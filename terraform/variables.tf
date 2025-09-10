# =============================================================================
# TERRAFORM VARIABLES CONFIGURATION
# =============================================================================
# This file defines all input variables for the Terraform configuration,
# replacing the parameter definitions from the previous Bicep templates.
#
# MIGRATION FROM BICEP TO TERRAFORM:
# ==================================
# These variables provide the same configuration options as the previous
# Bicep parameters but with enhanced validation, type safety, and 
# documentation capabilities that Terraform offers.
# =============================================================================

# =============================================================================
# CORE CONFIGURATION VARIABLES
# =============================================================================

variable "project_name" {
  description = "Name of the project (used in resource naming)"
  type        = string
  default     = "beeux"
  
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters and numbers."
  }
}

variable "environment_name" {
  description = "Environment name (it, qa, prod)"
  type        = string
  
  validation {
    condition     = contains(["it", "qa", "prod"], var.environment_name)
    error_message = "Environment name must be one of: it, qa, prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US"
  
  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3",
      "Central US", "North Central US", "South Central US", "West Central US",
      "Canada Central", "Canada East", "Brazil South",
      "North Europe", "West Europe", "UK South", "UK West",
      "France Central", "Germany West Central", "Norway East",
      "Switzerland North", "Sweden Central",
      "Australia East", "Australia Southeast", "Australia Central",
      "Japan East", "Japan West", "Korea Central", "Korea South",
      "Southeast Asia", "East Asia", "Central India", "South India", "West India"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# FEATURE FLAGS AND SERVICE ENABLEMENT
# =============================================================================

variable "use_free_tier" {
  description = "Use free tier services where possible (for IT environment)"
  type        = bool
  default     = false
}

variable "use_managed_services" {
  description = "Use managed Azure services (for QA/Production environments)"
  type        = bool
  default     = true
}

variable "enable_security_features" {
  description = "Enable enhanced security features"
  type        = bool
  default     = true
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for compute services"
  type        = bool
  default     = false
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for services"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Enable Web Application Firewall"
  type        = bool
  default     = false
}

variable "enable_key_vault" {
  description = "Enable Azure Key Vault"
  type        = bool
  default     = true
}

variable "enable_api_management" {
  description = "Enable Azure API Management"
  type        = bool
  default     = true
}

variable "use_container_apps" {
  description = "Use Azure Container Apps for API backend"
  type        = bool
  default     = true
}

variable "use_app_service" {
  description = "Use Azure App Service for frontend"
  type        = bool
  default     = true
}

variable "auto_shutdown_enabled" {
  description = "Enable auto-shutdown for cost optimization"
  type        = bool
  default     = false
}

variable "idle_shutdown_hours" {
  description = "Hours of inactivity before auto-shutdown"
  type        = number
  default     = 1
  
  validation {
    condition     = var.idle_shutdown_hours >= 1 && var.idle_shutdown_hours <= 24
    error_message = "Idle shutdown hours must be between 1 and 24."
  }
}

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

variable "database_type" {
  description = "Database type (managed or self-hosted)"
  type        = string
  default     = "managed"
  
  validation {
    condition     = contains(["managed", "self-hosted"], var.database_type)
    error_message = "Database type must be either 'managed' or 'self-hosted'."
  }
}

variable "postgresql_sku" {
  description = "PostgreSQL SKU name"
  type        = string
  default     = "B_Standard_B1ms"
  
  validation {
    condition = contains([
      "B_Standard_B1ms", "B_Standard_B2s", "GP_Standard_D2s_v3", 
      "GP_Standard_D4s_v3", "GP_Standard_D8s_v3", "MO_Standard_E4s_v3"
    ], var.postgresql_sku)
    error_message = "PostgreSQL SKU must be a valid Azure Database for PostgreSQL SKU."
  }
}

variable "postgresql_storage_mb" {
  description = "PostgreSQL storage size in MB"
  type        = number
  default     = 32768
  
  validation {
    condition     = var.postgresql_storage_mb >= 32768 && var.postgresql_storage_mb <= 16777216
    error_message = "PostgreSQL storage must be between 32GB and 16TB."
  }
}

variable "postgresql_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
  default     = "postgres_admin"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{2,63}$", var.postgresql_admin_username))
    error_message = "PostgreSQL admin username must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "beeux_db"
}

# =============================================================================
# APP SERVICE CONFIGURATION
# =============================================================================

variable "app_service_sku" {
  description = "App Service plan SKU"
  type        = string
  default     = "B1"
  
  validation {
    condition = contains([
      "F1", "D1", "B1", "B2", "B3", "S1", "S2", "S3", 
      "P1V2", "P2V2", "P3V2", "P1V3", "P2V3", "P3V3"
    ], var.app_service_sku)
    error_message = "App Service SKU must be a valid Azure App Service plan SKU."
  }
}

variable "app_service_min_instances" {
  description = "Minimum number of App Service instances"
  type        = number
  default     = 1
  
  validation {
    condition     = var.app_service_min_instances >= 1 && var.app_service_min_instances <= 30
    error_message = "App Service minimum instances must be between 1 and 30."
  }
}

variable "app_service_max_instances" {
  description = "Maximum number of App Service instances"
  type        = number
  default     = 3
  
  validation {
    condition     = var.app_service_max_instances >= 1 && var.app_service_max_instances <= 30
    error_message = "App Service maximum instances must be between 1 and 30."
  }
}

# =============================================================================
# CONTAINER APPS CONFIGURATION
# =============================================================================

variable "container_app_cpu" {
  description = "Container App CPU allocation"
  type        = string
  default     = "0.5"
  
  validation {
    condition     = contains(["0.25", "0.5", "0.75", "1.0", "1.25", "1.5", "1.75", "2.0"], var.container_app_cpu)
    error_message = "Container App CPU must be a valid value (0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0)."
  }
}

variable "container_app_memory" {
  description = "Container App memory allocation"
  type        = string
  default     = "1Gi"
  
  validation {
    condition     = contains(["0.5Gi", "1Gi", "1.5Gi", "2Gi", "3Gi", "4Gi"], var.container_app_memory)
    error_message = "Container App memory must be a valid value (0.5Gi, 1Gi, 1.5Gi, 2Gi, 3Gi, 4Gi)."
  }
}

variable "container_app_min_replicas" {
  description = "Minimum number of Container App replicas"
  type        = number
  default     = 1
  
  validation {
    condition     = var.container_app_min_replicas >= 0 && var.container_app_min_replicas <= 25
    error_message = "Container App minimum replicas must be between 0 and 25."
  }
}

variable "container_app_max_replicas" {
  description = "Maximum number of Container App replicas"
  type        = number
  default     = 10
  
  validation {
    condition     = var.container_app_max_replicas >= 1 && var.container_app_max_replicas <= 25
    error_message = "Container App maximum replicas must be between 1 and 25."
  }
}

# =============================================================================
# CONTAINER REGISTRY CONFIGURATION
# =============================================================================

variable "container_registry_sku" {
  description = "Container Registry SKU"
  type        = string
  default     = "Basic"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.container_registry_sku)
    error_message = "Container Registry SKU must be Basic, Standard, or Premium."
  }
}

