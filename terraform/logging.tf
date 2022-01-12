resource "azurerm_log_analytics_workspace" "aks_logworkspace" {
  name                = "${local.settings.name}-log"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.tags

  sku                        = "PerGB2018"
  retention_in_days          = 30
  internet_ingestion_enabled = false
}

resource "azurerm_log_analytics_solution" "aks_logworkspace_solution" {
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.tags

  solution_name         = "Containers"
  workspace_resource_id = azurerm_log_analytics_workspace.aks_logworkspace.id
  workspace_name        = azurerm_log_analytics_workspace.aks_logworkspace.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Containers"
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scope
resource "azurerm_monitor_private_link_scope" "aks_logworkspace_scope" {
  name                = "${local.settings.name}-log-scope"
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.tags
}

resource "azurerm_monitor_private_link_scoped_service" "aks_logworkspace_scoped_service" {
  name                = "${local.settings.name}-log-scoped-service"
  resource_group_name = azurerm_resource_group.resource_group.name

  scope_name         = azurerm_monitor_private_link_scope.aks_logworkspace_scope.name
  linked_resource_id = azurerm_log_analytics_workspace.aks_logworkspace.id
}
