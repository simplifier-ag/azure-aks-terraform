resource "azurerm_dns_zone" "simplifier_dns_zone" {
  # TODO: abstraction
  name                = "aks.simplifier.io"
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_dns_a_record" "simplifier_dns_a_record" {
  name                = local.settings.dns_prefix
  zone_name           = azurerm_dns_zone.simplifier_dns_zone.name
  resource_group_name = azurerm_resource_group.resource_group.name
  ttl                 = 300
  records             = ["${azurerm_public_ip.simplifier.ip_address}"]
}

# resource "azurerm_dns_cname_record" "simplifier_dns_cname_record" {
#   name                = local.settings.dns_prefix
#   record              = azurerm_public_ip.simplifier.fqdn
#   resource_group_name = azurerm_resource_group.resource_group.name
#   ttl                 = 300
#   zone_name           = azurerm_dns_zone.simplifier_dns_zone.name
# }
