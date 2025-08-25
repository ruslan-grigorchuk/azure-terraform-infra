resource "azurerm_storage_account" "main" {
  name                      = var.name
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_tier              = var.account_tier
  account_replication_type  = var.account_replication_type
  access_tier               = var.access_tier
  enable_https_traffic_only = var.enable_https_traffic_only
  min_tls_version          = var.min_tls_version
  account_kind             = "StorageV2"

  # Security settings
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  # Blob properties
  blob_properties {
    versioning_enabled = var.enable_versioning
    
    delete_retention_policy {
      days = var.delete_retention_policy_days
    }

    container_delete_retention_policy {
      days = var.delete_retention_policy_days
    }

    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "POST", "PUT", "DELETE", "OPTIONS"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }

  # Queue properties
  queue_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "POST", "PUT", "DELETE", "OPTIONS"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }

    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 10
    }

    minute_metrics {
      enabled               = true
      version               = "1.0"
      include_apis          = true
      retention_policy_days = 10
    }

    hour_metrics {
      enabled               = true
      version               = "1.0"
      include_apis          = true
      retention_policy_days = 10
    }
  }

  # Network access rules
  dynamic "network_rules" {
    for_each = length(var.allowed_ip_ranges) > 0 ? [1] : []
    content {
      default_action = "Deny"
      ip_rules       = var.allowed_ip_ranges
      bypass         = ["AzureServices"]
    }
  }

  # Static website configuration
  dynamic "static_website" {
    for_each = var.enable_static_website ? [1] : []
    content {
      index_document     = var.static_website_config.index_document
      error_404_document = var.static_website_config.error_404_document
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Blob containers
resource "azurerm_storage_container" "containers" {
  for_each = { for container in var.containers : container.name => container }

  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = each.value.access_type
}

# File shares
resource "azurerm_storage_share" "shares" {
  for_each = { for share in var.file_shares : share.name => share }

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.main.name
  quota                = each.value.quota
}

# Storage queues
resource "azurerm_storage_queue" "queues" {
  for_each = toset(var.queues)

  name                 = each.key
  storage_account_name = azurerm_storage_account.main.name
}

# Storage tables
resource "azurerm_storage_table" "tables" {
  for_each = toset(var.tables)

  name                 = each.key
  storage_account_name = azurerm_storage_account.main.name
}

# Store storage account keys in Key Vault
resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "${var.name}-storage-key"
  value        = azurerm_storage_account.main.primary_access_key
  key_vault_id = var.key_vault_id

  tags = var.tags
}

resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "${var.name}-storage-connection-string"
  value        = azurerm_storage_account.main.primary_connection_string
  key_vault_id = var.key_vault_id

  tags = var.tags
}

# Management policy for lifecycle management
resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "default"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }

      snapshot {
        delete_after_days_since_creation_greater_than = 30
      }

      version {
        delete_after_days_since_creation = 30
      }
    }
  }
}