data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enabled_for_disk_encryption   = var.enabled_for_disk_encryption
  enabled_for_deployment        = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  tenant_id                     = var.tenant_id != "" ? var.tenant_id : data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days    = var.soft_delete_retention_days
  purge_protection_enabled      = var.purge_protection_enabled
  sku_name                      = var.sku_name
  enable_rbac_authorization     = var.enable_rbac_authorization

  # Network access rules
  network_acls {
    default_action = var.network_access_default_action
    bypass         = var.bypass_azure_services ? "AzureServices" : "None"
    ip_rules       = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  # Access policies (only if RBAC authorization is disabled)
  dynamic "access_policy" {
    for_each = var.enable_rbac_authorization ? [] : var.access_policies
    content {
      tenant_id = var.tenant_id != "" ? var.tenant_id : data.azurerm_client_config.current.tenant_id
      object_id = access_policy.value.object_id

      certificate_permissions = access_policy.value.certificate_permissions
      key_permissions         = access_policy.value.key_permissions
      secret_permissions      = access_policy.value.secret_permissions
    }
  }

  # Default access policy for current user/service principal (only if RBAC is disabled)
  dynamic "access_policy" {
    for_each = var.enable_rbac_authorization ? [] : [1]
    content {
      tenant_id = var.tenant_id != "" ? var.tenant_id : data.azurerm_client_config.current.tenant_id
      object_id = data.azurerm_client_config.current.object_id

      certificate_permissions = [
        "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers",
        "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers",
        "Purge", "Recover", "Restore", "SetIssuers", "Update"
      ]

      key_permissions = [
        "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get",
        "Import", "List", "Purge", "Recover", "Restore", "Sign",
        "UnwrapKey", "Update", "Verify", "WrapKey", "Release",
        "Rotate", "GetRotationPolicy", "SetRotationPolicy"
      ]

      secret_permissions = [
        "Backup", "Delete", "Get", "List", "Purge",
        "Recover", "Restore", "Set"
      ]
    }
  }

  tags = var.tags
}

# RBAC role assignments (if RBAC authorization is enabled)
resource "azurerm_role_assignment" "key_vault_administrator" {
  count                = var.enable_rbac_authorization ? 1 : 0
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name         = each.key
  value        = each.value.value
  key_vault_id = azurerm_key_vault.main.id
  content_type = each.value.content_type

  tags = merge(var.tags, each.value.tags)

  depends_on = [azurerm_role_assignment.key_vault_administrator]
}

# Certificates
resource "azurerm_key_vault_certificate" "certificates" {
  for_each = { for cert in var.certificates : cert.name => cert }

  name         = each.value.name
  key_vault_id = azurerm_key_vault.main.id

  dynamic "certificate" {
    for_each = each.value.certificate != null ? [each.value.certificate] : []
    content {
      contents = certificate.value.contents
      password = certificate.value.password
    }
  }

  dynamic "certificate_policy" {
    for_each = each.value.certificate_policy != null ? [each.value.certificate_policy] : []
    content {
      issuer_parameters {
        name = certificate_policy.value.issuer_parameters.name
      }

      key_properties {
        exportable = certificate_policy.value.key_properties.exportable
        key_size   = certificate_policy.value.key_properties.key_size
        key_type   = certificate_policy.value.key_properties.key_type
        reuse_key  = certificate_policy.value.key_properties.reuse_key
      }

      dynamic "lifetime_action" {
        for_each = certificate_policy.value.lifetime_action != null ? [certificate_policy.value.lifetime_action] : []
        content {
          action {
            action_type = lifetime_action.value.action.action_type
          }

          trigger {
            days_before_expiry  = lifetime_action.value.trigger.days_before_expiry
            lifetime_percentage = lifetime_action.value.trigger.lifetime_percentage
          }
        }
      }

      secret_properties {
        content_type = certificate_policy.value.secret_properties.content_type
      }

      x509_certificate_properties {
        extended_key_usage = certificate_policy.value.x509_certificate_properties.extended_key_usage
        key_usage          = certificate_policy.value.x509_certificate_properties.key_usage
        subject            = certificate_policy.value.x509_certificate_properties.subject
        validity_in_months = certificate_policy.value.x509_certificate_properties.validity_in_months

        dynamic "subject_alternative_names" {
          for_each = certificate_policy.value.x509_certificate_properties.subject_alternative_names != null ? [certificate_policy.value.x509_certificate_properties.subject_alternative_names] : []
          content {
            dns_names = subject_alternative_names.value.dns_names
            emails    = subject_alternative_names.value.emails
            upns      = subject_alternative_names.value.upns
          }
        }
      }
    }
  }

  tags = var.tags

  depends_on = [azurerm_role_assignment.key_vault_administrator]
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  count              = var.diagnostic_logs_enabled && var.log_analytics_workspace_id != "" ? 1 : 0
  name               = "${var.name}-diagnostics"
  target_resource_id = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Private endpoint for secure access (commented out as it requires VNet)
# resource "azurerm_private_endpoint" "main" {
#   name                = "${var.name}-pe"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   subnet_id           = var.private_endpoint_subnet_id
#
#   private_service_connection {
#     name                           = "${var.name}-psc"
#     private_connection_resource_id = azurerm_key_vault.main.id
#     subresource_names              = ["vault"]
#     is_manual_connection           = false
#   }
#
#   tags = var.tags
# }