# =============================================================================
# IDENTITY MODULE OUTPUTS
# =============================================================================

output "user_assigned_identity_id" {
  description = "ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.main.id
}

output "user_assigned_identity_name" {
  description = "Name of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.main.name
}

output "user_assigned_principal_id" {
  description = "Principal ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "user_assigned_identity_client_id" {
  description = "Client ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "user_assigned_identity_tenant_id" {
  description = "Tenant ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.main.tenant_id
}
