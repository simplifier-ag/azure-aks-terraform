resource "azurerm_virtual_network" "simplifier" {
  name                = "${local.settings.name}-vnet"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  # TODO: reference
  address_space = ["10.13.0.0/16"]

  tags = local.tags
}

resource "azurerm_subnet" "simplifier" {
  name                = "${local.settings.name}-sub"
  resource_group_name = azurerm_resource_group.resource_group.name

  # TODO: reference
  address_prefixes = ["10.13.1.0/24"]

  # enable to deploy private link resources into a subnet; see azurerm_private_endpoint.simplifier_mariadb
  enforce_private_link_endpoint_network_policies = true
  service_endpoints                              = ["Microsoft.Sql", "Microsoft.Web"]
  virtual_network_name                           = azurerm_virtual_network.simplifier.name
}
