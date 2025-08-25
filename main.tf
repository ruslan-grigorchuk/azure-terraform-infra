# Random suffix for globally unique resources
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location

  tags = local.common_tags
}

# Key Vault (created first as other modules depend on it)
module "key_vault" {
  source = "./modules/key_vault"

  name                = "${local.name_prefix}-kv-${local.random_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  allowed_ip_ranges = var.allowed_ip_ranges
  
  tags = local.common_tags
}

# Application Insights
module "application_insights" {
  source = "./modules/application_insights"

  name                = "${local.name_prefix}-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  application_type = "web"
  
  availability_tests = [
    {
      name = "${local.name_prefix}-availability-test"
      url  = "https://${module.app_service.app_service_hostname}"
    }
  ]

  tags = local.common_tags
}

# App Service
module "app_service" {
  source = "./modules/app_service"

  name                = "${local.name_prefix}-app"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  sku_name        = var.app_service_sku
  custom_domain   = var.custom_domain
  allowed_ip_ranges = var.allowed_ip_ranges
  key_vault_id    = module.key_vault.key_vault_id
  application_insights_instrumentation_key = module.application_insights.instrumentation_key

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
    "ENVIRONMENT"                  = upper(var.environment)
    "PROJECT_NAME"                 = var.project_name
  }

  connection_strings = {
    "DefaultConnection" = {
      name  = "DefaultConnection"
      type  = "SQLAzure"
      value = module.sql_database.connection_string
    }
  }

  tags = local.common_tags

  depends_on = [module.key_vault]
}

# SQL Database
module "sql_database" {
  source = "./modules/sql_database"

  name                = "${local.name_prefix}-sql"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  administrator_login    = var.sql_admin_username
  sku_name              = var.sql_sku_name
  max_size_gb           = var.sql_max_size_gb
  allowed_ip_ranges     = var.allowed_ip_ranges
  key_vault_id          = module.key_vault.key_vault_id
  enable_threat_detection = var.environment == "prod"

  tags = local.common_tags

  depends_on = [module.key_vault]
}

# Storage Account
module "storage_account" {
  source = "./modules/storage_account"

  name                = "${replace(local.name_prefix, "-", "")}st${local.random_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  allowed_ip_ranges       = var.allowed_ip_ranges
  key_vault_id           = module.key_vault.key_vault_id

  containers = [
    {
      name        = "uploads"
      access_type = "private"
    },
    {
      name        = "public"
      access_type = "blob"
    },
    {
      name        = "backups"
      access_type = "private"
    }
  ]

  queues = ["notifications", "processing"]
  tables = ["logs", "metrics"]

  tags = local.common_tags

  depends_on = [module.key_vault]
}

# Service Bus (optional)
module "service_bus" {
  count  = var.enable_service_bus ? 1 : 0
  source = "./modules/service_bus"

  name                = "${local.name_prefix}-sb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  sku         = var.service_bus_sku
  key_vault_id = module.key_vault.key_vault_id

  queues = [
    {
      name                                    = "orders"
      max_size_in_megabytes                  = 1024
      requires_duplicate_detection           = true
      dead_lettering_on_message_expiration   = true
    },
    {
      name                                    = "notifications"
      max_size_in_megabytes                  = 1024
      requires_session                       = false
      dead_lettering_on_message_expiration   = true
    }
  ]

  topics = [
    {
      name                         = "events"
      max_size_in_megabytes        = 1024
      requires_duplicate_detection = true
    }
  ]

  subscriptions = [
    {
      name                                 = "audit-subscription"
      topic_name                          = "events"
      dead_lettering_on_message_expiration = true
    },
    {
      name                                 = "analytics-subscription"  
      topic_name                          = "events"
      dead_lettering_on_message_expiration = true
    }
  ]

  network_rule_set = {
    default_action = var.environment == "prod" ? "Deny" : "Allow"
    ip_rules       = var.allowed_ip_ranges
  }

  tags = local.common_tags

  depends_on = [module.key_vault]
}

# Optional: AKS Cluster (uncomment if needed)
# module "aks" {
#   source = "./modules/aks"
# 
#   name                = "${local.name_prefix}-aks"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   
#   kubernetes_version = "1.28.0"
#   
#   default_node_pool = {
#     name                = "default"
#     vm_size             = "Standard_D2s_v3"
#     node_count          = 3
#     enable_auto_scaling = true
#     min_count           = 1
#     max_count           = 10
#     availability_zones  = ["1", "2", "3"]
#   }
# 
#   additional_node_pools = {
#     "workload" = {
#       vm_size             = "Standard_D4s_v3"
#       node_count          = 2
#       enable_auto_scaling = true
#       min_count           = 1
#       max_count           = 5
#       node_labels = {
#         "workload-type" = "application"
#       }
#     }
#   }
# 
#   oms_agent_enabled = true
#   log_analytics_workspace_id = module.application_insights.workspace_id
# 
#   tags = local.common_tags
# }