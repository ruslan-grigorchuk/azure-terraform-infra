resource "azurerm_servicebus_namespace" "main" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  capacity                      = var.sku == "Premium" ? var.capacity : null
  zone_redundant               = var.sku == "Premium" ? var.zone_redundant : false
  local_auth_enabled           = var.local_auth_enabled
  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version          = var.minimum_tls_version

  # Network rule set (Premium SKU only)
  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" ? [var.network_rule_set] : []
    content {
      default_action                = network_rule_set.value.default_action
      public_network_access_enabled = network_rule_set.value.public_network_access_enabled
      trusted_services_allowed      = network_rule_set.value.trusted_services_allowed
      ip_rules                      = network_rule_set.value.ip_rules

      dynamic "network_rules" {
        for_each = network_rule_set.value.network_rules
        content {
          subnet_id                            = network_rules.value.subnet_id
          ignore_missing_vnet_service_endpoint = network_rules.value.ignore_missing_vnet_service_endpoint
        }
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Authorization Rules
resource "azurerm_servicebus_namespace_authorization_rule" "rules" {
  for_each = { for rule in var.authorization_rules : rule.name => rule }

  name         = each.value.name
  namespace_id = azurerm_servicebus_namespace.main.id
  listen       = each.value.listen
  send         = each.value.send
  manage       = each.value.manage
}

# Queues
resource "azurerm_servicebus_queue" "queues" {
  for_each = { for queue in var.queues : queue.name => queue }

  name         = each.value.name
  namespace_id = azurerm_servicebus_namespace.main.id

  max_message_size_in_kilobytes          = each.value.max_message_size_in_kilobytes
  max_size_in_megabytes                  = each.value.max_size_in_megabytes
  requires_duplicate_detection           = each.value.requires_duplicate_detection
  requires_session                       = each.value.requires_session
  default_message_ttl                    = each.value.default_message_ttl
  dead_lettering_on_message_expiration   = each.value.dead_lettering_on_message_expiration
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  max_delivery_count                     = each.value.max_delivery_count
  status                                 = each.value.status
  enable_batched_operations              = each.value.enable_batched_operations
  auto_delete_on_idle                    = each.value.auto_delete_on_idle
  enable_express                         = each.value.enable_express
  enable_partitioning                    = each.value.enable_partitioning
  lock_duration                          = each.value.lock_duration
}

# Topics
resource "azurerm_servicebus_topic" "topics" {
  for_each = { for topic in var.topics : topic.name => topic }

  name         = each.value.name
  namespace_id = azurerm_servicebus_namespace.main.id

  max_message_size_in_kilobytes           = each.value.max_message_size_in_kilobytes
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  requires_duplicate_detection            = each.value.requires_duplicate_detection
  default_message_ttl                     = each.value.default_message_ttl
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  enable_batched_operations               = each.value.enable_batched_operations
  auto_delete_on_idle                     = each.value.auto_delete_on_idle
  enable_express                          = each.value.enable_express
  enable_partitioning                     = each.value.enable_partitioning
  support_ordering                        = each.value.support_ordering
  status                                  = each.value.status
}

# Topic Subscriptions
resource "azurerm_servicebus_subscription" "subscriptions" {
  for_each = { for sub in var.subscriptions : "${sub.topic_name}-${sub.name}" => sub }

  name     = each.value.name
  topic_id = azurerm_servicebus_topic.topics[each.value.topic_name].id

  max_delivery_count                         = each.value.max_delivery_count
  default_message_ttl                        = each.value.default_message_ttl
  auto_delete_on_idle                        = each.value.auto_delete_on_idle
  dead_lettering_on_message_expiration       = each.value.dead_lettering_on_message_expiration
  dead_lettering_on_filter_evaluation_error = each.value.dead_lettering_on_filter_evaluation_error
  enable_batched_operations                  = each.value.enable_batched_operations
  requires_session                           = each.value.requires_session
  status                                     = each.value.status
  lock_duration                              = each.value.lock_duration
  forward_to                                 = each.value.forward_to != "" ? each.value.forward_to : null
  forward_dead_lettered_messages_to          = each.value.forward_dead_lettered_messages_to != "" ? each.value.forward_dead_lettered_messages_to : null
}

# Private Endpoint (Premium SKU only)
resource "azurerm_private_endpoint" "main" {
  count               = var.enable_private_endpoint && var.sku == "Premium" && var.private_endpoint_subnet_id != "" ? 1 : 0
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_servicebus_namespace.main.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.servicebus[0].id]
  }

  tags = var.tags
}

# Private DNS Zone (for private endpoint)
resource "azurerm_private_dns_zone" "servicebus" {
  count               = var.enable_private_endpoint && var.sku == "Premium" ? 1 : 0
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count              = var.diagnostic_logs_enabled && var.log_analytics_workspace_id != "" ? 1 : 0
  name               = "${var.name}-diagnostics"
  target_resource_id = azurerm_servicebus_namespace.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "OperationalLogs"
  }

  enabled_log {
    category = "VNetAndIPFilteringLogs"
  }

  enabled_log {
    category = "RuntimeAuditLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Store connection strings in Key Vault
resource "azurerm_key_vault_secret" "primary_connection_string" {
  name         = "${var.name}-primary-connection-string"
  value        = azurerm_servicebus_namespace_authorization_rule.rules["RootManageSharedAccessKey"].primary_connection_string
  key_vault_id = var.key_vault_id

  tags = var.tags
}

resource "azurerm_key_vault_secret" "secondary_connection_string" {
  name         = "${var.name}-secondary-connection-string"
  value        = azurerm_servicebus_namespace_authorization_rule.rules["RootManageSharedAccessKey"].secondary_connection_string
  key_vault_id = var.key_vault_id

  tags = var.tags
}

# Queue Authorization Rules (example for specific queue access)
resource "azurerm_servicebus_queue_authorization_rule" "queue_send_only" {
  for_each = { for queue in var.queues : queue.name => queue }

  name     = "${each.value.name}-send-only"
  queue_id = azurerm_servicebus_queue.queues[each.key].id
  listen   = false
  send     = true
  manage   = false
}

resource "azurerm_servicebus_queue_authorization_rule" "queue_listen_only" {
  for_each = { for queue in var.queues : queue.name => queue }

  name     = "${each.value.name}-listen-only"
  queue_id = azurerm_servicebus_queue.queues[each.key].id
  listen   = true
  send     = false
  manage   = false
}

# Topic Authorization Rules (example for specific topic access)
resource "azurerm_servicebus_topic_authorization_rule" "topic_send_only" {
  for_each = { for topic in var.topics : topic.name => topic }

  name     = "${each.value.name}-send-only"
  topic_id = azurerm_servicebus_topic.topics[each.key].id
  listen   = false
  send     = true
  manage   = false
}

resource "azurerm_servicebus_topic_authorization_rule" "topic_listen_only" {
  for_each = { for topic in var.topics : topic.name => topic }

  name     = "${each.value.name}-listen-only"
  topic_id = azurerm_servicebus_topic.topics[each.key].id
  listen   = true
  send     = false
  manage   = false
}