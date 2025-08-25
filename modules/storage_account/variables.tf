variable "name" {
  description = "Name for the Storage Account (must be globally unique)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "account_tier" {
  description = "Performance tier for the storage account"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Replication type for the storage account"
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "access_tier" {
  description = "Access tier for BlobStorage and StorageV2 accounts"
  type        = string
  default     = "Hot"
  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "Access tier must be Hot or Cool."
  }
}

variable "enable_https_traffic_only" {
  description = "Force HTTPS traffic only"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "TLS version must be TLS1_0, TLS1_1, or TLS1_2."
  }
}

variable "containers" {
  description = "List of blob containers to create"
  type = list(object({
    name        = string
    access_type = optional(string, "private")
  }))
  default = [
    {
      name        = "uploads"
      access_type = "private"
    },
    {
      name        = "public"
      access_type = "blob"
    }
  ]
}

variable "file_shares" {
  description = "List of file shares to create"
  type = list(object({
    name  = string
    quota = optional(number, 50)
  }))
  default = []
}

variable "queues" {
  description = "List of storage queues to create"
  type        = list(string)
  default     = []
}

variable "tables" {
  description = "List of storage tables to create"
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access the storage account"
  type        = list(string)
  default     = []
}

variable "key_vault_id" {
  description = "Key Vault ID for storing storage account keys"
  type        = string
}

variable "enable_static_website" {
  description = "Enable static website hosting"
  type        = bool
  default     = false
}

variable "static_website_config" {
  description = "Static website configuration"
  type = object({
    index_document     = optional(string, "index.html")
    error_404_document = optional(string, "404.html")
  })
  default = {
    index_document     = "index.html"
    error_404_document = "404.html"
  }
}

variable "enable_versioning" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "delete_retention_policy_days" {
  description = "Number of days to retain deleted blobs"
  type        = number
  default     = 7
  validation {
    condition     = var.delete_retention_policy_days >= 1 && var.delete_retention_policy_days <= 365
    error_message = "Delete retention policy days must be between 1 and 365."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}