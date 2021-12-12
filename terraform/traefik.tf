# https://github.com/traefik/traefik-helm-chart
# https://github.com/traefik/traefik-helm-chart/issues/208#issuecomment-670872105
# https://github.com/traefik/traefik-helm-chart/issues/42#issuecomment-563474382
# https://github.com/traefik/traefik/issues/7126

resource "helm_release" "helm_traefik" {
  name       = "traefik"
  namespace  = "traefik"
  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"
  # FIXME: for now
  atomic = true
  #cleanup_on_fail   = true
  recreate_pods     = true
  create_namespace  = true
  dependency_update = true
  max_history       = 5
  timeout           = 300

  values = [jsonencode({
    global = {
      checkNewVersion    = false
      sendAnonymousUsage = false
    }

    api = {
      insecure = true
    }

    metrics = {
      prometheus = false
    }

    # FIXME: tag
    image = {
      tag = "2.5.5"
    }

    service = {
      type = "LoadBalancer"
      spec = {
        loadBalancerIP = azurerm_public_ip.simplifier.ip_address
      }
    }

    persistence = {
      enabled      = true
      storageClass = "simplifier-certs"
      accessMode   = "ReadWriteMany"
      subPath      = "traefik"
      size         = "1Gi"
    }

    # additionalArguments = [
    #   "--api.insecure=true",
    #   "--metrics.prometheus=false",
    #   "--global.checknewversion=false",
    #   "--global.sendanonymoususage=false",
    # ]

    logs = {
      general = {
        level = "INFO"
      }
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
      kubernetesIngress = {
        enabled = true
        #allowExternalNameServices = true
        namespaces = []
      }
      kubernetesCRD = {
        enabled                   = true
        ingressClass              = "traefik"
        allowCrossNamespace       = true
        allowExternalNameServices = true
        namespaces                = []
      }
    }

    securityContext = {
      capabilities = {
        drop = ["ALL"]
        add  = ["NET_BIND_SERVICE"]
      }
      readOnlyRootFilesystem = true
      runAsGroup             = 0
      runAsNonRoot           = false
      runAsUser              = 0
    }

    resources = {
      requests = {
        cpu    = "250m"
        memory = "256Mi"
      }
      # limits = {
      #   cpu    = "500m"
      #   memory = "512Mi"
      # }
    }
  })]
  depends_on = [local_file.aks_kubeconfig, kubernetes_storage_class.simplifier_certs]
}

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

      from {
        namespace_selector {
          match_labels = {
            name = local.settings.dns_prefix
          }
        }
      }

      from {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }

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
        #accessControlAllowOrigin      = "origin-list-or-null"
        accessControlAllowCredentials = true
        accessControlAllowHeaders     = ["simplifiertoken", "simplifierapp", "User-Agent", "Content-Type", "Range"]
        accessControlAllowMethods     = ["GET", "POST", "OPTIONS", "PATCH", "PUT"]
        accessControlAllowOriginList  = ["ionic://localhost", "https://${azurerm_public_ip.simplifier.fqdn}"]
        accessControlExposeHeaders    = ["remainingTokenLifetime", "Content-Length", "Content-Range"]
        accessControlMaxAge           = 100
        addVaryHeader                 = true
        frameDeny                     = true
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
      name      = "simplifier-route"
      namespace = kubernetes_namespace.simplifier_namespace.metadata.0.name
    }
    "spec" = {
      "entryPoints" = [
        "web"
      ]
      "routes" = [
        {
          "match" = "Host(`${azurerm_public_ip.simplifier.fqdn}`)"
          "kind"  = "Rule"
          "middlewares" = [
            {
              "name"      = "simplifier-middleware"
              "namespace" = kubernetes_namespace.simplifier_namespace.metadata.0.name
            }
          ]
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
  depends_on = [helm_release.helm_traefik, kubernetes_manifest.simplifier_middleware]
}

resource "kubernetes_manifest" "simplifier_route_tls" {
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "IngressRoute"
    "metadata" = {
      name      = "simplifier-route-tls"
      namespace = kubernetes_namespace.simplifier_namespace.metadata.0.name
    }
    "spec" = {
      # TODO: required? think not
      "tls" = {
        "secretName" = "simplifier-certificate"
        #"certResolver" = "letsencrypt"
      }
      "entryPoints" = [
        "websecure"
      ]
      "routes" = [
        {
          "match" = "Host(`${azurerm_public_ip.simplifier.fqdn}`)"
          "kind"  = "Rule"
          # TODO: required? think not
          "middlewares" = [
            {
              "name"      = "simplifier-middleware"
              "namespace" = kubernetes_namespace.simplifier_namespace.metadata.0.name
            }
          ]
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
  depends_on = [helm_release.helm_traefik, kubernetes_manifest.simplifier_middleware]
}
