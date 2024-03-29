resource "random_string" "mariadb_password" {
  length  = 32
  special = false
  upper   = true
}

# TODO: use module https://github.com/kumarvna/terraform-azurerm-mariadb-server ?
resource "azurerm_mariadb_server" "simplifier_mariadb" {
  name                = "mariadb-${local.settings.customer}-${local.settings.environment}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  administrator_login           = "simplifieradmin"
  administrator_login_password  = random_string.mariadb_password.result
  auto_grow_enabled             = true
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = false
  sku_name                      = "GP_Gen5_4"
  ssl_enforcement_enabled       = false
  storage_mb                    = 5120
  version                       = "10.3"

  tags = local.tags
}

# warning: this will delete the database if the server exists
resource "null_resource" "simplifier_database_delete" {
  provisioner "local-exec" {
    command = <<-EOT
      az mariadb db delete --yes --resource-group ${azurerm_resource_group.resource_group.name} --server-name ${azurerm_mariadb_server.simplifier_mariadb.name} --name ${azurerm_mariadb_database.simplifier_database.name}
    EOT
  }
  depends_on = [azurerm_mariadb_server.simplifier_mariadb]
}

resource "azurerm_mariadb_database" "simplifier_database" {
  name                = "${local.settings.customer}${local.settings.environment}"
  resource_group_name = azurerm_resource_group.resource_group.name
  server_name         = azurerm_mariadb_server.simplifier_mariadb.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}

# https://community.simplifier.io/doc/installation-instructions/general-instructions/additional-requirements-mysql-databases-backend/
resource "azurerm_mariadb_configuration" "wait_timeout" {
  name                = "wait_timeout"
  resource_group_name = azurerm_resource_group.resource_group.name
  server_name         = azurerm_mariadb_server.simplifier_mariadb.name
  value               = "28800"
}

resource "azurerm_mariadb_configuration" "max_allowed_packet" {
  name                = "max_allowed_packet"
  resource_group_name = azurerm_resource_group.resource_group.name
  server_name         = azurerm_mariadb_server.simplifier_mariadb.name
  value               = "1073741824"
}

# required to allow the pods to access the mariadb server (link subnets)
resource "azurerm_private_endpoint" "simplifier_mariadb" {
  name                = "${local.settings.customer}-${local.settings.environment}-pe"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  subnet_id           = azurerm_subnet.simplifier.id

  private_service_connection {
    name                           = "${local.settings.customer}-${local.settings.environment}-psc"
    private_connection_resource_id = azurerm_mariadb_server.simplifier_mariadb.id
    subresource_names              = ["mariadbServer"]
    # confirm resource creation automatically
    is_manual_connection = false
  }
}
