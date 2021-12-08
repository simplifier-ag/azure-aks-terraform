resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "aks-identity"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  tags                = local.tags
}

# resource "azurerm_user_assigned_identity" "aks_kubelet_identity" {
#   name                = "aks-kubelet-identity"
#   resource_group_name = azurerm_resource_group.resource_group.name
#   location            = azurerm_resource_group.resource_group.location
#   tags                = local.tags
# }
