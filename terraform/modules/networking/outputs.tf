# =============================================================================
# NETWORKING MODULE - OUTPUTS
# =============================================================================

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "The address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = azurerm_subnet.main.id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = azurerm_subnet.main.name
}

output "subnet_address_prefix" {
  description = "The address prefix of the subnet"
  value       = azurerm_subnet.main.address_prefixes
}

output "nsg_id" {
  description = "The ID of the network security group"
  value       = azurerm_network_security_group.main.id
}

output "nsg_name" {
  description = "The name of the network security group"
  value       = azurerm_network_security_group.main.name
}
