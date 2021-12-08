# https://github.com/traefik/traefik-helm-chart
resource "helm_release" "helm_traefik" {
  name              = "traefik"
  namespace         = "traefik"
  repository        = "https://helm.traefik.io/traefik"
  chart             = "traefik"
  cleanup_on_fail   = true
  create_namespace  = true
  dependency_update = true
  max_history       = 5
  timeout           = 180
  values = [jsonencode({
    service = {
      type = "ClusterIP"
    }
    metrics = {}
    additionalArguments = [
      "--log.level=INFO",
      "--providers.kubernetesingress.ingressclass=traefik",
      "--metrics.prometheus=false",
      "--api.dashboard=false",
    ]
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

# # TODO FIXME: bug in terraform provider, PR pending
# resource "kubectl_manifest" "traefik_dashboard" {
#   yaml_body = <<YAML
# # dashboard.yaml
# apiVersion: traefik.containo.us/v1alpha1
# kind: IngressRoute
# metadata:
#   name: traefik-dashboard
#   namespace: traefik
# spec:
#   entryPoints:
#     - web
#   routes:
#     - match: Host(`traefik.localhost`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))
#       kind: Rule
#       services:
#         - name: api@internal
#           kind: TraefikService
# YAML
#   depends_on = [
#     helm_release.helm_traefik,
#   ]
# }
