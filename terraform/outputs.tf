output "resource_group_name" {
  value = azurerm_resource_group.resource_group.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks_cluster.name
}

output "aks_cluster_fqdn" {
  value = azurerm_kubernetes_cluster.aks_cluster.fqdn
}

output "aks_host" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
}

output "aks_kube_config" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config
  sensitive = true
}

output "azurerm_public_ip_address" {
  value = azurerm_public_ip.simplifier.ip_address
}

output "azurerm_public_fqdn" {
  value       = azurerm_public_ip.simplifier.fqdn
  description = "the dns name of the publicly accessible host"
}

output "mariadb_fqdn" {
  value = azurerm_mariadb_server.simplifier_mariadb.fqdn
}

output "mariadb_private_ip_address" {
  value = azurerm_private_endpoint.simplifier_mariadb.private_service_connection.0.private_ip_address
}

output "mariadb_administrator_login" {
  sensitive = true
  value     = azurerm_mariadb_server.simplifier_mariadb.administrator_login
}

output "mariadb_administrator_login_password" {
  sensitive = true
  value     = azurerm_mariadb_server.simplifier_mariadb.administrator_login_password
}
