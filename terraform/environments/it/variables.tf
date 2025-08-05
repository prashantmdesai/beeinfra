# =============================================================================
# IT ENVIRONMENT VARIABLE DECLARATIONS
# =============================================================================
# This file declares all variables used by the IT environment,
# with values provided in terraform.tfvars
# =============================================================================

# All variables are declared in the parent directory variables.tf
# This file serves as a passthrough for environment-specific configuration

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment_name" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "use_free_tier" {
  description = "Use free tier services where possible"
  type        = bool
}

variable "use_managed_services" {
  description = "Use managed Azure services"
  type        = bool
}

variable "enable_security_features" {
  description = "Enable enhanced security features"
  type        = bool
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for compute services"
  type        = bool
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for services"
  type        = bool
}

variable "enable_waf" {
  description = "Enable Web Application Firewall"
  type        = bool
}

variable "enable_api_management" {
  description = "Enable Azure API Management"
  type        = bool
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
}

variable "idle_shutdown_hours" {
  description = "Hours of inactivity before auto-shutdown"
  type        = number
}

variable "database_type" {
  description = "Database type"
  type        = string
}

variable "postgresql_sku" {
  description = "PostgreSQL SKU name"
  type        = string
}

variable "postgresql_storage_mb" {
  description = "PostgreSQL storage size in MB"
  type        = number
}

variable "postgresql_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
}

variable "app_service_sku" {
  description = "App Service plan SKU"
  type        = string
}

variable "app_service_min_instances" {
  description = "Minimum number of App Service instances"
  type        = number
}

variable "app_service_max_instances" {
  description = "Maximum number of App Service instances"
  type        = number
}

variable "container_app_cpu" {
  description = "Container App CPU allocation"
  type        = string
}

variable "container_app_memory" {
  description = "Container App memory allocation"
  type        = string
}

variable "container_app_min_replicas" {
  description = "Minimum number of Container App replicas"
  type        = number
}

variable "container_app_max_replicas" {
  description = "Maximum number of Container App replicas"
  type        = number
}

variable "container_registry_sku" {
  description = "Container Registry SKU"
  type        = string
}

variable "api_management_sku" {
  description = "API Management SKU"
  type        = string
}

variable "developer_vm_size" {
  description = "Developer VM size"
  type        = string
}

variable "developer_vm_admin_username" {
  description = "Developer VM administrator username"
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
}

variable "alert_email_primary" {
  description = "Primary email for budget alerts"
  type        = string
}

variable "alert_email_secondary" {
  description = "Secondary email for budget alerts"
  type        = string
}

variable "alert_phone" {
  description = "Phone number for SMS alerts"
  type        = string
}

variable "blob_container_name" {
  description = "Name of the blob container for file storage"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}
