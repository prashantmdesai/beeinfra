# =============================================================================
# VIRTUAL MACHINE MODULE - SSH KEY GENERATION
# =============================================================================
# Generates SSH key pairs for VM access if not provided
# =============================================================================

# Generate SSH key pair if not provided
resource "tls_private_key" "ssh" {
  count = var.ssh_public_key == null ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key to local file (for Terraform-generated keys only)
resource "local_file" "private_key" {
  count = var.ssh_public_key == null && var.save_ssh_key_locally ? 1 : 0

  content         = tls_private_key.ssh[0].private_key_pem
  filename        = "${path.root}/ssh-keys/${var.vm_name}-id_rsa"
  file_permission = "0600"
}

# Save public key to local file (for Terraform-generated keys only)
resource "local_file" "public_key" {
  count = var.ssh_public_key == null && var.save_ssh_key_locally ? 1 : 0

  content         = tls_private_key.ssh[0].public_key_openssh
  filename        = "${path.root}/ssh-keys/${var.vm_name}-id_rsa.pub"
  file_permission = "0644"
}
