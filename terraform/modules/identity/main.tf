# =============================================================================
# IDENTITY MODULE - USER-ASSIGNED MANAGED IDENTITY
# =============================================================================
# This Terraform module creates and manages Azure user-assigned managed identities
# to replace the previous Bicep identity.bicep module functionality.
#
# MIGRATION FROM BICEP TO TERRAFORM:
# ==================================
# This module provides the same identity management capabilities as the previous
# Bicep template but with enhanced resource management and state tracking.
# =============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2.26"
    }
  }
}

# Generate unique name for the managed identity
resource "azurecaf_name" "user_assigned_identity" {
  name          = var.name
  resource_type = "azurerm_user_assigned_identity"
  random_length = 0
  clean_input   = true
}

# Create user-assigned managed identity
resource "azurerm_user_assigned_identity" "main" {
  name                = azurecaf_name.user_assigned_identity.result
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = merge(var.tags, {
    Purpose = "Managed Identity for Azure Services"
    Module  = "identity"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}
