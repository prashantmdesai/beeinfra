# =============================================================================
# MAIN TERRAFORM CONFIGURATION FOR BEEINFRA PROJECT
# =============================================================================
# This file replaces the previous main.bicep and serves as the central 
# orchestration point for deploying Azure infrastructure using Terraform
# instead of Azure Bicep templates.
#
# MIGRATION FROM BICEP TO TERRAFORM:
# ==================================
# This Terraform configuration provides the same functionality as the previous
# Bicep templates but with enhanced:
# - State management and drift detection
# - Better module composition and reusability  
# - Cross-cloud compatibility for future expansion
# - Enhanced dependency management
# - Better variable validation and type safety
#
# REQUIREMENTS COMPLIANCE:
# =======================
# This configuration implements all requirements from infrasetup.instructions.md:
# - Requirement 1-3: Multi-environment deployment (IT, QA, Production)
# - Requirement 4-11: Cost management and budget alerts
# - Requirement 12-16: Security implementation per environment
# - Requirement 17-23: HTTPS enforcement and Key Vault integration
# - Requirement 24-28: Developer VMs and comprehensive documentation
# =============================================================================

# Data sources for current Azure context
data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

# Generate unique resource names using Azure CAF naming convention
resource "azurecaf_name" "resource_group" {
  name          = var.project_name
  resource_type = "azurerm_resource_group"
  prefixes      = [var.environment_name]
  suffixes      = [var.location]
  random_length = 0
  clean_input   = true
}

resource "azurecaf_name" "storage_account" {
  name          = var.project_name
  resource_type = "azurerm_storage_account"
  prefixes      = [var.environment_name]
  suffixes      = [var.location]
  random_length = 4
  clean_input   = true
}

# Create resource group for the environment
resource "azurerm_resource_group" "main" {
  name     = azurecaf_name.resource_group.result
  location = var.location
  
  tags = merge(var.common_tags, {
    "azd-env-name" = var.environment_name
    "Environment"  = var.environment_name
    "Project"      = var.project_name
    "CreatedBy"    = "Terraform"
    "MigratedFrom" = "Bicep"
  })
  
  lifecycle {
    ignore_changes = [tags["CreatedBy"], tags["MigratedFrom"]]
  }
}

# User-assigned managed identity for all services
module "identity" {
  source = "./modules/identity"
  
  name                = "${var.project_name}-identity-${var.environment_name}"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = var.common_tags
}

# Virtual Network and Networking
module "networking" {
  source = "./modules/networking"
  
  name                = "${var.project_name}-network-${var.environment_name}"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  environment_name   = var.environment_name
  
  enable_private_endpoints = var.enable_private_endpoints
  enable_waf              = var.enable_waf
  
  tags = var.common_tags
}

# Azure Key Vault for secrets management
module "keyvault" {
  source = "./modules/keyvault"
  
  name                = "${var.project_name}-kv-${var.environment_name}"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  environment_name   = var.environment_name
  
  tenant_id                    = data.azurerm_client_config.current.tenant_id
  user_assigned_identity_id    = module.identity.user_assigned_identity_id
  user_assigned_principal_id   = module.identity.user_assigned_principal_id
  enable_private_endpoints     = var.enable_private_endpoints
  private_endpoint_subnet_id   = module.networking.private_endpoint_subnet_id
  
  tags = var.common_tags
  
  depends_on = [module.identity, module.networking]
}

# Storage Account for application data
module "storage" {
  source = "./modules/storage"
  
  name                = azurecaf_name.storage_account.result
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  environment_name   = var.environment_name
  
  user_assigned_identity_id    = module.identity.user_assigned_identity_id
  user_assigned_principal_id   = module.identity.user_assigned_principal_id
  enable_private_endpoints     = var.enable_private_endpoints
  private_endpoint_subnet_id   = module.networking.private_endpoint_subnet_id
  
  tags = var.common_tags
  
  depends_on = [module.identity, module.networking]
}

# Container Registry for application images
module "container_registry" {
  source = "./modules/container_registry"
  
  name                = "${var.project_name}cr${var.environment_name}"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  environment_name   = var.environment_name
  
  sku                          = var.container_registry_sku
  user_assigned_identity_id    = module.identity.user_assigned_identity_id
  user_assigned_principal_id   = module.identity.user_assigned_principal_id
  enable_private_endpoints     = var.enable_private_endpoints
  private_endpoint_subnet_id   = module.networking.private_endpoint_subnet_id
  
  tags = var.common_tags
  
  depends_on = [module.identity, module.networking]
}

# PostgreSQL Database
module "postgresql" {
  source = "./modules/postgresql"
  
  name                = "${var.project_name}-postgres-${var.environment_name}"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  environment_name   = var.environment_name
  
  database_type                = var.database_type
  sku_name                     = var.postgresql_sku
  storage_mb                   = var.postgresql_storage_mb
  administrator_login          = var.postgresql_admin_username
  user_assigned_identity_id    = module.identity.user_assigned_identity_id
  key_vault_id                 = module.keyvault.key_vault_id
  enable_private_endpoints     = var.enable_private_endpoints
  private_endpoint_subnet_id   = module.networking.private_endpoint_subnet_id
  
