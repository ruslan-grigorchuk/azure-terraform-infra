resource "random_password" "sql_password" {
  length  = 32
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "azurerm_mssql_server" "main" {
  name                = "${var.name}-sqlserver"
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = "12.0"

  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password != "" ? var.administrator_login_password : random_password.sql_password.result

  minimum_tls_version = "1.2"

  azuread_administrator {
    login_username = data.azuread_client_config.current.display_name
    object_id      = data.azuread_client_config.current.object_id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_mssql_database" "main" {
  name           = "${var.name}-db"
  server_id      = azurerm_mssql_server.main.id
  collation      = var.collation
  max_size_gb    = var.max_size_gb
  sku_name       = var.sku_name
  zone_redundant = false

  # Backup settings
  short_term_retention_policy {
    retention_days = var.backup_retention_days
  }

  long_term_retention_policy {
    weekly_retention  = "P1W"
    monthly_retention = "P1M"
    yearly_retention  = "P1Y"
    week_of_year      = 1
  }

  tags = var.tags
}

# Firewall rules
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "allowed_ips" {
  for_each = { for idx, ip_range in var.allowed_ip_ranges : idx => ip_range }

  name             = "AllowedIP-${each.key}"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = split("/", each.value)[0]
  end_ip_address   = split("/", each.value)[0]
}

# Security configurations
resource "azurerm_mssql_server_security_alert_policy" "main" {
  count                      = var.enable_threat_detection ? 1 : 0
  resource_group_name        = var.resource_group_name
  server_name                = azurerm_mssql_server.main.name
  state                      = "Enabled"
  storage_endpoint           = azurerm_storage_account.security_logs[0].primary_blob_endpoint
  storage_account_access_key = azurerm_storage_account.security_logs[0].primary_access_key
  email_addresses            = []
  retention_days             = 20

  disabled_alerts = []
}

resource "azurerm_mssql_server_vulnerability_assessment" "main" {
  count                           = var.enable_threat_detection ? 1 : 0
  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.main[0].id
  storage_container_path          = "${azurerm_storage_account.security_logs[0].primary_blob_endpoint}${azurerm_storage_container.security_logs[0].name}/"
  storage_account_access_key      = azurerm_storage_account.security_logs[0].primary_access_key

  recurring_scans {
    enabled                   = true
    email_subscription_admins = false
    emails                    = []
  }
}

# Storage account for security logs
resource "azurerm_storage_account" "security_logs" {
  count                    = var.enable_threat_detection ? 1 : 0
  name                     = "${replace(var.name, "-", "")}sqlseclogs${random_integer.suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

resource "azurerm_storage_container" "security_logs" {
  count                 = var.enable_threat_detection ? 1 : 0
  name                  = "sql-security-logs"
  storage_account_name  = azurerm_storage_account.security_logs[0].name
  container_access_type = "private"
}

# Store database credentials in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "${var.name}-sql-admin-password"
  value        = var.administrator_login_password != "" ? var.administrator_login_password : random_password.sql_password.result
  key_vault_id = var.key_vault_id

  tags = var.tags

  depends_on = [azurerm_mssql_server.main]
}

resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "${var.name}-sql-connection-string"
  value        = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${var.administrator_login};Password=${var.administrator_login_password != "" ? var.administrator_login_password : random_password.sql_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = var.key_vault_id

  tags = var.tags

  depends_on = [azurerm_mssql_server.main, azurerm_mssql_database.main]
}

resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

data "azuread_client_config" "current" {}