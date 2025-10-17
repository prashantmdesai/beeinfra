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
# Note: k8s-join-token and logs directories are NOT managed by Terraform because
# they are written to by VMs and cause authentication failures during destroy.
# These directories will be created automatically by VMs when they mount the share.

resource "azurerm_storage_share_directory" "backups" {
  name             = "backups"
  storage_share_id = azurerm_storage_share.main.id
}

resource "azurerm_storage_share_directory" "app_data" {
  name             = "app-data"
  storage_share_id = azurerm_storage_share.main.id
}

# =============================================================================
# BLOB STORAGE (BLBS) - For Media Files
# =============================================================================
# Blob Container for media files used in the application
# Mounted via BlobFuse on all VMs for unified access

resource "azurerm_storage_container" "blbs" {
  name                  = var.blob_container_name
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"

  metadata = {
    environment = var.env_name
    purpose     = "Media files storage"
    component   = "BLBS"
  }
}

# Create placeholder directories in blob container using empty blobs
# This helps organize media files by type
resource "azurerm_storage_blob" "blbs_images_placeholder" {
  name                   = "images/.placeholder"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = azurerm_storage_container.blbs.name
  type                   = "Block"
  source_content         = "This directory stores image files"
}

resource "azurerm_storage_blob" "blbs_videos_placeholder" {
  name                   = "videos/.placeholder"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = azurerm_storage_container.blbs.name
  type                   = "Block"
  source_content         = "This directory stores video files"
}

resource "azurerm_storage_blob" "blbs_audio_placeholder" {
  name                   = "audio/.placeholder"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = azurerm_storage_container.blbs.name
  type                   = "Block"
  source_content         = "This directory stores audio files"
}

resource "azurerm_storage_blob" "blbs_documents_placeholder" {
  name                   = "documents/.placeholder"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = azurerm_storage_container.blbs.name
  type                   = "Block"
  source_content         = "This directory stores document files"
}
