variable "name" {
  description = "Name for the Application Insights instance"
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

variable "application_type" {
  description = "Type of application being monitored"
  type        = string
  default     = "web"
  validation {
    condition = contains([
      "web", "java", "MobileCenter", "other", "phone", "store", "ios", "Node.JS"
    ], var.application_type)
    error_message = "Application type must be one of: web, java, MobileCenter, other, phone, store, ios, Node.JS."
  }
}

variable "retention_in_days" {
  description = "Data retention period in days"
  type        = number
  default     = 90
  validation {
    condition = contains([
      30, 60, 90, 120, 180, 270, 365, 550, 730
    ], var.retention_in_days)
    error_message = "Retention period must be one of: 30, 60, 90, 120, 180, 270, 365, 550, 730 days."
  }
}

variable "sampling_percentage" {
  description = "Sampling percentage for telemetry"
  type        = number
  default     = 100
  validation {
    condition     = var.sampling_percentage >= 0 && var.sampling_percentage <= 100
    error_message = "Sampling percentage must be between 0 and 100."
  }
}

variable "disable_ip_masking" {
  description = "Disable IP address masking"
  type        = bool
  default     = false
}

variable "workspace_id" {
  description = "Log Analytics workspace ID (required for workspace-based Application Insights)"
  type        = string
  default     = ""
}

variable "internet_ingestion_enabled" {
  description = "Enable ingestion from public internet"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Enable querying from public internet"
  type        = bool
  default     = true
}

variable "force_customer_storage_for_profiler" {
  description = "Force the use of customer storage account for profiler"
  type        = bool
  default     = false
}

variable "local_authentication_disabled" {
  description = "Disable local authentication (API key based)"
  type        = bool
  default     = false
}

variable "daily_data_cap_in_gb" {
  description = "Daily data volume cap in GB"
  type        = number
  default     = 10
  validation {
    condition     = var.daily_data_cap_in_gb >= 0.023 && var.daily_data_cap_in_gb <= 1000
    error_message = "Daily data cap must be between 0.023 and 1000 GB."
  }
}

variable "daily_data_cap_notifications_disabled" {
  description = "Disable daily data cap notifications"
  type        = bool
  default     = false
}

variable "availability_tests" {
  description = "List of availability tests to create"
  type = list(object({
    name                    = string
    url                     = string
    enabled                 = optional(bool, true)
    timeout                 = optional(number, 120)
    frequency               = optional(number, 300)
    retry_enabled           = optional(bool, true)
    description             = optional(string, "")
    geo_locations           = optional(list(string), ["us-tx-sn1-azr", "us-il-ch1-azr"])
    expected_status_code    = optional(number, 200)
    ssl_check_enabled       = optional(bool, true)
    follow_redirects        = optional(bool, true)
  }))
  default = []
}

variable "action_groups" {
  description = "List of action group IDs for alerts"
  type        = list(string)
  default     = []
}

variable "smart_detection_rules" {
  description = "Smart detection rule configurations"
  type = list(object({
    name                    = string
    enabled                 = optional(bool, true)
    send_emails_to_subscription_owners = optional(bool, false)
    additional_email_recipients = optional(list(string), [])
  }))
  default = [
    {
      name = "Slow page load time"
    },
    {
      name = "Slow server response time"
    },
    {
      name = "Degradation in server response time"
    },
    {
      name = "Abnormal rise in exception volume"
    },
    {
      name = "Potential memory leak detected"
    }
  ]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}