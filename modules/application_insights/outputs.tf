output "application_insights_id" {
  description = "ID of the Application Insights instance"
  value       = azurerm_application_insights.main.id
}

output "application_insights_name" {
  description = "Name of the Application Insights instance"
  value       = azurerm_application_insights.main.name
}

output "instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "app_id" {
  description = "Application ID for Application Insights"
  value       = azurerm_application_insights.main.app_id
}

output "workspace_id" {
  description = "Log Analytics workspace ID"
  value       = local.workspace_id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = var.workspace_id == "" ? azurerm_log_analytics_workspace.main[0].name : data.azurerm_log_analytics_workspace.existing[0].name
}

output "web_test_ids" {
  description = "Map of web test names to their IDs"
  value       = { for name, test in azurerm_application_insights_web_test.tests : name => test.id }
}

output "api_key_id" {
  description = "ID of the read-only API key"
  value       = azurerm_application_insights_api_key.read_only.id
}

output "api_key" {
  description = "Read-only API key for Application Insights"
  value       = azurerm_application_insights_api_key.read_only.api_key
  sensitive   = true
}

output "workbook_id" {
  description = "ID of the Application Insights workbook"
  value       = azurerm_application_insights_workbook.main.id
}