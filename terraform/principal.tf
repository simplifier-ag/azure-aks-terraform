# data "azuread_client_config" "current" {}

# resource "azuread_application" "simplifier" {
#   display_name     = "simplifier.io"
#   identifier_uris  = ["http://simplifier.io"]
#   owners           = data.azuread_client_config.current.object_id
#   sign_in_audience = "AzureADMyOrg"
# }

# resource "azuread_service_principal" "simplifier" {
#   application_id = azuread_application.simplifier.application_id
#   owners         = [data.azuread_client_config.current.object_id]
#   #alternative_names = []
#   description = local.settings.name
# }

# # https://registry.terraform.io/modules/kumarvna/service-principal/azuread/latest
# module "service-principal" {
#   source  = "kumarvna/service-principal/azuread"
#   version = "2.2.0"

#   service_principal_name = 

#   certificate_path                     = "./pki/principal.pem"
#   enable_service_principal_certificate = true
#   password_rotation_in_years           = 2

#   # adding roles and scope to service principal
#   assignments = [
#     {
#       scope                = "/subscriptions/${local.settings.subscription_id}"
#       role_definition_name = "Contributor"
#     },
#   ]
# }
