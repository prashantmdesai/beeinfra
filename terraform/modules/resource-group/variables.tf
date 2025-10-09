# =============================================================================
# RESOURCE GROUP MODULE - VARIABLES
# =============================================================================

variable "org_name" {
  description = "Organization name (e.g., dats)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.org_name))
    error_message = "Organization name must contain only lowercase letters and numbers."
  }
}

variable "platform_name" {
  description = "Platform name (e.g., beeux)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.platform_name))
    error_message = "Platform name must contain only lowercase letters and numbers."
  }
}

variable "env_name" {
  description = "Environment name (e.g., dev, sit, uat, prd)"
  type        = string
  
  validation {
    condition     = contains(["dev", "sit", "uat", "prd"], var.env_name)
    error_message = "Environment must be one of: dev, sit, uat, prd."
  }
}

variable "location" {
  description = "Azure region for the resource group (e.g., centralus)"
  type        = string
  default     = "centralus"
  
  validation {
    condition     = can(regex("^[a-z]+$", var.location))
    error_message = "Location must contain only lowercase letters (e.g., centralus, eastus)."
  }
}

variable "tags" {
  description = "Additional tags to apply to the resource group"
  type        = map(string)
  default     = {}
}
