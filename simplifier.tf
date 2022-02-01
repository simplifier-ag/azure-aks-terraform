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

resource "kubernetes_limit_range" "aks_limit_range" {
  metadata {
    name = "${local.settings.name}-limit-range"
    # limit range in context of namespace
    namespace = kubernetes_namespace.simplifier_namespace.metadata.0.name
    labels    = local.tags
  }

  spec {
    limit {
      type = "Pod"
      max = {
        cpu    = "4"
        memory = "14Gi"
      }
    }
    limit {
      type = "Container"
      default_request = {
        cpu    = "100m"
        memory = "100Mi"
      }
    }
    limit {
      type = "PersistentVolumeClaim"
      max = {
        storage = "120G"
      }
    }
  }
}

resource "kubernetes_secret" "simplifier_secret" {
  metadata {
    name      = "simplifier-secret"
    namespace = kubernetes_namespace.simplifier_namespace.metadata.0.name
    labels    = local.tags
  }
  data = {
    db_host      = azurerm_private_endpoint.simplifier_mariadb.private_service_connection.0.private_ip_address
    db_name      = azurerm_mariadb_database.simplifier_database.name
    db_pass      = azurerm_mariadb_server.simplifier_mariadb.administrator_login_password
    db_user      = "${azurerm_mariadb_server.simplifier_mariadb.administrator_login}@${azurerm_mariadb_server.simplifier_mariadb.fqdn}"
    virtual_host = local.settings.fqdn
  }
}

# https://community.simplifier.io/doc/installation-instructions/installation/docker-image-configuration/
resource "kubernetes_stateful_set" "simplifier_stateful_set" {
  metadata {
    name      = "simplifier-set"
    namespace = kubernetes_namespace.simplifier_namespace.metadata.0.name
    # add aditional labels to the set
    labels = merge(local.tags, local.additional_set_tags)
  }

  timeouts {
    create = "10m"
    update = "7m"
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
        storage_class_name = "managed"
        access_modes       = ["ReadWriteOnce"]

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
        termination_grace_period_seconds = 300
        container {
          name                       = "simplifier-app"
          image                      = local.settings.image
          image_pull_policy          = local.settings.image_pull_policy
          termination_message_path   = "/opt/simplifier/data/termination_message.log"
          termination_message_policy = "FallbackToLogsOnError"

          resources {
            requests = {
              cpu    = "500m"
              memory = "4Gi"
            }
            limits = {
              cpu    = "4"
              memory = "14Gi"
            }
          }

          port {
            container_port = 8080
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
          # FIXME: Cannot enable Cluster Mode: configuration value [26235c64-9222-45a3-a0c4-7085beb28c9d] for [current_cluster_member_name] is invalid
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
    name      = "simplifier-service"
    namespace = kubernetes_namespace.simplifier_namespace.metadata.0.name
    labels    = local.tags
    # important: https://docs.microsoft.com/en-us/azure/aks/internal-lb
    annotations = {
      "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
    }
  }
  spec {
    type = "ClusterIP"

    port {
      port        = 8080
      target_port = 8080
    }

    selector = {
      k8s-app = local.tags.k8s-app
    }
  }
}

resource "kubernetes_ingress_v1" "simplifier_traefik_ingress" {
  metadata {
    name      = "simplifier-ingress"
    namespace = kubernetes_namespace.simplifier_namespace.metadata.0.name
    labels    = local.tags

    # look ma, it's 2022 :)
    annotations = {
      "kubernetes.io/ingress.class"                         = "traefik"
      "cert-manager.io/acme-challenge-type"                 = "http01"
      "cert-manager.io/cluster-issuer"                      = "simplifier-cluster-issuer"
      "cert-manager.io/dns-names"                           = "${local.settings.fqdn},${azurerm_public_ip.simplifier.fqdn}"
      "traefik.ingress.kubernetes.io/frontend-entry-points" = "web,websecure"
      # FIXME: redirection not working
      "traefik.ingress.kubernetes.io/redirect-entry-point" = "web"
      "traefik.ingress.kubernetes.io/redirect-permanent"   = true
      "traefik.ingress.kubernetes.io/router.entrypoints"   = "web,websecure"
      "traefik.ingress.kubernetes.io/router.middlewares"   = "testing-dev-simplifier-middleware@kubernetescrd"
      "traefik.ingress.kubernetes.io/router.tls"           = true
    }
  }

  spec {
    default_backend {
      service {
        name = kubernetes_service.simplifier_service.metadata.0.name
        port {
          number = kubernetes_service.simplifier_service.spec.0.port.0.port
        }
      }
    }

    rule {
      #host = local.settings.fqdn # not setting 'host' matches all
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.simplifier_service.metadata.0.name
              port {
                number = kubernetes_service.simplifier_service.spec.0.port.0.port
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = ["${local.settings.fqdn}", "${azurerm_public_ip.simplifier.fqdn}"]
      secret_name = "simplifier-certificate"
    }
  }
}
