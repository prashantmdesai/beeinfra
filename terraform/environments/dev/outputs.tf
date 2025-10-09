# =============================================================================
# OUTPUTS - DEV ENVIRONMENT
# =============================================================================

# -----------------------------------------------------------------------------
# RESOURCE GROUP OUTPUTS
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.rg_name
}

output "resource_group_id" {
  description = "Resource group ID"
  value       = module.resource_group.rg_id
}

output "resource_group_location" {
  description = "Resource group location"
  value       = module.resource_group.rg_location
}

# -----------------------------------------------------------------------------
# NETWORKING OUTPUTS
# -----------------------------------------------------------------------------

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = module.networking.vnet_name
}

output "subnet_id" {
  description = "Subnet ID"
  value       = module.networking.subnet_id
}

output "nsg_id" {
  description = "Network security group ID"
  value       = module.networking.nsg_id
}

# -----------------------------------------------------------------------------
# STORAGE OUTPUTS
# -----------------------------------------------------------------------------

output "storage_account_name" {
  description = "Storage account name"
  value       = module.storage.storage_account_name
}

output "file_share_name" {
  description = "File share name"
  value       = module.storage.file_share_name
}

output "storage_mount_command" {
  description = "Command to mount file share"
  value       = module.storage.mount_command
  sensitive   = true
}

# -----------------------------------------------------------------------------
# VM1 OUTPUTS
# -----------------------------------------------------------------------------

output "vm1_name" {
  description = "VM1 name"
  value       = module.vm1_infr1.vm_name
}

output "vm1_private_ip" {
  description = "VM1 private IP"
  value       = module.vm1_infr1.private_ip
}

output "vm1_public_ip" {
  description = "VM1 public IP"
  value       = module.vm1_infr1.public_ip
}

output "vm1_ssh_connection" {
  description = "SSH connection string for VM1"
  value       = module.vm1_infr1.ssh_connection_string
}

output "vm1_ssh_private_key_path" {
  description = "Path to VM1 SSH private key"
  value       = module.vm1_infr1.ssh_private_key_path
}

# -----------------------------------------------------------------------------
# VM2 OUTPUTS
# -----------------------------------------------------------------------------

output "vm2_name" {
  description = "VM2 name"
  value       = module.vm2_secu1.vm_name
}

output "vm2_private_ip" {
  description = "VM2 private IP"
  value       = module.vm2_secu1.private_ip
}

output "vm2_public_ip" {
  description = "VM2 public IP"
  value       = module.vm2_secu1.public_ip
}

output "vm2_ssh_connection" {
  description = "SSH connection string for VM2"
  value       = module.vm2_secu1.ssh_connection_string
}

# -----------------------------------------------------------------------------
# VM3 OUTPUTS
# -----------------------------------------------------------------------------

output "vm3_name" {
  description = "VM3 name"
  value       = module.vm3_apps1.vm_name
}

output "vm3_private_ip" {
  description = "VM3 private IP"
  value       = module.vm3_apps1.private_ip
}

output "vm3_public_ip" {
  description = "VM3 public IP"
  value       = module.vm3_apps1.public_ip
}

output "vm3_ssh_connection" {
  description = "SSH connection string for VM3"
  value       = module.vm3_apps1.ssh_connection_string
}

# -----------------------------------------------------------------------------
# VM4 OUTPUTS
# -----------------------------------------------------------------------------

output "vm4_name" {
  description = "VM4 name"
  value       = module.vm4_apps2.vm_name
}

output "vm4_private_ip" {
  description = "VM4 private IP"
  value       = module.vm4_apps2.private_ip
}

output "vm4_public_ip" {
  description = "VM4 public IP"
  value       = module.vm4_apps2.public_ip
}

output "vm4_ssh_connection" {
  description = "SSH connection string for VM4"
  value       = module.vm4_apps2.ssh_connection_string
}

# -----------------------------------------------------------------------------
# VM5 OUTPUTS
# -----------------------------------------------------------------------------

output "vm5_name" {
  description = "VM5 name"
  value       = module.vm5_data1.vm_name
}

output "vm5_private_ip" {
  description = "VM5 private IP"
  value       = module.vm5_data1.private_ip
}

output "vm5_public_ip" {
  description = "VM5 public IP"
  value       = module.vm5_data1.public_ip
}

output "vm5_ssh_connection" {
  description = "SSH connection string for VM5"
  value       = module.vm5_data1.ssh_connection_string
}

# -----------------------------------------------------------------------------
# SUMMARY OUTPUTS
# -----------------------------------------------------------------------------

output "all_vms" {
  description = "Summary of all VMs"
  value = {
    vm1_master = {
      name       = module.vm1_infr1.vm_name
      role       = module.vm1_infr1.vm_role
      private_ip = module.vm1_infr1.private_ip
      public_ip  = module.vm1_infr1.public_ip
      components = module.vm1_infr1.vm_components
    }
    vm2_worker = {
      name       = module.vm2_secu1.vm_name
      role       = module.vm2_secu1.vm_role
      private_ip = module.vm2_secu1.private_ip
      public_ip  = module.vm2_secu1.public_ip
      components = module.vm2_secu1.vm_components
    }
    vm3_worker = {
      name       = module.vm3_apps1.vm_name
      role       = module.vm3_apps1.vm_role
      private_ip = module.vm3_apps1.private_ip
      public_ip  = module.vm3_apps1.public_ip
      components = module.vm3_apps1.vm_components
    }
    vm4_worker = {
      name       = module.vm4_apps2.vm_name
      role       = module.vm4_apps2.vm_role
      private_ip = module.vm4_apps2.private_ip
      public_ip  = module.vm4_apps2.public_ip
      components = module.vm4_apps2.vm_components
    }
    vm5_worker = {
      name       = module.vm5_data1.vm_name
      role       = module.vm5_data1.vm_role
      private_ip = module.vm5_data1.private_ip
      public_ip  = module.vm5_data1.public_ip
      components = module.vm5_data1.vm_components
    }
  }
}
