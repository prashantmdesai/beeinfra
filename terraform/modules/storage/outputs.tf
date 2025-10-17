# =============================================================================
# STORAGE MODULE - OUTPUTS
# =============================================================================

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "primary_access_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "The secondary access key for the storage account"
  value       = azurerm_storage_account.main.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "The primary connection string for the storage account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "primary_file_endpoint" {
  description = "The primary file endpoint for the storage account"
  value       = azurerm_storage_account.main.primary_file_endpoint
}

output "file_share_name" {
  description = "The name of the file share"
  value       = azurerm_storage_share.main.name
}

output "file_share_id" {
  description = "The ID of the file share"
  value       = azurerm_storage_share.main.id
}

output "file_share_url" {
  description = "The URL of the file share"
  value       = azurerm_storage_share.main.url
}

output "mount_command" {
  description = "Command to mount the file share on Linux VMs"
  value       = <<-EOT
    sudo mount -t cifs //${azurerm_storage_account.main.name}.file.core.windows.net/${azurerm_storage_share.main.name} /mnt/${azurerm_storage_share.main.name} -o vers=3.0,username=${azurerm_storage_account.main.name},password=<ACCESS_KEY>,dir_mode=0777,file_mode=0777,serverino
  EOT
}

output "mount_path" {
  description = "Recommended mount path on VMs"
  value       = "/mnt/${azurerm_storage_share.main.name}"
}

# =============================================================================
# BLOB STORAGE (BLBS) OUTPUTS
# =============================================================================

output "blob_container_name" {
  description = "The name of the blob container"
  value       = azurerm_storage_container.blbs.name
}

output "blob_container_id" {
  description = "The ID of the blob container"
  value       = azurerm_storage_container.blbs.id
}

output "primary_blob_endpoint" {
  description = "The primary blob endpoint for the storage account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "blob_mount_path" {
  description = "Recommended mount path for blob container on VMs"
  value       = "/mnt/${azurerm_storage_container.blbs.name}"
}

output "blob_connection_string" {
  description = "Connection string for blob storage (used by BlobFuse)"
  value       = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.main.name};AccountKey=${azurerm_storage_account.main.primary_access_key};EndpointSuffix=core.windows.net"
  sensitive   = true
}
