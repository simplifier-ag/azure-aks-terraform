data "azuread_client_config" "current" {}

resource "azurerm_resource_group" "resource_group" {
  name     = "${local.settings.name}-rg"
  location = local.settings.location
  tags     = local.tags
}