# =============================================================================
# API MANAGEMENT CONFIGURATION
# =============================================================================

variable "api_management_sku" {
  description = "API Management SKU"
  type        = string
  default     = "Developer"
  
  validation {
    condition     = contains(["Developer", "Standard", "Premium"], var.api_management_sku)
    error_message = "API Management SKU must be Developer, Standard, or Premium."
  }
}

# =============================================================================
# DEVELOPER VM CONFIGURATION
# =============================================================================

variable "developer_vm_size" {
  description = "Developer VM size"
  type        = string
  default     = "Standard_B1s"
  
  validation {
    condition = contains([
      "Standard_B1s", "Standard_B1ms", "Standard_B2s", "Standard_B2ms",
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3"
    ], var.developer_vm_size)
    error_message = "Developer VM size must be a valid Azure VM size."
  }
}

variable "developer_vm_admin_username" {
  description = "Developer VM administrator username"
  type        = string
  default     = "azureuser"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{2,63}$", var.developer_vm_admin_username))
    error_message = "Developer VM admin username must start with a letter and contain only letters, numbers, and underscores."
  }
}

# =============================================================================
# COST MANAGEMENT AND ALERTING
# =============================================================================

variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 10
  
  validation {
    condition     = var.budget_amount >= 1 && var.budget_amount <= 10000
    error_message = "Budget amount must be between $1 and $10,000."
  }
}

variable "alert_email_primary" {
  description = "Primary email for budget alerts"
  type        = string
  default     = "prashantmdesai@yahoo.com"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email_primary))
    error_message = "Primary alert email must be a valid email address."
  }
}

variable "alert_email_secondary" {
  description = "Secondary email for budget alerts"
  type        = string
  default     = "prashantmdesai@hotmail.com"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email_secondary))
    error_message = "Secondary alert email must be a valid email address."
  }
}

variable "alert_phone" {
  description = "Phone number for SMS alerts"
  type        = string
  default     = "+12246564855"
  
  validation {
    condition     = can(regex("^\\+[1-9]\\d{1,14}$", var.alert_phone))
    error_message = "Phone number must be in international format (e.g., +12246564855)."
  }
}

# =============================================================================
# STORAGE CONFIGURATION
# =============================================================================

variable "blob_container_name" {
  description = "Name of the blob container for file storage"
  type        = string
  default     = "audio-files"
}

# =============================================================================
# APPLICATION CONFIGURATION
# =============================================================================

variable "app_name" {
  description = "Application name for Azure Developer CLI"
  type        = string
  default     = "beeux"
}
