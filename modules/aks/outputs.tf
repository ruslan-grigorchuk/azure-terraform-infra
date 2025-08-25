output "cluster_id" {
  description = "The ID of the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "The name of the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "The FQDN of the Azure Kubernetes Managed Cluster API server"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_private_fqdn" {
  description = "The FQDN for the Kubernetes Cluster when private cluster is enabled"
  value       = azurerm_kubernetes_cluster.main.private_fqdn
}

output "kube_config_raw" {
  description = "Raw Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate data for the cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate
  sensitive   = true
}

output "client_certificate" {
  description = "Base64 encoded client certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Base64 encoded client key"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.client_key
  sensitive   = true
}

output "host" {
  description = "Kubernetes API server host"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.host
  sensitive   = true
}

output "username" {
  description = "Kubernetes username"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.username
  sensitive   = true
}

output "password" {
  description = "Kubernetes password"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.password
  sensitive   = true
}

output "kubelet_identity" {
  description = "The kubelet identity information"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity
}

output "cluster_identity" {
  description = "The cluster identity information"
  value       = azurerm_kubernetes_cluster.main.identity
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "node_resource_group" {
  description = "Name of the resource group containing cluster nodes"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "effective_outbound_ips" {
  description = "The effective outbound IPs"
  value       = try(azurerm_kubernetes_cluster.main.network_profile[0].load_balancer_profile[0].effective_outbound_ips, [])
}

output "network_profile" {
  description = "Network profile configuration"
  value       = azurerm_kubernetes_cluster.main.network_profile
}

output "ingress_application_gateway" {
  description = "Application Gateway Ingress Controller information"
  value       = try(azurerm_kubernetes_cluster.main.ingress_application_gateway, null)
}

output "oms_agent_identity" {
  description = "OMS agent identity information"
  value       = try(azurerm_kubernetes_cluster.main.oms_agent[0].oms_agent_identity, null)
}

output "key_vault_secrets_provider_identity" {
  description = "Key Vault Secrets Provider identity information"
  value       = try(azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity, null)
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID used for monitoring"
  value       = local.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  value       = var.log_analytics_workspace_id == "" && var.oms_agent_enabled ? azurerm_log_analytics_workspace.aks[0].name : (var.log_analytics_workspace_id != "" ? data.azurerm_log_analytics_workspace.existing[0].name : null)
}

output "additional_node_pool_names" {
  description = "Names of additional node pools"
  value       = [for pool in azurerm_kubernetes_cluster_node_pool.additional : pool.name]
}

output "additional_node_pool_ids" {
  description = "Map of additional node pool names to their IDs"
  value       = { for name, pool in azurerm_kubernetes_cluster_node_pool.additional : name => pool.id }
}