# =============================================================================
# BACKEND CONFIGURATION
# =============================================================================
# Azure Storage backend for Terraform state
# This keeps state centralized and enables team collaboration
# =============================================================================

terraform {
  backend "azurerm" {
    # NOTE: These values should be provided via backend config file or environment variables
    # Example initialization:
    # terraform init \
    #   -backend-config="resource_group_name=terraform-state-rg" \
    #   -backend-config="storage_account_name=tfstateacct" \
    #   -backend-config="container_name=tfstate" \
    #   -backend-config="key=dev/terraform.tfstate"
    
    # Uncomment and configure for production use:
    # resource_group_name  = "terraform-state-rg"
    # storage_account_name = "tfstateacct"
    # container_name       = "tfstate"
    # key                  = "dev/terraform.tfstate"
  }
}
