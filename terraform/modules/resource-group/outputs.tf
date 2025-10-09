# =============================================================================
# RESOURCE GROUP MODULE - OUTPUTS
# =============================================================================

output "rg_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "rg_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "rg_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "rg_tags" {
  description = "The tags applied to the resource group"
  value       = azurerm_resource_group.main.tags
}
