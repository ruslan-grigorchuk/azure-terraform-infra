variable "name" {
  description = "Name for the AKS cluster"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,63}$", var.name))
    error_message = "AKS cluster name must be 1-63 characters, letters, numbers, and hyphens only."
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

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use"
  type        = string
  default     = ""
}

variable "node_resource_group" {
  description = "Name of the resource group for AKS nodes (auto-generated if not specified)"
  type        = string
  default     = ""
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "api_server_authorized_ip_ranges" {
  description = "IP ranges authorized to access the API server"
  type        = list(string)
  default     = []
}

variable "role_based_access_control_enabled" {
  description = "Enable RBAC"
  type        = bool
  default     = true
}

variable "azure_policy_enabled" {
  description = "Enable Azure Policy add-on"
  type        = bool
  default     = true
}

variable "http_application_routing_enabled" {
  description = "Enable HTTP application routing add-on"
  type        = bool
  default     = false
}

variable "oms_agent_enabled" {
  description = "Enable OMS agent (Container Insights)"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Container Insights"
  type        = string
  default     = ""
}

# Network Configuration
variable "network_plugin" {
  description = "Network plugin (azure or kubenet)"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Network plugin must be azure or kubenet."
  }
}

variable "network_policy" {
  description = "Network policy (calico, azure, or cilium)"
  type        = string
  default     = "calico"
  validation {
    condition     = contains(["calico", "azure", "cilium"], var.network_policy)
    error_message = "Network policy must be calico, azure, or cilium."
  }
}

variable "docker_bridge_cidr" {
  description = "Docker bridge CIDR"
  type        = string
  default     = "172.17.0.1/16"
}

variable "dns_service_ip" {
  description = "DNS service IP"
  type        = string
  default     = "10.0.0.10"
}

variable "service_cidr" {
  description = "Service CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pod_cidr" {
  description = "Pod CIDR (only used with kubenet)"
  type        = string
  default     = "10.244.0.0/16"
}

variable "vnet_subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
  default     = ""
}

# Node Pool Configuration
variable "default_node_pool" {
  description = "Default node pool configuration"
  type = object({
    name                = optional(string, "default")
    vm_size             = optional(string, "Standard_D2s_v3")
    node_count          = optional(number, 3)
    min_count           = optional(number, 1)
    max_count           = optional(number, 10)
    enable_auto_scaling = optional(bool, true)
    availability_zones  = optional(list(string), ["1", "2", "3"])
    max_pods            = optional(number, 110)
    os_disk_size_gb     = optional(number, 30)
    os_disk_type        = optional(string, "Managed")
    enable_node_public_ip = optional(bool, false)
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
    only_critical_addons_enabled = optional(bool, false)
    orchestrator_version = optional(string, "")
    proximity_placement_group_id = optional(string, "")
    scale_down_mode     = optional(string, "Delete")
    type                = optional(string, "VirtualMachineScaleSets")
    ultra_ssd_enabled   = optional(bool, false)
    upgrade_settings = optional(object({
      max_surge = optional(string, "10%")
    }), {})
  })
  default = {}
}

variable "additional_node_pools" {
  description = "Additional node pools"
  type = map(object({
    vm_size             = string
    node_count          = optional(number, 3)
    min_count           = optional(number, 1)
    max_count           = optional(number, 10)
    enable_auto_scaling = optional(bool, true)
    availability_zones  = optional(list(string), ["1", "2", "3"])
    max_pods            = optional(number, 110)
    os_disk_size_gb     = optional(number, 30)
    os_disk_type        = optional(string, "Managed")
    os_type             = optional(string, "Linux")
    enable_node_public_ip = optional(bool, false)
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
    orchestrator_version = optional(string, "")
    proximity_placement_group_id = optional(string, "")
    scale_down_mode     = optional(string, "Delete")
    mode                = optional(string, "User")
    spot_max_price      = optional(number, -1)
    priority            = optional(string, "Regular")
    eviction_policy     = optional(string, "Delete")
    ultra_ssd_enabled   = optional(bool, false)
    upgrade_settings = optional(object({
      max_surge = optional(string, "10%")
    }), {})
  }))
  default = {}
}

# Identity Configuration
variable "identity_type" {
  description = "Type of identity (SystemAssigned, UserAssigned, or SystemAssigned,UserAssigned)"
  type        = string
  default     = "SystemAssigned"
  validation {
    condition = contains([
      "SystemAssigned",
      "UserAssigned",
      "SystemAssigned,UserAssigned"
    ], var.identity_type)
    error_message = "Identity type must be SystemAssigned, UserAssigned, or SystemAssigned,UserAssigned."
  }
}

variable "user_assigned_identity_ids" {
  description = "List of user assigned identity IDs"
  type        = list(string)
  default     = []
}

# Azure AD Integration
variable "azure_active_directory_role_based_access_control" {
  description = "Azure AD RBAC configuration"
  type = object({
    managed                = optional(bool, true)
    tenant_id              = optional(string, "")
    admin_group_object_ids = optional(list(string), [])
    azure_rbac_enabled     = optional(bool, true)
  })
  default = {
    managed = true
    azure_rbac_enabled = true
  }
}

# Auto Scaling Configuration
variable "auto_scaler_profile" {
  description = "Auto scaler profile configuration"
  type = object({
    balance_similar_node_groups      = optional(bool, false)
    expander                        = optional(string, "random")
    max_graceful_termination_sec    = optional(number, 600)
    max_node_provisioning_time      = optional(string, "15m")
    max_unready_nodes              = optional(number, 3)
    max_unready_percentage         = optional(number, 45)
    new_pod_scale_up_delay         = optional(string, "10s")
    scale_down_delay_after_add     = optional(string, "10m")
    scale_down_delay_after_delete  = optional(string, "10s")
    scale_down_delay_after_failure = optional(string, "3m")
    scan_interval                  = optional(string, "10s")
    scale_down_unneeded           = optional(string, "10m")
    scale_down_unready            = optional(string, "20m")
    scale_down_utilization_threshold = optional(number, 0.5)
    empty_bulk_delete_max         = optional(number, 10)
    skip_nodes_with_local_storage = optional(bool, true)
    skip_nodes_with_system_pods   = optional(bool, true)
  })
  default = {}
}

# Ingress Controller
variable "ingress_application_gateway" {
  description = "Application Gateway Ingress Controller configuration"
  type = object({
    enabled    = optional(bool, false)
    gateway_id = optional(string, "")
    gateway_name = optional(string, "")
    subnet_cidr = optional(string, "")
    subnet_id  = optional(string, "")
  })
  default = {
    enabled = false
  }
}

# Key Vault Integration
variable "key_vault_secrets_provider" {
  description = "Key Vault Secrets Provider configuration"
  type = object({
    enabled                     = optional(bool, false)
    secret_rotation_enabled     = optional(bool, false)
    secret_rotation_interval    = optional(string, "2m")
  })
  default = {
    enabled = false
  }
}

# Maintenance Window
variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    allowed = optional(list(object({
      day   = string
      hours = list(number)
    })), [])
    not_allowed = optional(list(object({
      end   = string
      start = string
    })), [])
  })
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}