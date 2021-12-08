resource "azurerm_virtual_network" "simplifier" {
  name = "${local.settings.name}-vnet"
  # TODO: reference
  address_space       = ["10.13.0.0/16"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.tags
}

resource "azurerm_subnet" "simplifier" {
  name = "${local.settings.name}-sub"
  # TODO: reference
  address_prefixes                               = ["10.13.1.0/24"]
  enforce_private_link_endpoint_network_policies = true
  resource_group_name                            = azurerm_resource_group.resource_group.name
  service_endpoints                              = ["Microsoft.Sql", "Microsoft.Web"]
  virtual_network_name                           = azurerm_virtual_network.simplifier.name
}

resource "azurerm_public_ip" "simplifier" {
  name     = "${local.settings.name}-ip"
  location = azurerm_resource_group.resource_group.location
  # TODO: documentation
  resource_group_name = "MC_${azurerm_resource_group.resource_group.name}_${local.settings.name}_${local.settings.location}"
  sku                 = "Standard"
  allocation_method   = "Static"
  domain_name_label   = local.settings.dns_prefix
  tags                = local.tags

  depends_on = [
    azurerm_kubernetes_cluster.aks_cluster,
  ]
}