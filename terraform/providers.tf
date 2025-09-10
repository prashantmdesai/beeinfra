# =============================================================================
# TERRAFORM PROVIDERS CONFIGURATION
# =============================================================================
# This file configures the required Terraform providers for the BeeInfra project.
# 
# MIGRATION FROM BICEP TO TERRAFORM:
# ==================================
# This replaces the previous Azure Bicep-based infrastructure deployment with
# Terraform for better multi-cloud capabilities, state management, and 
# infrastructure lifecycle management across IT, QA, and Production environments.
#
# REQUIREMENTS COMPLIANCE:
# =======================
# This configuration supports requirements from infrasetup.instructions.md:
# - Multi-environment deployment (IT, QA, Production)
# - Azure resource management with consistent naming
# - State management for infrastructure changes
# - Provider version pinning for reproducible deployments
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    # Azure Resource Manager provider for all Azure resources
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75.0"
    }
    
    # Azure Active Directory provider for identity management
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45.0"
    }
    
    # Random provider for generating secure passwords and unique names
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    
    # Time provider for resource delays and scheduling
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.1"
    }
    
    # Azure CAF (Cloud Adoption Framework) for naming conventions
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2.26"
    }
  }
  
  # Backend configuration for state storage
  # This will be configured per environment in the environment-specific files
  backend "azurerm" {
    # Configuration provided via backend config files or environment variables
  }
}

# Configure the Azure Provider with enhanced security features
provider "azurerm" {
  features {
    # Enhanced security and cleanup features
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = true
      skip_shutdown_and_force_delete = false
    }
    
    application_insights {
      disable_generated_rule = false
    }
  }
  
  # Skip provider registration for faster deployments
  skip_provider_registration = false
  
  # Use Azure CLI authentication by default
  use_cli = true
  use_msi = false
}

# Configure Azure AD Provider
provider "azuread" {
  # Use Azure CLI authentication
  use_cli = true
}

# Configure Random Provider
provider "random" {
  # No specific configuration needed
}

# Configure Time Provider  
provider "time" {
  # No specific configuration needed
}

# Configure Azure CAF Provider for consistent naming
provider "azurecaf" {
  # No specific configuration needed
}
