data "azurerm_kubernetes_service_versions" "current" {
  location        = azurerm_resource_group.resource_group.location
  include_preview = false
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = local.settings.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  dns_prefix          = local.settings.dns_prefix
  tags                = local.tags

  kubernetes_version        = data.azurerm_kubernetes_service_versions.current.latest_version
  automatic_channel_upgrade = "stable"

  # TODO: abstraction
  maintenance_window {
    allowed {
      day   = "Tuesday"
      hours = [2, 3, 4]
    }
  }

  default_node_pool {
    name                 = "default"
    orchestrator_version = data.azurerm_kubernetes_service_versions.current.latest_version

    enable_host_encryption = true
    ultra_ssd_enabled      = true
    os_disk_size_gb        = local.settings.os_disk_size_gb
    vm_size                = local.settings.linux_nodes_sku
    vnet_subnet_id         = azurerm_subnet.simplifier.id

    tags        = local.tags
    node_labels = local.tags

    availability_zones  = [1]
    node_count          = 1
    min_count           = 1
    max_count           = 3
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
    #type = "SystemAssigned"
    type                      = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.aks_identity.id
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "Standard"
  }

  role_based_access_control {
    enabled = false
    # enabled = true
    # azure_active_directory {
    #   managed                = true
    #   # FIXME: https://portal.azure.com/#blade/Microsoft_AAD_IAM/GroupDetailsMenuBlade/Properties/groupId/65cf14c3-0c57-4813-9ac5-10b1ff98612b
    #   #admin_group_object_ids = [azuread_group.admin_group.id]
    #   admin_group_object_ids = ["65cf14c3-0c57-4813-9ac5-10b1ff98612b"]
    # }
  }

  addon_profile {
    aci_connector_linux {
      enabled = false
    }
    # TODO: https://docs.microsoft.com/en-ie/azure/governance/policy/concepts/policy-for-kubernetes
    azure_policy {
      enabled = true
    }
    http_application_routing {
      # FIXME: disable
      enabled = false
    }
    ingress_application_gateway {
      enabled = false
    }
    kube_dashboard {
      enabled = false
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logworkspace.id
    }
  }
}

resource "local_file" "aks_kubeconfig" {
  filename        = ".kubeconfig"
  content         = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  file_permission = "0600"
  depends_on      = [azurerm_kubernetes_cluster.aks_cluster]
}

# TODO: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/pod_disruption_budget
