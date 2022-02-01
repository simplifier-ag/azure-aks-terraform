# https://artifacthub.io/packages/helm/cert-manager/cert-manager
resource "helm_release" "helm_cert_manager" {
  name              = "cert-manager"
  namespace         = "cert-manager"
  repository        = "https://charts.jetstack.io"
  chart             = "cert-manager"
  atomic            = true
  create_namespace  = true
  dependency_update = true
  max_history       = 5
  timeout           = 300
  wait_for_jobs     = true

  # https://github.com/jetstack/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml
  values = [jsonencode({
    # global = {
    #   podSecurityPolicy = {
    #     enabled     = true
    #     useAppArmor = true
    #   }
    # }

    prometheus = {
      enabled = false
    }

    installCRDs = true

    resources = {
      requests = {
        cpu    = "250m"
        memory = "256Mi"
      }
    }
  })]
  depends_on = [local_file.aks_kubeconfig]
}

resource "kubernetes_manifest" "simplifier_cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "simplifier-cluster-issuer"
    }

    spec = {
      acme = {
        email  = local.settings.letsencrypt_email
        server = local.settings.letsencrypt_server
        privateKeySecretRef = {
          name = "simplifier-cluster-issuer"
        }

        # differes from the documentation ('ingress' vs 'ingressTemplate' - this way the class gets referenced right
        solvers = [
          {
            http01 = {
              ingress = {
                ingressTemplate = {
                  metadata = {
                    annotations = {
                      "kubernetes.io/ingress.class"        = "traefik"
                      "ingress.kubernetes.io/ssl-redirect" = "false"
                    }
                  }
                }
              }
            }
          }, # http01
        ]
      }
    }
  }

  wait_for = {
    fields = {
      "status.conditions[0].type"   = "Ready"
      "status.conditions[0].status" = "True"
    }
  }

  field_manager {
    force_conflicts = true
  }
  depends_on = [helm_release.helm_cert_manager]
}
