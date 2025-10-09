# =============================================================================
# SSH KEY PAIR MODULE - VARIABLES
# =============================================================================

variable "key_name" {
  description = "Name for the SSH key pair (used in filename)"
  type        = string
}

variable "save_locally" {
  description = "Whether to save the SSH key files locally"
  type        = bool
  default     = true
}

variable "output_path" {
  description = "Directory path where SSH keys will be saved"
  type        = string
  default     = "./ssh-keys"
}
