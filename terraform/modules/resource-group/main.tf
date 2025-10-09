# =============================================================================
# RESOURCE GROUP MODULE
# =============================================================================
# Creates an Azure Resource Group with standardized naming convention
# Naming: {org}-{platform}-{env}-rg (e.g., dats-beeux-dev-rg)
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

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.org_name}-${var.platform_name}-${var.env_name}-rg"
  location = var.location

  tags = merge(
    var.tags,
    {
      Environment  = var.env_name
      Organization = var.org_name
      Platform     = var.platform_name
      ManagedBy    = "Terraform"
      Purpose      = "BeEux Word Learning Platform Infrastructure"
      CreatedDate  = timestamp()
    }
  )

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}
