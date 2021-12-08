# https://artifacthub.io/packages/helm/cert-manager/cert-manager
resource "helm_release" "helm_cert_manager" {
  name              = "cert-manager"
  namespace         = "cert-manager"
  repository        = "https://charts.jetstack.io"
  chart             = "cert-manager"
  cleanup_on_fail   = true
  create_namespace  = true
  dependency_update = true
  max_history       = 5
  timeout           = 360
  wait_for_jobs     = true
  # https://github.com/jetstack/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml
  values = [jsonencode({
    global = {
      podSecurityPolicy = {
        enabled     = "true"
        useAppArmor = "true"
      }
    }
    prometheus = {
      enabled = "false"
    }
    installCRDs = "true"
    resources = {
      requests = {
        cpu    = "250m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
  })]
}