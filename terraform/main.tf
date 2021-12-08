data "azuread_client_config" "current" {}

resource "azurerm_resource_group" "resource_group" {
  name     = "${local.settings.name}-rg"
  location = local.settings.location
  tags     = local.tags
}

# FIXME: provider broken :()
# resource "azuread_group" "admin_group" {
#   display_name = "${local.settings.name}-group"

#   description      = "aks administrators for ${local.settings.name}"
#   owners           = [data.azuread_client_config.current.object_id]
#   security_enabled = true
#   lifecycle {
#     ignore_changes = [
#       # Ignore changes to tags, e.g. because a management agent
#       # updates these based on some ruleset managed elsewhere.
#       owners,
#     ]
#   }
# }
