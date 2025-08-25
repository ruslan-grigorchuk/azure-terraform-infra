variable "name" {
  description = "Name for the Key Vault"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.name))
    error_message = "Key Vault name must be 3-24 characters, letters, numbers, and hyphens only."
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

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
  default     = ""
}

variable "sku_name" {
  description = "SKU for the Key Vault"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "Key Vault SKU must be standard or premium."
  }
}

variable "enabled_for_deployment" {
  description = "Enable Key Vault for Azure Virtual Machine deployment"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Enable Key Vault for Azure Disk Encryption"
  type        = bool
  default     = true
}

variable "enabled_for_template_deployment" {
  description = "Enable Key Vault for Azure Resource Manager template deployment"
  type        = bool
  default     = true
}

variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization for Key Vault"
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days that items should be retained in soft delete"
  type        = number
  default     = 90
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "access_policies" {
  description = "List of access policies for the Key Vault"
  type = list(object({
    object_id               = string
    certificate_permissions = optional(list(string), [])
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
  }))
  default = []
}

variable "network_access_default_action" {
  description = "Default action for network access rules"
  type        = string
  default     = "Deny"
  validation {
    condition     = contains(["Allow", "Deny"], var.network_access_default_action)
    error_message = "Network access default action must be Allow or Deny."
  }
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access the Key Vault"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access the Key Vault"
  type        = list(string)
  default     = []
}

variable "bypass_azure_services" {
  description = "Allow trusted Azure services to bypass firewall"
  type        = bool
  default     = true
}

variable "secrets" {
  description = "Map of secrets to create in the Key Vault"
  type = map(object({
    value        = string
    content_type = optional(string, "")
    tags         = optional(map(string), {})
  }))
  default   = {}
  sensitive = true
}

variable "certificates" {
  description = "List of certificates to create in the Key Vault"
  type = list(object({
    name = string
    certificate = optional(object({
      contents = string
      password = optional(string, "")
    }))
    certificate_policy = optional(object({
      issuer_parameters = object({
        name = string
      })
      key_properties = object({
        exportable = bool
        key_size   = number
        key_type   = string
        reuse_key  = bool
      })
      lifetime_action = optional(object({
        action = object({
          action_type = string
        })
        trigger = object({
          days_before_expiry  = optional(number)
          lifetime_percentage = optional(number)
        })
      }))
      secret_properties = object({
        content_type = string
      })
      x509_certificate_properties = object({
        extended_key_usage = optional(list(string))
        key_usage          = list(string)
        subject            = string
        validity_in_months = number
        subject_alternative_names = optional(object({
          dns_names = optional(list(string))
          emails    = optional(list(string))
          upns      = optional(list(string))
        }))
      })
    }))
  }))
  default = []
}

variable "diagnostic_logs_enabled" {
  description = "Enable diagnostic logs for Key Vault"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic logs"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}