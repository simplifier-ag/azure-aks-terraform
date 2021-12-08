resource "kubernetes_namespace" "simplifier_namespace" {
  metadata {
    name = "${local.settings.customer}-${local.settings.environment}"
    annotations = {
      name = local.settings.name
    }
    labels = local.tags
  }
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

resource "kubernetes_secret" "simplifier_secret" {
  metadata {
    name      = "${local.settings.customer}-${local.settings.environment}-secret"
    namespace = kubernetes_namespace.simplifier_namespace.metadata.0.name
    labels    = local.tags
  }
  data = {
    db_host      = azurerm_private_endpoint.simplifier_mariadb.private_service_connection.0.private_ip_address
    db_name      = azurerm_mariadb_database.simplifier_database.name
    db_pass      = azurerm_mariadb_server.simplifier_mariadb.administrator_login_password
    db_user      = "${azurerm_mariadb_server.simplifier_mariadb.administrator_login}@${azurerm_mariadb_server.simplifier_mariadb.fqdn}"
    virtual_host = azurerm_public_ip.simplifier.fqdn
  }
}

# https://community.simplifier.io/doc/installation-instructions/installation/docker-image-configuration/
resource "kubernetes_stateful_set" "simplifier_stateful_set" {
  metadata {
    name      = "${local.settings.customer}-${local.settings.environment}-set"
    namespace = kubernetes_namespace.simplifier_namespace.metadata.0.name
    labels    = local.tags
  }

  timeouts {
    create = "30m"
    update = "30m"
  }

  spec {
    pod_management_policy  = "Parallel"
    replicas               = 1
    revision_history_limit = 5
    service_name           = kubernetes_service.simplifier_service.metadata.0.name

    selector {
      match_labels = {
        k8s-app = local.tags.k8s-app
      }
    }

    update_strategy {
      type = "RollingUpdate"
      rolling_update {
        partition = 1
      }
    }

    volume_claim_template {
      metadata {
        name   = "simplifier-data"
        labels = local.tags
      }
      spec {
        storage_class_name = "managed-csi-premium"
        access_modes       = ["ReadWriteOnce"]
        # storage_class_name = "simplifier-many"
        # access_modes       = ["ReadWriteMany"]
        resources {
          requests = {
            storage = "100Gi"
          }
        }
      }
    }

    template {
      metadata {
        labels      = local.tags
        annotations = {}
      }
      spec {
        #termination_grace_period_seconds = 300
        container {
          name                       = "simplifier-app"
          image                      = local.settings.image
          image_pull_policy          = "IfNotPresent"
          termination_message_path   = "/opt/simplifier/data/termination_message.log"
          termination_message_policy = "FallbackToLogsOnError"

          resources {
            # limits = {
            #   cpu    = "4"
            #   memory = "16Gi"
            # }
            requests = {
              cpu    = "500m"
              memory = "4Gi"
            }
          }

          env {
            name  = "PLUGINLIST"
            value = "keyValueStorePlugin,pdfPlugin,captcha,contentRepoPlugin,jsonStore"
          }
          env {
            name  = "JVM_PARAMETER"
            value = "-XX:+UseContainerSupport -XX:MaxRAMPercentage=90.0 -XX:MaxMetaspaceSize=512m -XX:+UseG1GC -XX:+UseStringDeduplication -XX:-UseGCOverheadLimit"
          }
          env {
            name  = "DB"
            value = "mysql"
          }
          env {
            name  = "MYSQL_PORT"
            value = "3306"
          }
          env {
            name = "CLUSTER_MEMBER_NAME"
            value_from {
              field_ref {
                field_path = "metadata.uid"
              }
            }
          }
          env {
            name = "VIRTUAL_HOST"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.simplifier_secret.metadata.0.name
                key  = "virtual_host"
              }
            }
          }
          env {
            name = "MYSQL_HOST"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.simplifier_secret.metadata.0.name
                key  = "db_host"
              }
            }
          }
          env {
            name = "MYSQL_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.simplifier_secret.metadata.0.name
                key  = "db_name"
              }
            }
          }
          env {
            name = "MYSQL_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.simplifier_secret.metadata.0.name
                key  = "db_user"
              }
            }
          }
          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.simplifier_secret.metadata.0.name
                key  = "db_pass"
              }
            }
          }

          volume_mount {
            name       = "simplifier-data"
            mount_path = "/opt/simplifier/data"
          }

          startup_probe {
            http_get {
              path   = "/client/2.0/version"
              port   = 8080
              scheme = "HTTP"
            }
            failure_threshold = 60
            period_seconds    = 10
            timeout_seconds   = 10
          }
          liveness_probe {
            http_get {
              path   = "/client/2.0/version"
              port   = 8080
              scheme = "HTTP"
            }
            failure_threshold = 2
            period_seconds    = 5
            timeout_seconds   = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "simplifier_service" {
  metadata {
    name      = "${local.settings.customer}-${local.settings.environment}-service"
    namespace = kubernetes_namespace.simplifier_namespace.metadata.0.name
    labels    = local.tags
  }
  spec {
    type             = "LoadBalancer"
    load_balancer_ip = azurerm_public_ip.simplifier.ip_address
    #type = "NodePort"

    selector = {
      k8s-app = local.tags.k8s-app
    }
    port {
      port = 80
      target_port = 8080
    }
  }
}

resource "kubernetes_ingress" "simplifier_traefik_ingress" {
  metadata {
    name      = "${local.settings.customer}-${local.settings.environment}-traefik-ingress"
    namespace = kubernetes_namespace.simplifier_namespace.metadata.0.name
    labels    = local.tags
    annotations = {
      "kubernetes.io/ingress.class"                      = "traefik"
      "traefik.ingress.kubernetes.io/redirect-permanent" = "false"
    }
  }
  spec {
    backend {
      service_name = kubernetes_service.simplifier_service.metadata.0.name
      service_port = 80
    }
    rule {
      host = azurerm_public_ip.simplifier.fqdn
      http {
        path {
          path = "/*"
          backend {
            service_name = kubernetes_service.simplifier_service.metadata.0.name
            service_port = 80
          }
        }
      }
    }
  }
  depends_on = [
    helm_release.helm_traefik
  ]
}

# resource "kubernetes_pod_disruption_budget" "simplifier_pdb" {
#   metadata {
#     name      = "${local.settings.customer}-${local.settings.environment}-pdb"
#     namespace = kubernetes_namespace.simplifier_namespace.metadata.0.name
#     labels    = local.tags
#   }
#   spec {
#     max_unavailable = "50%"
#     selector {
#       match_labels = {
#         k8s-app = local.tags.k8s-app
#       }
#     }
#   }
# }
