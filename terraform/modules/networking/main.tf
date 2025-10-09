# =============================================================================
# NETWORKING MODULE
# =============================================================================
# Creates VNet, Subnet, and NSG for the BeEux Word Learning Platform
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.org_name}-${var.platform_name}-${var.env_name}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_address_space]

  tags = merge(
    var.tags,
    {
      Environment  = var.env_name
      Organization = var.org_name
      Platform     = var.platform_name
      ManagedBy    = "Terraform"
    }
  )
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.org_name}-${var.platform_name}-${var.env_name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefix]
  
  # Service endpoints required for storage account network rules
  service_endpoints = ["Microsoft.Storage"]
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${var.org_name}-${var.platform_name}-${var.env_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      Environment  = var.env_name
      Organization = var.org_name
      Platform     = var.platform_name
      ManagedBy    = "Terraform"
    }
  )
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}
