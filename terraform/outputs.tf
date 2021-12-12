output "git_repo_rev" {
  value = local.repo_rev
}

output "resource_group_name" {
  value = azurerm_resource_group.resource_group.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks_cluster.name
}

output "aks_cluster_fqdn" {
  value = azurerm_kubernetes_cluster.aks_cluster.fqdn
}

output "aks_api_host" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
}

output "aks_kube_config" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config
  sensitive = true
}

output "aks_versions" {
  value = data.azurerm_kubernetes_service_versions.current.versions
}

output "aks_latest_version" {
  value = data.azurerm_kubernetes_service_versions.current.latest_version
}

output "aks_cluster_kubernetes_version" {
  value = azurerm_kubernetes_cluster.aks_cluster.kubernetes_version
}

output "simplifier_ip_address" {
  value = azurerm_public_ip.simplifier.ip_address
}

output "simplifier_fqdn" {
  value = azurerm_dns_a_record.simplifier_dns_a_record.fqdn
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
