# =============================================================================
# STORAGE MODULE
# =============================================================================
# Creates Azure Storage Account and File Share for the BeEux Word Learning Platform
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind

  # Security settings
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  # Network rules - allow access from subnet and laptop/WiFi
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = var.subnet_ids
    ip_rules                   = var.allowed_ip_ranges
  }

  tags = merge(
    var.tags,
    {
      Environment  = var.env_name
      Organization = var.org_name
      Platform     = var.platform_name
      ManagedBy    = "Terraform"
      Purpose      = "Shared storage for Kubernetes cluster"
    }
  )
}

# File Share
resource "azurerm_storage_share" "main" {
  name                 = var.file_share_name
  storage_account_name = azurerm_storage_account.main.name
  quota                = var.file_share_quota_gb

  metadata = {
    environment = var.env_name
    purpose     = "Kubernetes shared storage"
  }
}

# Create directories in the file share for organized storage
resource "azurerm_storage_share_directory" "k8s_join_token" {
  name             = "k8s-join-token"
  storage_share_id = azurerm_storage_share.main.id
}

resource "azurerm_storage_share_directory" "logs" {
  name             = "logs"
  storage_share_id = azurerm_storage_share.main.id
}

resource "azurerm_storage_share_directory" "backups" {
  name             = "backups"
  storage_share_id = azurerm_storage_share.main.id
}

resource "azurerm_storage_share_directory" "app_data" {
  name             = "app-data"
  storage_share_id = azurerm_storage_share.main.id
}
