# =============================================================================
# STORAGE MODULE - VARIABLES
# =============================================================================

variable "org_name" {
  description = "Organization name (e.g., dats)"
  type        = string
}

variable "platform_name" {
  description = "Platform name (e.g., beeux)"
  type        = string
}

variable "env_name" {
  description = "Environment name (e.g., dev, sit, uat, prd)"
  type        = string
}

variable "location" {
  description = "Azure region for the storage account"
  type        = string
  default     = "centralus"
}

variable "resource_group_name" {
  description = "Name of the resource group where storage resources will be created"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, 3-24 lowercase alphanumeric)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be either Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Storage account replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "LRS"
  
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "account_kind" {
  description = "Storage account kind (BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2)"
  type        = string
  default     = "StorageV2"
  
  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "Account kind must be one of: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2."
  }
}

variable "file_share_name" {
  description = "Name of the Azure Files share"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.file_share_name))
    error_message = "File share name must be 3-63 characters, start/end with letter or number, contain only lowercase letters, numbers, and hyphens."
  }
}

variable "file_share_quota_gb" {
  description = "File share quota in GB (max 102400 for Standard, 100 for Premium)"
  type        = number
  default     = 100
  
  validation {
    condition     = var.file_share_quota_gb >= 1 && var.file_share_quota_gb <= 102400
    error_message = "File share quota must be between 1 and 102400 GB."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs allowed to access the storage account"
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "List of IP addresses or CIDR blocks allowed to access the storage account (e.g., ['136.56.79.92', '136.56.79.0/24'])"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to storage resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# BLOB STORAGE (BLBS) VARIABLES
# =============================================================================

variable "blob_container_name" {
  description = "Name of the blob container for media files (BLBS component)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.blob_container_name))
    error_message = "Blob container name must be 3-63 characters, start/end with letter or number, contain only lowercase letters, numbers, and hyphens."
  }
}
