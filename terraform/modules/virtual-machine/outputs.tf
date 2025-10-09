# =============================================================================
# VIRTUAL MACHINE MODULE - OUTPUTS
# =============================================================================

output "vm_id" {
  description = "The ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.id
}

output "vm_name" {
  description = "The name of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.name
}

output "private_ip" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "public_ip" {
  description = "The public IP address of the VM"
  value       = azurerm_public_ip.main.ip_address
}

output "public_ip_fqdn" {
  description = "The FQDN of the public IP (if configured)"
  value       = azurerm_public_ip.main.fqdn
}

output "nic_id" {
  description = "The ID of the network interface"
  value       = azurerm_network_interface.main.id
}

output "ssh_connection_string" {
  description = "SSH connection string to connect to the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
}

output "ssh_public_key" {
  description = "The SSH public key used for the VM"
  value       = var.ssh_public_key
}

output "vm_role" {
  description = "The role of the VM (master or worker)"
  value       = var.vm_role
}

output "vm_components" {
  description = "Components deployed on this VM"
  value       = var.vm_components
}

output "vm_zone" {
  description = "The availability zone of the VM"
  value       = var.vm_zone
}
