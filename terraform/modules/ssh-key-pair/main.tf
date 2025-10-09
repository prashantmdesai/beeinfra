# =============================================================================
# SSH KEY PAIR MODULE
# =============================================================================
# Generates a single SSH key pair to be shared across multiple VMs
# This prevents redundant key generation and ensures all VMs use the same key
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Generate SSH key pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key to local file
resource "local_file" "private_key" {
  count = var.save_locally ? 1 : 0

  content         = tls_private_key.ssh.private_key_pem
  filename        = "${var.output_path}/${var.key_name}-id_rsa"
  file_permission = "0600"
}

# Save public key to local file
resource "local_file" "public_key" {
  count = var.save_locally ? 1 : 0

  content         = tls_private_key.ssh.public_key_openssh
  filename        = "${var.output_path}/${var.key_name}-id_rsa.pub"
  file_permission = "0644"
}
