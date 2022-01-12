output "git_repo_rev" {
  value = local.repo_rev
}

output "resource_group_name" {
  value = azurerm_resource_group.resource_group.name
}

output "aks_cluster_node_resource_group" {
  value = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
}

output "aks_cluster_effective_outbound_ips" {
  value = azurerm_kubernetes_cluster.aks_cluster.network_profile.0.load_balancer_profile.0.effective_outbound_ips
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks_cluster.name
}

output "aks_cluster_fqdn" {
  value = azurerm_kubernetes_cluster.aks_cluster.fqdn
}

output "aks_kube_config" {
  sensitive = true
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config
}

output "aks_cluster_kubernetes_latest_version" {
  value = data.azurerm_kubernetes_service_versions.current.latest_version
}

output "aks_cluster_kubernetes_version" {
  value = azurerm_kubernetes_cluster.aks_cluster.kubernetes_version
}

output "simplifier_ip_address" {
  value = azurerm_public_ip.simplifier.ip_address
}

output "simplifier_fqdn" {
  value = local.settings.fqdn
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
