output "namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.id
}

output "namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.name
}

output "namespace_hostname" {
  description = "Hostname of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.name
}

output "namespace_fqdn" {
  description = "FQDN of the Service Bus namespace"
  value       = "${azurerm_servicebus_namespace.main.name}.servicebus.windows.net"
}

output "primary_connection_string" {
  description = "Primary connection string for the Service Bus namespace"
  value       = azurerm_servicebus_namespace_authorization_rule.rules["RootManageSharedAccessKey"].primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "Secondary connection string for the Service Bus namespace"
  value       = azurerm_servicebus_namespace_authorization_rule.rules["RootManageSharedAccessKey"].secondary_connection_string
  sensitive   = true
}

output "primary_key" {
  description = "Primary key for the Service Bus namespace"
  value       = azurerm_servicebus_namespace_authorization_rule.rules["RootManageSharedAccessKey"].primary_key
  sensitive   = true
}

output "secondary_key" {
  description = "Secondary key for the Service Bus namespace"
  value       = azurerm_servicebus_namespace_authorization_rule.rules["RootManageSharedAccessKey"].secondary_key
  sensitive   = true
}

output "namespace_identity_principal_id" {
  description = "Principal ID of the Service Bus namespace managed identity"
  value       = azurerm_servicebus_namespace.main.identity[0].principal_id
}

output "queue_names" {
  description = "Names of created queues"
  value       = [for queue in azurerm_servicebus_queue.queues : queue.name]
}

output "topic_names" {
  description = "Names of created topics"
  value       = [for topic in azurerm_servicebus_topic.topics : topic.name]
}

output "subscription_names" {
  description = "Names of created subscriptions"
  value       = [for sub in azurerm_servicebus_subscription.subscriptions : sub.name]
}

output "queue_ids" {
  description = "Map of queue names to their IDs"
  value       = { for name, queue in azurerm_servicebus_queue.queues : name => queue.id }
}

output "topic_ids" {
  description = "Map of topic names to their IDs"
  value       = { for name, topic in azurerm_servicebus_topic.topics : name => topic.id }
}

output "subscription_ids" {
  description = "Map of subscription names to their IDs"
  value       = { for name, sub in azurerm_servicebus_subscription.subscriptions : name => sub.id }
}

output "queue_send_only_connection_strings" {
  description = "Map of queue names to their send-only connection strings"
  value       = { for name, rule in azurerm_servicebus_queue_authorization_rule.queue_send_only : name => rule.primary_connection_string }
  sensitive   = true
}

output "queue_listen_only_connection_strings" {
  description = "Map of queue names to their listen-only connection strings"
  value       = { for name, rule in azurerm_servicebus_queue_authorization_rule.queue_listen_only : name => rule.primary_connection_string }
  sensitive   = true
}

output "topic_send_only_connection_strings" {
  description = "Map of topic names to their send-only connection strings"
  value       = { for name, rule in azurerm_servicebus_topic_authorization_rule.topic_send_only : name => rule.primary_connection_string }
  sensitive   = true
}

output "topic_listen_only_connection_strings" {
  description = "Map of topic names to their listen-only connection strings"
  value       = { for name, rule in azurerm_servicebus_topic_authorization_rule.topic_listen_only : name => rule.primary_connection_string }
  sensitive   = true
}

output "private_endpoint_fqdn" {
  description = "FQDN of the private endpoint"
  value       = var.enable_private_endpoint && var.sku == "Premium" ? azurerm_private_endpoint.main[0].private_service_connection[0].private_ip_address : null
}