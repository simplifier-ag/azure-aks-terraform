data "azurerm_kubernetes_service_versions" "current" {
  location        = azurerm_resource_group.resource_group.location
  include_preview = false
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = local.settings.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.tags

  dns_prefix = local.settings.dns_prefix

  kubernetes_version        = data.azurerm_kubernetes_service_versions.current.latest_version
  automatic_channel_upgrade = "stable"
  sku_tier                  = local.settings.aks_sku_tier

  maintenance_window {
    allowed {
      day   = local.settings.maintenance_window_day
      hours = local.settings.maintenance_window_hours
    }
  }

  default_node_pool {
    name = "default"
    # allow auto-upgrade
    orchestrator_version = data.azurerm_kubernetes_service_versions.current.latest_version

    os_disk_type    = "Ephemeral"
    os_disk_size_gb = local.settings.os_disk_size_gb

    vm_size        = local.settings.linux_nodes_sku
    vnet_subnet_id = azurerm_subnet.simplifier.id

    tags        = local.tags
    node_labels = local.tags

    # TODO: test and enable?
    #availability_zones  = ["1", "2"]
    #type                = "VirtualMachineScaleSets"
    availability_zones = ["1"]

    node_count          = 1
    min_count           = 1
    max_count           = 4
    enable_auto_scaling = true

    linux_os_config {
      sysctl_config {
        fs_file_max           = 12000500
        fs_nr_open            = 20000500
        net_ipv4_tcp_tw_reuse = true
        vm_swappiness         = 0
      }
    }
  }

  identity {
    type                      = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.aks_identity.id
  }

  network_profile {
    # https://docs.microsoft.com/en-us/azure/aks/concepts-network#azure-virtual-networks
    network_plugin = "azure"
    network_policy = "azure"

    load_balancer_sku = "Standard"
    # https://docs.microsoft.com/en-us/azure/aks/faq#transparent-mode
    network_mode  = "transparent"
    outbound_type = "loadBalancer"

    load_balancer_profile {
      # https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard#configure-the-allocated-outbound-ports
      managed_outbound_ip_count = 1
      outbound_ports_allocated  = 32
      idle_timeout_in_minutes   = 5
    }
  }

  role_based_access_control {
    enabled = false
  }

  addon_profile {
    aci_connector_linux {
      enabled = false
    }
    http_application_routing {
      enabled = false
    }
    ingress_application_gateway {
      enabled = false
    }
    kube_dashboard {
      enabled = false
    }
    # https://docs.microsoft.com/en-ie/azure/governance/policy/concepts/policy-for-kubernetes
    azure_policy {
      enabled = true
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logworkspace.id
    }
  }

  depends_on = [
    azurerm_user_assigned_identity.aks_identity
  ]
}

resource "local_file" "aks_kubeconfig" {
  filename        = ".kubeconfig"
  content         = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  file_permission = "0600"
  depends_on      = [azurerm_kubernetes_cluster.aks_cluster]
}

# this is required for pods to allow public dns to resolve the certificates we request from letsencrypt
# FIXME: subdomain hardcoded
resource "kubernetes_manifest" "configmap_kube_system_kube_dns" {
  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "stubDomains"         = <<-EOT
      {"${local.settings.dns_suffix}": ["${azurerm_public_ip.simplifier.ip_address}"]}

      EOT
      "upstreamNameservers" = <<-EOT
      ["8.8.8.8", "8.8.4.4"]

      EOT
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "name"      = "kube-dns"
      "namespace" = "kube-system"
    }
  }
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}
