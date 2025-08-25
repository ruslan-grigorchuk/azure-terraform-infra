output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "primary_access_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Secondary access key for the storage account"
  value       = azurerm_storage_account.main.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string for the storage account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "Secondary connection string for the storage account"
  value       = azurerm_storage_account.main.secondary_connection_string
  sensitive   = true
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_queue_endpoint" {
  description = "Primary queue endpoint"
  value       = azurerm_storage_account.main.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "Primary table endpoint"
  value       = azurerm_storage_account.main.primary_table_endpoint
}

output "primary_file_endpoint" {
  description = "Primary file endpoint"
  value       = azurerm_storage_account.main.primary_file_endpoint
}

output "primary_web_endpoint" {
  description = "Primary web endpoint (static website)"
  value       = azurerm_storage_account.main.primary_web_endpoint
}

output "primary_web_host" {
  description = "Primary web host (static website)"
  value       = azurerm_storage_account.main.primary_web_host
}

output "storage_account_identity_principal_id" {
  description = "Principal ID of the storage account managed identity"
  value       = azurerm_storage_account.main.identity[0].principal_id
}

output "container_names" {
  description = "Names of created blob containers"
  value       = [for container in azurerm_storage_container.containers : container.name]
}

output "share_names" {
  description = "Names of created file shares"
  value       = [for share in azurerm_storage_share.shares : share.name]
}

output "queue_names" {
  description = "Names of created storage queues"
  value       = [for queue in azurerm_storage_queue.queues : queue.name]
}

output "table_names" {
  description = "Names of created storage tables"
  value       = [for table in azurerm_storage_table.tables : table.name]
}