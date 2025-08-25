variable "name" {
  description = "Name for the App Service Plan and Web App"
  type        = string
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku_name" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "B1"
  validation {
    condition     = contains(["F1", "D1", "B1", "B2", "B3", "S1", "S2", "S3", "P1v2", "P2v2", "P3v2", "P1v3", "P2v3", "P3v3"], var.sku_name)
    error_message = "Invalid App Service Plan SKU."
  }
}

variable "custom_domain" {
  description = "Custom domain name for the web app (optional)"
  type        = string
  default     = ""
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access the app service"
  type        = list(string)
  default     = []
}

variable "app_settings" {
  description = "App settings for the web app"
  type        = map(string)
  default     = {}
}

variable "connection_strings" {
  description = "Connection strings for the web app"
  type = map(object({
    name  = string
    type  = string
    value = string
  }))
  default = {}
}

variable "key_vault_id" {
  description = "Key Vault ID for storing SSL certificates and secrets"
  type        = string
  default     = ""
}

variable "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}