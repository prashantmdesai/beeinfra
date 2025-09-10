# =============================================================================
# IT ENVIRONMENT MAIN CONFIGURATION
# =============================================================================
# This file serves as the entry point for deploying the IT environment
# using Terraform modules, replacing the previous Bicep deployment approach.
# =============================================================================

# Configure Terraform to use the parent directory modules
terraform {
  required_version = ">= 1.5.0"
}

# Reference the main configuration from parent directory
module "it_environment" {
  source = "../../"
  
  # Pass all variables from terraform.tfvars
  project_name    = var.project_name
  environment_name = var.environment_name
  location        = var.location
  common_tags     = var.common_tags
  
  # Feature flags
  use_free_tier             = var.use_free_tier
  use_managed_services      = var.use_managed_services
  enable_security_features  = var.enable_security_features
  enable_auto_scaling      = var.enable_auto_scaling
  enable_private_endpoints = var.enable_private_endpoints
  enable_waf              = var.enable_waf
  enable_api_management   = var.enable_api_management
  use_container_apps      = var.use_container_apps
  use_app_service         = var.use_app_service
  auto_shutdown_enabled   = var.auto_shutdown_enabled
  idle_shutdown_hours     = var.idle_shutdown_hours
  
  # Database configuration
  database_type            = var.database_type
  postgresql_sku          = var.postgresql_sku
  postgresql_storage_mb   = var.postgresql_storage_mb
  postgresql_admin_username = var.postgresql_admin_username
  database_name           = var.database_name
  
  # App Service configuration
  app_service_sku          = var.app_service_sku
  app_service_min_instances = var.app_service_min_instances
  app_service_max_instances = var.app_service_max_instances
  
  # Container Apps configuration
  container_app_cpu         = var.container_app_cpu
  container_app_memory      = var.container_app_memory
  container_app_min_replicas = var.container_app_min_replicas
  container_app_max_replicas = var.container_app_max_replicas
  
  # Container Registry configuration
  container_registry_sku = var.container_registry_sku
  
  # API Management configuration
  api_management_sku = var.api_management_sku
  
  # Developer VM configuration
  developer_vm_size         = var.developer_vm_size
  developer_vm_admin_username = var.developer_vm_admin_username
  
  # Cost management
  budget_amount          = var.budget_amount
  alert_email_primary    = var.alert_email_primary
  alert_email_secondary  = var.alert_email_secondary
  alert_phone           = var.alert_phone
  
  # Storage configuration
  blob_container_name = var.blob_container_name
  
  # Application configuration
  app_name = var.app_name
}
