# =============================================================================
# SSH KEY PAIR MODULE - OUTPUTS
# =============================================================================

output "private_key_pem" {
  description = "The private key in PEM format"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "public_key_openssh" {
  description = "The public key in OpenSSH format"
  value       = tls_private_key.ssh.public_key_openssh
}

output "private_key_path" {
  description = "Path to the private key file (if saved locally)"
  value       = var.save_locally ? "${var.output_path}/${var.key_name}-id_rsa" : null
}

output "public_key_path" {
  description = "Path to the public key file (if saved locally)"
  value       = var.save_locally ? "${var.output_path}/${var.key_name}-id_rsa.pub" : null
}
