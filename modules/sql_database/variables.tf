variable "name" {
  description = "Name for the SQL Server and Database"
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

variable "administrator_login" {
  description = "Administrator login for the SQL Server"
  type        = string
  default     = "sqladmin"
}

variable "administrator_login_password" {
  description = "Administrator password for the SQL Server"
  type        = string
  sensitive   = true
  default     = ""
}

variable "sku_name" {
  description = "SKU for the SQL Database"
  type        = string
  default     = "S0"
  validation {
    condition = can(regex("^(GP_|HS_|BC_|S[0-9]|P[0-9]|DW[0-9]+c|DS[0-9]+)", var.sku_name))
    error_message = "Invalid SQL Database SKU name."
  }
}

variable "max_size_gb" {
  description = "Maximum size of the database in gigabytes"
  type        = number
  default     = 10
  validation {
    condition     = var.max_size_gb > 0 && var.max_size_gb <= 4096
    error_message = "Database size must be between 1 and 4096 GB."
  }
}

variable "collation" {
  description = "Collation for the database"
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access the SQL Server"
  type        = list(string)
  default     = []
}

variable "key_vault_id" {
  description = "Key Vault ID for storing database credentials"
  type        = string
}

variable "enable_threat_detection" {
  description = "Enable Advanced Threat Protection"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 1 and 35."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}