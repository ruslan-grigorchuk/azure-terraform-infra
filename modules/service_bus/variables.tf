variable "name" {
  description = "Name for the Service Bus namespace"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{4,48}[a-zA-Z0-9]$", var.name))
    error_message = "Service Bus namespace name must be 6-50 characters, start with a letter, and contain only letters, numbers, and hyphens."
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

variable "sku" {
  description = "SKU of the Service Bus namespace"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "Service Bus SKU must be Basic, Standard, or Premium."
  }
}

variable "capacity" {
  description = "Number of message units for Premium SKU"
  type        = number
  default     = 1
  validation {
    condition     = var.capacity >= 1 && var.capacity <= 16
    error_message = "Capacity must be between 1 and 16 for Premium SKU."
  }
}

variable "zone_redundant" {
  description = "Enable zone redundancy (Premium SKU only)"
  type        = bool
  default     = false
}

variable "local_auth_enabled" {
  description = "Enable local authentication with access keys"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "Minimum TLS version must be 1.0, 1.1, or 1.2."
  }
}

variable "queues" {
  description = "List of queues to create"
  type = list(object({
    name                                    = string
    max_message_size_in_kilobytes          = optional(number, 256)
    max_size_in_megabytes                  = optional(number, 1024)
    requires_duplicate_detection           = optional(bool, false)
    requires_session                       = optional(bool, false)
    default_message_ttl                    = optional(string, "P14D")
    dead_lettering_on_message_expiration   = optional(bool, false)
    duplicate_detection_history_time_window = optional(string, "PT10M")
    max_delivery_count                     = optional(number, 10)
    status                                 = optional(string, "Active")
    enable_batched_operations              = optional(bool, true)
    auto_delete_on_idle                    = optional(string, "P10675199DT2H48M5.4775807S")
    enable_express                         = optional(bool, false)
    enable_partitioning                    = optional(bool, false)
    lock_duration                          = optional(string, "PT1M")
  }))
  default = []
}

variable "topics" {
  description = "List of topics to create"
  type = list(object({
    name                         = string
    max_message_size_in_kilobytes = optional(number, 256)
    max_size_in_megabytes        = optional(number, 1024)
    requires_duplicate_detection = optional(bool, false)
    default_message_ttl          = optional(string, "P14D")
    duplicate_detection_history_time_window = optional(string, "PT10M")
    enable_batched_operations    = optional(bool, true)
    auto_delete_on_idle          = optional(string, "P10675199DT2H48M5.4775807S")
    enable_express               = optional(bool, false)
    enable_partitioning          = optional(bool, false)
    support_ordering             = optional(bool, false)
    status                       = optional(string, "Active")
  }))
  default = []
}

variable "subscriptions" {
  description = "List of topic subscriptions to create"
  type = list(object({
    name                                 = string
    topic_name                          = string
    max_delivery_count                  = optional(number, 10)
    default_message_ttl                 = optional(string, "P14D")
    auto_delete_on_idle                 = optional(string, "P10675199DT2H48M5.4775807S")
    dead_lettering_on_message_expiration = optional(bool, true)
    dead_lettering_on_filter_evaluation_error = optional(bool, true)
    enable_batched_operations           = optional(bool, true)
    requires_session                    = optional(bool, false)
    status                              = optional(string, "Active")
    lock_duration                       = optional(string, "PT1M")
    forward_to                          = optional(string, "")
    forward_dead_lettered_messages_to   = optional(string, "")
  }))
  default = []
}

variable "authorization_rules" {
  description = "List of authorization rules to create"
  type = list(object({
    name   = string
    listen = optional(bool, false)
    send   = optional(bool, false)
    manage = optional(bool, false)
  }))
  default = [
    {
      name   = "RootManageSharedAccessKey"
      listen = true
      send   = true
      manage = true
    }
  ]
}

variable "network_rule_set" {
  description = "Network rule set configuration"
  type = object({
    default_action                = optional(string, "Allow")
    public_network_access_enabled = optional(bool, true)
    trusted_services_allowed      = optional(bool, false)
    ip_rules                      = optional(list(string), [])
    network_rules = optional(list(object({
      subnet_id                            = string
      ignore_missing_vnet_service_endpoint = optional(bool, false)
    })), [])
  })
  default = {
    default_action = "Allow"
  }
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint (Premium SKU only)"
  type        = string
  default     = ""
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint (Premium SKU only)"
  type        = bool
  default     = false
}

variable "diagnostic_logs_enabled" {
  description = "Enable diagnostic logs"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic logs"
  type        = string
  default     = ""
}

variable "key_vault_id" {
  description = "Key Vault ID for storing connection strings"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}