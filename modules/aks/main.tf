data "azurerm_client_config" "current" {}

# Log Analytics Workspace for Container Insights
resource "azurerm_log_analytics_workspace" "aks" {
  count               = var.oms_agent_enabled && var.log_analytics_workspace_id == "" ? 1 : 0
  name                = "${var.name}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

data "azurerm_log_analytics_workspace" "existing" {
  count               = var.log_analytics_workspace_id != "" ? 1 : 0
  name                = split("/", var.log_analytics_workspace_id)[8]
  resource_group_name = split("/", var.log_analytics_workspace_id)[4]
}

locals {
  log_analytics_workspace_id = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : (var.oms_agent_enabled ? azurerm_log_analytics_workspace.aks[0].id : null)
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix != "" ? var.dns_prefix : var.name
  kubernetes_version  = var.kubernetes_version != "" ? var.kubernetes_version : null
  node_resource_group = var.node_resource_group != "" ? var.node_resource_group : "${var.resource_group_name}-nodes"

  private_cluster_enabled             = var.private_cluster_enabled
  api_server_authorized_ip_ranges     = var.api_server_authorized_ip_ranges
  role_based_access_control_enabled   = var.role_based_access_control_enabled
  http_application_routing_enabled    = var.http_application_routing_enabled

  # Default Node Pool
  default_node_pool {
    name                         = var.default_node_pool.name
    vm_size                      = var.default_node_pool.vm_size
    node_count                   = var.default_node_pool.enable_auto_scaling ? null : var.default_node_pool.node_count
    min_count                    = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.min_count : null
    max_count                    = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.max_count : null
    enable_auto_scaling          = var.default_node_pool.enable_auto_scaling
    availability_zones           = var.default_node_pool.availability_zones
    max_pods                     = var.default_node_pool.max_pods
    os_disk_size_gb             = var.default_node_pool.os_disk_size_gb
    os_disk_type                = var.default_node_pool.os_disk_type
    enable_node_public_ip       = var.default_node_pool.enable_node_public_ip
    node_labels                 = var.default_node_pool.node_labels
    node_taints                 = var.default_node_pool.node_taints
    only_critical_addons_enabled = var.default_node_pool.only_critical_addons_enabled
    orchestrator_version        = var.default_node_pool.orchestrator_version != "" ? var.default_node_pool.orchestrator_version : null
    proximity_placement_group_id = var.default_node_pool.proximity_placement_group_id != "" ? var.default_node_pool.proximity_placement_group_id : null
    scale_down_mode             = var.default_node_pool.scale_down_mode
    type                        = var.default_node_pool.type
    ultra_ssd_enabled           = var.default_node_pool.ultra_ssd_enabled
    vnet_subnet_id              = var.vnet_subnet_id != "" ? var.vnet_subnet_id : null

    dynamic "upgrade_settings" {
      for_each = var.default_node_pool.upgrade_settings != null ? [var.default_node_pool.upgrade_settings] : []
      content {
        max_surge = upgrade_settings.value.max_surge
      }
    }
  }

  # Identity
  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned,UserAssigned" ? var.user_assigned_identity_ids : null
  }

  # Network Profile
  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    docker_bridge_cidr = var.docker_bridge_cidr
    dns_service_ip     = var.dns_service_ip
    service_cidr       = var.service_cidr
    pod_cidr           = var.network_plugin == "kubenet" ? var.pod_cidr : null
  }

  # Azure AD Integration
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.role_based_access_control_enabled ? [var.azure_active_directory_role_based_access_control] : []
    content {
      managed                = azure_active_directory_role_based_access_control.value.managed
      tenant_id              = azure_active_directory_role_based_access_control.value.tenant_id != "" ? azure_active_directory_role_based_access_control.value.tenant_id : data.azurerm_client_config.current.tenant_id
      admin_group_object_ids = azure_active_directory_role_based_access_control.value.admin_group_object_ids
      azure_rbac_enabled     = azure_active_directory_role_based_access_control.value.azure_rbac_enabled
    }
  }

  # Auto Scaler Profile
  dynamic "auto_scaler_profile" {
    for_each = var.auto_scaler_profile != null ? [var.auto_scaler_profile] : []
    content {
      balance_similar_node_groups      = auto_scaler_profile.value.balance_similar_node_groups
      expander                        = auto_scaler_profile.value.expander
      max_graceful_termination_sec    = auto_scaler_profile.value.max_graceful_termination_sec
      max_node_provisioning_time      = auto_scaler_profile.value.max_node_provisioning_time
      max_unready_nodes              = auto_scaler_profile.value.max_unready_nodes
      max_unready_percentage         = auto_scaler_profile.value.max_unready_percentage
      new_pod_scale_up_delay         = auto_scaler_profile.value.new_pod_scale_up_delay
      scale_down_delay_after_add     = auto_scaler_profile.value.scale_down_delay_after_add
      scale_down_delay_after_delete  = auto_scaler_profile.value.scale_down_delay_after_delete
      scale_down_delay_after_failure = auto_scaler_profile.value.scale_down_delay_after_failure
      scan_interval                  = auto_scaler_profile.value.scan_interval
      scale_down_unneeded           = auto_scaler_profile.value.scale_down_unneeded
      scale_down_unready            = auto_scaler_profile.value.scale_down_unready
      scale_down_utilization_threshold = auto_scaler_profile.value.scale_down_utilization_threshold
      empty_bulk_delete_max         = auto_scaler_profile.value.empty_bulk_delete_max
      skip_nodes_with_local_storage = auto_scaler_profile.value.skip_nodes_with_local_storage
      skip_nodes_with_system_pods   = auto_scaler_profile.value.skip_nodes_with_system_pods
    }
  }

  # OMS Agent (Container Insights)
  dynamic "oms_agent" {
    for_each = var.oms_agent_enabled ? [1] : []
    content {
      log_analytics_workspace_id = local.log_analytics_workspace_id
    }
  }

  # Azure Policy
  dynamic "azure_policy_enabled" {
    for_each = var.azure_policy_enabled ? [1] : []
    content {
      
    }
  }

  # Application Gateway Ingress Controller
  dynamic "ingress_application_gateway" {
    for_each = var.ingress_application_gateway.enabled ? [var.ingress_application_gateway] : []
    content {
      gateway_id   = ingress_application_gateway.value.gateway_id != "" ? ingress_application_gateway.value.gateway_id : null
      gateway_name = ingress_application_gateway.value.gateway_name != "" ? ingress_application_gateway.value.gateway_name : null
      subnet_cidr  = ingress_application_gateway.value.subnet_cidr != "" ? ingress_application_gateway.value.subnet_cidr : null
      subnet_id    = ingress_application_gateway.value.subnet_id != "" ? ingress_application_gateway.value.subnet_id : null
    }
  }

  # Key Vault Secrets Provider
  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider.enabled ? [var.key_vault_secrets_provider] : []
    content {
      secret_rotation_enabled  = key_vault_secrets_provider.value.secret_rotation_enabled
      secret_rotation_interval = key_vault_secrets_provider.value.secret_rotation_interval
    }
  }

  # Maintenance Window
  dynamic "maintenance_window" {
    for_each = length(var.maintenance_window) > 0 ? [var.maintenance_window] : []
    content {
      dynamic "allowed" {
        for_each = maintenance_window.value.allowed != null ? maintenance_window.value.allowed : []
        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }

      dynamic "not_allowed" {
        for_each = maintenance_window.value.not_allowed != null ? maintenance_window.value.not_allowed : []
        content {
          end   = not_allowed.value.end
          start = not_allowed.value.start
        }
      }
    }
  }

  tags = var.tags
}

