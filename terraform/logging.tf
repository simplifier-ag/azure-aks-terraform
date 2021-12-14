resource "azurerm_log_analytics_workspace" "aks_logworkspace" {
  name                = "${local.settings.name}-log"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  sku                        = "PerGB2018"
  retention_in_days          = 30
  internet_ingestion_enabled = false
  tags                       = local.tags
}
