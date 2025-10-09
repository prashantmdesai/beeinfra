# =============================================================================
# NETWORKING MODULE - VARIABLES
# =============================================================================

variable "org_name" {
  description = "Organization name (e.g., dats)"
  type        = string
}

variable "platform_name" {
  description = "Platform name (e.g., beeux)"
  type        = string
}

variable "env_name" {
  description = "Environment name (e.g., dev, sit, uat, prd)"
  type        = string
}

variable "location" {
  description = "Azure region for the network resources"
  type        = string
  default     = "centralus"
}

variable "resource_group_name" {
  description = "Name of the resource group where network resources will be created"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "VNet address space must be a valid CIDR block."
  }
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet"
  type        = string
  default     = "10.0.1.0/24"
  
  validation {
    condition     = can(cidrhost(var.subnet_address_prefix, 0))
    error_message = "Subnet address prefix must be a valid CIDR block."
  }
}

variable "laptop_ip" {
  description = "Laptop IP address for NSG rules (CIDR format, e.g., 136.56.79.92/32)"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.laptop_ip, 0))
    error_message = "Laptop IP must be a valid CIDR block (e.g., 136.56.79.92/32)."
  }
}

variable "wifi_cidr" {
  description = "WiFi network CIDR for NSG rules (e.g., 136.56.79.0/24)"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.wifi_cidr, 0))
    error_message = "WiFi CIDR must be a valid CIDR block (e.g., 136.56.79.0/24)."
  }
}

variable "tags" {
  description = "Additional tags to apply to network resources"
  type        = map(string)
  default     = {}
}