# Additional Node Pools
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = each.value.vm_size
  node_count           = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count            = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count            = each.value.enable_auto_scaling ? each.value.max_count : null
  enable_auto_scaling  = each.value.enable_auto_scaling
  availability_zones   = each.value.availability_zones
  max_pods             = each.value.max_pods
  os_disk_size_gb      = each.value.os_disk_size_gb
  os_disk_type         = each.value.os_disk_type
  os_type              = each.value.os_type
  enable_node_public_ip = each.value.enable_node_public_ip
  node_labels          = each.value.node_labels
  node_taints          = each.value.node_taints
  orchestrator_version = each.value.orchestrator_version != "" ? each.value.orchestrator_version : null
  proximity_placement_group_id = each.value.proximity_placement_group_id != "" ? each.value.proximity_placement_group_id : null
  scale_down_mode      = each.value.scale_down_mode
  mode                 = each.value.mode
  spot_max_price       = each.value.priority == "Spot" ? each.value.spot_max_price : null
  priority             = each.value.priority
  eviction_policy      = each.value.priority == "Spot" ? each.value.eviction_policy : null
  ultra_ssd_enabled    = each.value.ultra_ssd_enabled
  vnet_subnet_id       = var.vnet_subnet_id != "" ? var.vnet_subnet_id : null

  dynamic "upgrade_settings" {
    for_each = each.value.upgrade_settings != null ? [each.value.upgrade_settings] : []
    content {
      max_surge = upgrade_settings.value.max_surge
    }
  }

  tags = var.tags
}

# Role assignments for AKS cluster identity
resource "azurerm_role_assignment" "aks_network_contributor" {
  count                = var.vnet_subnet_id != "" ? 1 : 0
  scope                = var.vnet_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "aks" {
  count              = var.log_analytics_workspace_id != "" ? 1 : 0
  name               = "${var.name}-diagnostics"
  target_resource_id = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = local.log_analytics_workspace_id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  enabled_log {
    category = "guard"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}