  tags = var.common_tags
  
  depends_on = [module.identity, module.keyvault, module.networking]
}

# Application Insights for monitoring
module "monitoring" {
  source = "./modules/monitoring"
  
  name                = "${var.project_name}-insights-${var.environment_name}"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  environment_name   = var.environment_name
  
  tags = var.common_tags
}

# Container Apps Environment
module "container_apps_environment" {
  count  = var.use_container_apps ? 1 : 0
  source = "./modules/container_apps_environment"
  
  name                = "${var.project_name}-containerenv-${var.environment_name}"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  environment_name   = var.environment_name
  
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  application_insights_key   = module.monitoring.application_insights_instrumentation_key
  
  tags = var.common_tags
  
  depends_on = [module.monitoring]
}

# Container Apps for API backend
module "container_apps" {
  count  = var.use_container_apps ? 1 : 0
  source = "./modules/container_apps"
  
  name                     = "${var.project_name}-api-${var.environment_name}"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  environment_name        = var.environment_name
  
  container_apps_environment_id = module.container_apps_environment[0].container_apps_environment_id
  container_registry_server     = module.container_registry.container_registry_server
  user_assigned_identity_id     = module.identity.user_assigned_identity_id
  
  # Environment-specific configuration
  cpu_limit               = var.container_app_cpu
  memory_limit           = var.container_app_memory
  min_replicas           = var.container_app_min_replicas
  max_replicas           = var.container_app_max_replicas
  enable_auto_scaling    = var.enable_auto_scaling
  
  # Application configuration
  postgresql_connection_string = module.postgresql.connection_string
  storage_connection_string    = module.storage.primary_connection_string
  application_insights_key     = module.monitoring.application_insights_instrumentation_key
  
  tags = var.common_tags
  
  depends_on = [
    module.container_apps_environment,
    module.container_registry,
    module.postgresql,
    module.storage,
    module.monitoring
  ]
}

# App Service for frontend
module "app_service" {
  count  = var.use_app_service ? 1 : 0
  source = "./modules/app_service"
  
  name                = "${var.project_name}-frontend-${var.environment_name}"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  environment_name   = var.environment_name
  
  sku_name                     = var.app_service_sku
  user_assigned_identity_id    = module.identity.user_assigned_identity_id
  enable_auto_scaling         = var.enable_auto_scaling
  min_instances               = var.app_service_min_instances
  max_instances               = var.app_service_max_instances
  
  # Application configuration
  api_base_url                = var.use_container_apps ? module.container_apps[0].container_app_fqdn : ""
  application_insights_key    = module.monitoring.application_insights_instrumentation_key
  
  tags = var.common_tags
  
  depends_on = [
    module.identity,
    module.monitoring,
    module.container_apps
  ]
}

# API Management for API Gateway
module "api_management" {
  count  = var.enable_api_management ? 1 : 0
  source = "./modules/api_management"
  
  name                = "${var.project_name}-apim-${var.environment_name}"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  environment_name   = var.environment_name
  
  sku                          = var.api_management_sku
  user_assigned_identity_id    = module.identity.user_assigned_identity_id
  application_insights_id      = module.monitoring.application_insights_id
  enable_private_endpoints     = var.enable_private_endpoints
  
  # Backend configuration
  container_app_fqdn = var.use_container_apps ? module.container_apps[0].container_app_fqdn : ""
  web_app_hostname   = var.use_app_service ? module.app_service[0].app_service_default_hostname : ""
  
  tags = var.common_tags
  
  depends_on = [
    module.identity,
    module.monitoring,
    module.container_apps,
    module.app_service
  ]
}

# Developer VM for environment access
module "developer_vm" {
  source = "./modules/developer_vm"
  
  name                = "${var.project_name}-devvm-${var.environment_name}"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  environment_name   = var.environment_name
  
  vm_size                    = var.developer_vm_size
  admin_username            = var.developer_vm_admin_username
  subnet_id                 = module.networking.developer_vm_subnet_id
  user_assigned_identity_id = module.identity.user_assigned_identity_id
  key_vault_id              = module.keyvault.key_vault_id
  
  tags = var.common_tags
  
  depends_on = [
    module.identity,
    module.keyvault,
    module.networking
  ]
}

# Budget alerts for cost management
module "budget_alerts" {
  source = "./modules/budget_alerts"
  
  resource_group_name = azurerm_resource_group.main.name
  environment_name   = var.environment_name
  subscription_id    = data.azurerm_subscription.current.subscription_id
  
  budget_amount           = var.budget_amount
  alert_email_primary     = var.alert_email_primary
  alert_email_secondary   = var.alert_email_secondary
  alert_phone            = var.alert_phone
  
  tags = var.common_tags
  
  depends_on = [azurerm_resource_group.main]
}
