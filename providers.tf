provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

  }

  # Use environment variables or Azure CLI authentication
  # subscription_id = var.subscription_id
  # tenant_id       = var.tenant_id
}

provider "azuread" {
  # Use environment variables or Azure CLI authentication
  # tenant_id = var.tenant_id
}

provider "random" {}

# Data sources for current configuration
data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}