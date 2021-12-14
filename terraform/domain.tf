resource "azurerm_dns_zone" "simplifier_dns_zone" {
  name                = local.settings.dns_suffix
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.tags
}

resource "azurerm_dns_a_record" "simplifier_dns_a_record" {
  name                = local.settings.dns_prefix
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.tags

  records   = ["${azurerm_public_ip.simplifier.ip_address}"]
  ttl       = 300
  zone_name = azurerm_dns_zone.simplifier_dns_zone.name
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip#domain_name_label
resource "azurerm_public_ip" "simplifier" {
  name     = "${local.settings.name}-ip"
  location = azurerm_resource_group.resource_group.location
  tags     = local.tags

  # https://docs.microsoft.com/en-us/azure/aks/faq#why-are-two-resource-groups-created-with-aks
  resource_group_name = "MC_${azurerm_resource_group.resource_group.name}_${local.settings.name}_${local.settings.location}"

  allocation_method = "Static"
  domain_name_label = local.settings.dns_prefix
  sku               = "Standard"

  # important: the resource group exists only after the creation of the cluster - it's done azure side, so we depend on the cluster here
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}
