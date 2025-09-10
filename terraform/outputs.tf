# =============================================================================
# TERRAFORM OUTPUTS CONFIGURATION
# =============================================================================
# This file defines all output values from the Terraform deployment,
# replacing the output definitions from the previous Bicep templates.
#
# MIGRATION FROM BICEP TO TERRAFORM:
# ==================================
# These outputs provide the same information as the previous Bicep outputs
# but with enhanced formatting and conditional logic that Terraform offers.
# =============================================================================

# =============================================================================
# CORE INFRASTRUCTURE OUTPUTS
# =============================================================================

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.main.id
}

output "location" {
  description = "Azure region where resources are deployed"
  value       = azurerm_resource_group.main.location
}

output "environment_name" {
  description = "Environment name (it, qa, prod)"
  value       = var.environment_name
}

# =============================================================================
# IDENTITY AND SECURITY OUTPUTS
# =============================================================================

output "user_assigned_identity_id" {
  description = "ID of the user-assigned managed identity"
  value       = module.identity.user_assigned_identity_id
}

output "user_assigned_identity_principal_id" {
  description = "Principal ID of the user-assigned managed identity"
  value       = module.identity.user_assigned_principal_id
}

output "user_assigned_identity_client_id" {
  description = "Client ID of the user-assigned managed identity"
  value       = module.identity.user_assigned_identity_client_id
}

output "key_vault_id" {
  description = "ID of the Azure Key Vault"
  value       = module.keyvault.key_vault_id
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = module.keyvault.key_vault_uri
}

# =============================================================================
# NETWORKING OUTPUTS
# =============================================================================

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = module.networking.virtual_network_id
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = module.networking.virtual_network_name
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = var.enable_waf ? module.networking.application_gateway_public_ip : null
}

output "application_gateway_fqdn" {
  description = "FQDN of the Application Gateway"
  value       = var.enable_waf ? module.networking.application_gateway_fqdn : null
}

# =============================================================================
# DATABASE OUTPUTS
# =============================================================================

output "postgresql_server_name" {
  description = "Name of the PostgreSQL server"
  value       = module.postgresql.postgresql_server_name
}

output "postgresql_server_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = module.postgresql.postgresql_server_fqdn
}

output "postgresql_database_name" {
  description = "Name of the PostgreSQL database"
  value       = module.postgresql.postgresql_database_name
}

output "postgresql_connection_string" {
  description = "PostgreSQL connection string (stored in Key Vault)"
  value       = module.postgresql.connection_string
  sensitive   = true
}

# =============================================================================
# STORAGE OUTPUTS
# =============================================================================

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = module.storage.storage_account_id
}

output "storage_primary_endpoint" {
  description = "Primary endpoint of the storage account"
  value       = module.storage.storage_primary_endpoint
}

output "storage_primary_connection_string" {
  description = "Primary connection string for the storage account"
  value       = module.storage.primary_connection_string
  sensitive   = true
}

# =============================================================================
# CONTAINER REGISTRY OUTPUTS
# =============================================================================

output "container_registry_name" {
  description = "Name of the container registry"
  value       = module.container_registry.container_registry_name
}

output "container_registry_id" {
  description = "ID of the container registry"
  value       = module.container_registry.container_registry_id
}

output "container_registry_server" {
  description = "Server URL of the container registry"
  value       = module.container_registry.container_registry_server
}

output "container_registry_admin_username" {
  description = "Admin username for the container registry"
  value       = module.container_registry.container_registry_admin_username
  sensitive   = true
}

# =============================================================================
# APP SERVICE OUTPUTS (FRONTEND)
# =============================================================================

output "app_service_name" {
  description = "Name of the App Service (frontend)"
  value       = var.use_app_service ? module.app_service[0].app_service_name : null
}

output "app_service_id" {
  description = "ID of the App Service (frontend)"
  value       = var.use_app_service ? module.app_service[0].app_service_id : null
}

output "app_service_default_hostname" {
  description = "Default hostname of the App Service"
  value       = var.use_app_service ? module.app_service[0].app_service_default_hostname : null
}

output "app_service_url" {
  description = "HTTPS URL of the App Service (frontend)"
  value       = var.use_app_service ? "https://${module.app_service[0].app_service_default_hostname}" : null
}

# =============================================================================
# CONTAINER APPS OUTPUTS (API BACKEND)
# =============================================================================

output "container_app_name" {
  description = "Name of the Container App (API backend)"
  value       = var.use_container_apps ? module.container_apps[0].container_app_name : null
}

