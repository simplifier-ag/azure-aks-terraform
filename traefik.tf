# https://github.com/traefik/traefik-helm-chart
# https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml
# https://github.com/traefik/traefik-helm-chart/issues/208#issuecomment-670872105
# https://github.com/traefik/traefik-helm-chart/issues/42#issuecomment-563474382
# https://github.com/traefik/traefik/issues/7126

resource "helm_release" "helm_traefik" {
  name              = "traefik"
  namespace         = "traefik"
  repository        = "https://helm.traefik.io/traefik"
  chart             = "traefik"
  atomic            = true
  create_namespace  = true
  dependency_update = true
  max_history       = 5
  recreate_pods     = true
  timeout           = 300

  values = [jsonencode({
    globalArguments = [
      "--global.checknewversion",
      "--global.sendanonymoususage"
    ]

    logs = {
      general = {
        level = "WARN"
      }
      access = {
        enabled = true
        # format = "json"
        bufferingSize = 100
      }
    }

    metrics = {
      prometheus = []
    }

    ports = {
      web = {
        port = 80
      }
      websecure = {
        port = 443
      }
    }

    providers = {
      kubernetesCRD = {
        enabled      = true
        ingressClass = "traefik"
        # yes, we cross namespaces
        allowCrossNamespace = true
        namespaces          = [] # all
      }
      kubernetesIngress = {
        enabled    = true
        namespaces = [] # all
      }
    }

    rbac = {
      enabled = false
    }

    resources = {
      requests = {
        cpu    = "250m"
        memory = "256Mi"
      }
    }

    # allow binding ports below 1024 - traefik is our external load balancer
    securityContext = {
      capabilities = {
        drop = ["ALL"]
        add  = ["NET_BIND_SERVICE"]
      }
      runAsNonRoot           = false
      readOnlyRootFilesystem = true
      runAsGroup             = 0
      runAsUser              = 0
    }

    service = {
      type = "LoadBalancer"
      spec = {
        loadBalancerIP = azurerm_public_ip.simplifier.ip_address
      }
    }
  })]
  depends_on = [local_file.aks_kubeconfig]
}

# https://kubernetes.io/docs/concepts/services-networking/network-policies/
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy
resource "kubernetes_network_policy" "simplifier_network_policy" {
  metadata {
    name      = "${helm_release.helm_traefik.metadata.0.namespace}-network-policy"
    namespace = helm_release.helm_traefik.metadata.0.namespace
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "k8s-app"
        operator = "In"
        values   = ["${local.tags.k8s-app}"]
      }
    }
    ingress {
      ports {
        port     = "http"
        protocol = "TCP"
      }
      ports {
        port     = "https"
        protocol = "TCP"
      }
    }

    # allow all
    egress {}

    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_manifest" "simplifier_middleware" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "simplifier-middleware"
      namespace = kubernetes_namespace.simplifier_namespace.metadata.0.name
    }

    spec = {
      headers = {
        accessControlAllowCredentials = true
        accessControlAllowHeaders     = ["simplifiertoken", "simplifierapp", "User-Agent", "Content-Type", "Range"]
        accessControlAllowMethods     = ["GET", "POST", "OPTIONS", "PATCH", "PUT"]
        accessControlAllowOriginList  = ["ionic://localhost", "https://${azurerm_public_ip.simplifier.fqdn}", "https://${local.settings.fqdn}"]
        accessControlExposeHeaders    = ["remainingTokenLifetime", "Content-Length", "Content-Range"]
        accessControlMaxAge           = 100
        addVaryHeader                 = true
        frameDeny                     = false
      }
    }
  }
  field_manager {
    force_conflicts = true
  }
  depends_on = [helm_release.helm_traefik]
}

resource "kubernetes_manifest" "simplifier_route" {
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "IngressRoute"
    "metadata" = {
      "name"      = "simplifier-route"
      "namespace" = kubernetes_namespace.simplifier_namespace.metadata.0.name
    }
    "spec" = {
      "entryPoints" = [
        "web"
      ]
      "routes" = [
        {
          "match" = "Host(`${azurerm_public_ip.simplifier.fqdn}`) || Host(`${local.settings.fqdn}`)"
          "kind"  = "Rule"
          "services" = [
            {
              "name"      = kubernetes_service.simplifier_service.metadata.0.name
              "namespace" = kubernetes_service.simplifier_service.metadata.0.namespace
              "port"      = 8080
              "kind"      = "Service"
            }
          ]

        }
      ]
    }
  }
  field_manager {
    force_conflicts = true
  }
  depends_on = [helm_release.helm_traefik]
}

resource "kubernetes_manifest" "simplifier_route_tls" {
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "IngressRoute"
    "metadata" = {
      "name"      = "simplifier-route-tls"
      "namespace" = kubernetes_namespace.simplifier_namespace.metadata.0.name
    }
    "spec" = {
      "tls" = {
        "secretName" = "simplifier-certificate"
      }
      "entryPoints" = [
        "websecure"
      ]
      "routes" = [
        {
          "match" = "Host(`${azurerm_public_ip.simplifier.fqdn}`) || Host(`${local.settings.fqdn}`)"
          "kind"  = "Rule"
          "services" = [
            {
              "name"      = kubernetes_service.simplifier_service.metadata.0.name
              "namespace" = kubernetes_service.simplifier_service.metadata.0.namespace
              "port"      = 8080
              "kind"      = "Service"
            }
          ]

        }
      ]
    }
  }
  field_manager {
    force_conflicts = true
  }
  depends_on = [helm_release.helm_traefik]
}