output "container_app_id" {
  description = "ID of the Container App (API backend)"
  value       = var.use_container_apps ? module.container_apps[0].container_app_id : null
}

output "container_app_fqdn" {
  description = "FQDN of the Container App"
  value       = var.use_container_apps ? module.container_apps[0].container_app_fqdn : null
}

output "container_app_url" {
  description = "HTTPS URL of the Container App (API backend)"
  value       = var.use_container_apps ? "https://${module.container_apps[0].container_app_fqdn}" : null
}

output "container_apps_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = var.use_container_apps ? module.container_apps_environment[0].container_apps_environment_id : null
}

# =============================================================================
# API MANAGEMENT OUTPUTS
# =============================================================================

output "api_management_name" {
  description = "Name of the API Management service"
  value       = var.enable_api_management ? module.api_management[0].api_management_name : null
}

output "api_management_id" {
  description = "ID of the API Management service"
  value       = var.enable_api_management ? module.api_management[0].api_management_id : null
}

output "api_management_gateway_url" {
  description = "Gateway URL of the API Management service"
  value       = var.enable_api_management ? module.api_management[0].api_management_gateway_url : null
}

output "api_management_portal_url" {
  description = "Portal URL of the API Management service"
  value       = var.enable_api_management ? module.api_management[0].api_management_portal_url : null
}

output "api_management_subscription_key" {
  description = "Subscription key for API Management"
  value       = var.enable_api_management ? module.api_management[0].api_management_subscription_key : null
  sensitive   = true
}

# =============================================================================
# DEVELOPER VM OUTPUTS
# =============================================================================

output "developer_vm_name" {
  description = "Name of the developer VM"
  value       = module.developer_vm.developer_vm_name
}

output "developer_vm_id" {
  description = "ID of the developer VM"
  value       = module.developer_vm.developer_vm_id
}

output "developer_vm_public_ip" {
  description = "Public IP address of the developer VM"
  value       = module.developer_vm.developer_vm_public_ip
}

output "developer_vm_fqdn" {
  description = "FQDN of the developer VM"
  value       = module.developer_vm.developer_vm_fqdn
}

output "developer_vm_ssh_command" {
  description = "SSH command to connect to the developer VM"
  value       = module.developer_vm.developer_vm_ssh_command
}

output "developer_vm_computer_name" {
  description = "Computer name of the developer VM"
  value       = module.developer_vm.developer_vm_computer_name
}

# =============================================================================
# MONITORING OUTPUTS
# =============================================================================

output "application_insights_id" {
  description = "ID of Application Insights"
  value       = module.monitoring.application_insights_id
}

output "application_insights_name" {
  description = "Name of Application Insights"
  value       = module.monitoring.application_insights_name
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = module.monitoring.application_insights_instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_name
}

# =============================================================================
# COST MANAGEMENT OUTPUTS
# =============================================================================

output "budget_name" {
  description = "Name of the budget alert"
  value       = module.budget_alerts.budget_name
}

output "budget_id" {
  description = "ID of the budget alert"
  value       = module.budget_alerts.budget_id
}

output "budget_amount" {
  description = "Budget amount in USD"
  value       = var.budget_amount
}

# =============================================================================
# CONSOLIDATED APPLICATION URLS
# =============================================================================

output "frontend_url" {
  description = "URL of the frontend application"
  value = var.use_app_service ? "https://${module.app_service[0].app_service_default_hostname}" : (
    var.enable_waf ? "https://${module.networking.application_gateway_fqdn}" : null
  )
}

output "api_url" {
  description = "URL of the API backend"
  value = var.enable_api_management ? module.api_management[0].api_management_gateway_url : (
    var.use_container_apps ? "https://${module.container_apps[0].container_app_fqdn}" : null
  )
}

# =============================================================================
# DEPLOYMENT SUMMARY
# =============================================================================

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment              = var.environment_name
    resource_group          = azurerm_resource_group.main.name
    location               = azurerm_resource_group.main.location
    frontend_service       = var.use_app_service ? "App Service" : "None"
    api_service           = var.use_container_apps ? "Container Apps" : "None"
    database_type         = var.database_type
    api_management        = var.enable_api_management ? "Enabled" : "Disabled"
    private_endpoints     = var.enable_private_endpoints ? "Enabled" : "Disabled"
    web_application_firewall = var.enable_waf ? "Enabled" : "Disabled"
    auto_scaling         = var.enable_auto_scaling ? "Enabled" : "Disabled"
    budget_amount        = "$${var.budget_amount}"
    created_by           = "Terraform"
    migrated_from        = "Bicep"
  }
}
