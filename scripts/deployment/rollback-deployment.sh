#!/bin/bash
################################################################################
# Script: rollback-deployment.sh
# Description: Rollback Azure infrastructure deployment
# Author: Infrastructure Team
# Date: 2025-10-08
# Version: 1.0.0
################################################################################

set -euo pipefail

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../common"

source "${COMMON_DIR}/logging-standard.sh"
source "${COMMON_DIR}/error-handlers.sh"
source "${COMMON_DIR}/validation-helpers.sh"

# Script configuration
readonly SCRIPT_NAME="rollback-deployment"
readonly LOG_FILE="/var/log/deployment/${SCRIPT_NAME}.log"

# Deployment configuration
readonly TERRAFORM_DIR="${TERRAFORM_DIR:-$(cd "${SCRIPT_DIR}/../../terraform/environments/dev" && pwd)}"
readonly BACKUP_DIR="/tmp/terraform-backups"
readonly TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

################################################################################
# Function: print_banner
# Description: Print rollback banner
################################################################################
print_banner() {
    echo ""
    echo "=========================================="
    echo "  Azure Infrastructure Rollback"
    echo "=========================================="
    echo "Environment: dev"
    echo "Terraform Dir: $TERRAFORM_DIR"
    echo "Timestamp: $(date)"
    echo "=========================================="
    echo ""
}

################################################################################
# Function: check_prerequisites
# Description: Verify prerequisites for rollback
################################################################################
check_prerequisites() {
    log_info "Checking rollback prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform not found. Please install Terraform first"
        return 1
    fi
    
    local tf_version=$(terraform version | head -n1 | awk '{print $2}')
    log_info "Terraform version: $tf_version"
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI not found. Please install Azure CLI first"
        return 1
    fi
    
    # Check Azure authentication
    log_info "Checking Azure authentication..."
    if ! az account show &> /dev/null; then
        log_error "Not authenticated with Azure. Please run: az login"
        return 1
    fi
    
    local subscription=$(az account show --query name -o tsv)
    log_info "Current subscription: $subscription"
    
    # Check if terraform directory exists
    if [[ ! -d "$TERRAFORM_DIR" ]]; then
        log_error "Terraform directory not found: $TERRAFORM_DIR"
        return 1
    fi
    
    # Check if state file exists
    cd "$TERRAFORM_DIR" || return 1
    if [[ ! -f "terraform.tfstate" ]]; then
        log_error "Terraform state file not found"
        log_error "No deployment to rollback"
        return 1
    fi
    
    log_info "Prerequisites check completed successfully"
    return 0
}

################################################################################
# Function: backup_current_state
# Description: Backup current state before rollback
################################################################################
backup_current_state() {
    log_info "Backing up current Terraform state..."
    
    cd "$TERRAFORM_DIR" || return 1
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup state
    if [[ -f "terraform.tfstate" ]]; then
        local backup_file="${BACKUP_DIR}/terraform.tfstate.pre-rollback.${TIMESTAMP}"
        cp terraform.tfstate "$backup_file"
        log_info "State backed up to: $backup_file"
    fi
    
    # Backup state backup file
    if [[ -f "terraform.tfstate.backup" ]]; then
        local backup_file="${BACKUP_DIR}/terraform.tfstate.backup.pre-rollback.${TIMESTAMP}"
        cp terraform.tfstate.backup "$backup_file"
        log_info "State backup backed up to: $backup_file"
    fi
    
    return 0
}

################################################################################
# Function: show_current_resources
# Description: Display current resources
################################################################################
show_current_resources() {
    log_info "Current resources in state:"
    
    cd "$TERRAFORM_DIR" || return 1
    
    local resource_count=$(terraform state list 2>/dev/null | wc -l)
    log_info "Total resources: $resource_count"
    
    echo ""
    echo "Resources to be destroyed:"
    echo "=========================================="
    terraform state list 2>&1 | tee -a "$LOG_FILE"
    echo "=========================================="
    echo ""
    
    # Get resource group info
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
    if [[ -n "$rg_name" ]]; then
        log_info "Resource group: $rg_name"
        
        # List resources in Azure
        echo ""
        echo "Azure Resources in $rg_name:"
        echo "=========================================="
        az resource list --resource-group "$rg_name" --query "[].{Name:name, Type:type}" -o table 2>&1 | tee -a "$LOG_FILE" || true
        echo "=========================================="
        echo ""
    fi
    
    return 0
}

################################################################################
# Function: generate_destroy_plan
# Description: Generate destroy plan
################################################################################
generate_destroy_plan() {
    log_info "Generating destroy plan..."
    
    cd "$TERRAFORM_DIR" || return 1
    
    local plan_file="${BACKUP_DIR}/terraform.destroy.plan.${TIMESTAMP}"
    
    terraform plan -destroy \
        -var-file="terraform.tfvars" \
        -var-file="vm1-infr1-dev.tfvars" \
        -var-file="vm2-secu1-dev.tfvars" \
        -var-file="vm3-apps1-dev.tfvars" \
        -var-file="vm4-apps2-dev.tfvars" \
        -var-file="vm5-data1-dev.tfvars" \
        -out="$plan_file" 2>&1 | tee -a "$LOG_FILE" || {
        log_error "Failed to generate destroy plan"
        return 1
    }
    
    log_info "Destroy plan saved to: $plan_file"
    
    # Display plan summary
    echo ""
    echo "=========================================="
    echo "Destroy Plan Summary"
    echo "=========================================="
    terraform show -no-color "$plan_file" | grep -E "Plan:" | tee -a "$LOG_FILE"
    echo "=========================================="
    echo ""
    
    # Save plan file path
    echo "$plan_file" > "${BACKUP_DIR}/latest-destroy-plan.txt"
    
    return 0
}

################################################################################
# Function: confirm_destroy
# Description: Ask user to confirm destroy
################################################################################
confirm_destroy() {
    log_info "Awaiting user confirmation to proceed with destroy..."
    
    echo ""
    echo "=========================================="
    echo "WARNING: DESTRUCTIVE OPERATION"
    echo "=========================================="
    echo "This will DESTROY all infrastructure resources including:"
    echo "  - All 5 Virtual Machines"
    echo "  - Virtual Network and Subnets"
    echo "  - Storage Account and File Share"
    echo "  - Network Security Groups"
    echo "  - Public IP Addresses"
    echo "  - Network Interfaces"
    echo "  - All data will be PERMANENTLY DELETED"
    echo ""
    echo "This operation CANNOT be undone!"
    echo "=========================================="
    echo ""
    
    read -p "Are you ABSOLUTELY SURE you want to destroy all resources? Type 'destroy' to confirm: " response
    
    if [[ "$response" != "destroy" ]]; then
        log_info "Rollback cancelled by user"
        return 1
    fi
    
    echo ""
    read -p "Final confirmation - Type 'yes' to proceed: " final_response
    
    if [[ "$final_response" != "yes" ]]; then
        log_info "Rollback cancelled by user"
        return 1
    fi
    
    log_info "User confirmed destruction"
    return 0
}

################################################################################
# Function: terraform_destroy
# Description: Execute Terraform destroy
################################################################################
terraform_destroy() {
    log_info "Destroying infrastructure..."
    
    cd "$TERRAFORM_DIR" || return 1
    
    local plan_file=$(cat "${BACKUP_DIR}/latest-destroy-plan.txt")
    
    if [[ ! -f "$plan_file" ]]; then
        log_error "Destroy plan file not found: $plan_file"
        return 1
    fi
    
    terraform apply "$plan_file" 2>&1 | tee -a "$LOG_FILE" || {
        log_error "Terraform destroy failed"
        log_error "Some resources may still exist. Check Azure portal"
        return 1
    }
    
    log_info "Terraform destroy completed successfully"
    return 0
}

################################################################################
# Function: verify_destruction
# Description: Verify resources were destroyed
################################################################################
verify_destruction() {
    log_info "Verifying resource destruction..."
    
    cd "$TERRAFORM_DIR" || return 1
    
    # Check state
    local resource_count=$(terraform state list 2>/dev/null | wc -l)
    if [[ $resource_count -eq 0 ]]; then
        log_info "✓ All resources removed from state"
    else
        log_warning "Some resources still in state: $resource_count"
        terraform state list 2>&1 | tee -a "$LOG_FILE"
    fi
    
    # Try to get resource group from backup
    local rg_name=""
    local backup_state="${BACKUP_DIR}/terraform.tfstate.pre-rollback.${TIMESTAMP}"
    if [[ -f "$backup_state" ]]; then
        rg_name=$(cat "$backup_state" | grep -o '"resource_group_name"[^}]*' | grep -o '"value"[^"]*"[^"]*' | cut -d'"' -f4 | head -n1 || echo "")
    fi
    
    # Check Azure
    if [[ -n "$rg_name" ]]; then
        log_info "Checking Azure for resource group: $rg_name"
        
        if az group show --name "$rg_name" &>/dev/null; then
            log_warning "Resource group still exists in Azure"
            
            local remaining=$(az resource list --resource-group "$rg_name" --query "length(@)" -o tsv 2>/dev/null || echo "0")
            if [[ $remaining -gt 0 ]]; then
                log_warning "Resources still in group: $remaining"
                az resource list --resource-group "$rg_name" --query "[].{Name:name, Type:type}" -o table 2>&1 | tee -a "$LOG_FILE"
            fi
        else
            log_info "✓ Resource group deleted from Azure"
        fi
    fi
    
    log_info "Destruction verification completed"
    return 0
}

################################################################################
# Function: cleanup_local_state
# Description: Clean up local state files
################################################################################
cleanup_local_state() {
    log_info "Cleaning up local state files..."
    
    cd "$TERRAFORM_DIR" || return 1
    
    # Move state files to backup
    if [[ -f "terraform.tfstate" ]]; then
        mv terraform.tfstate "${BACKUP_DIR}/terraform.tfstate.final.${TIMESTAMP}"
        log_info "State file moved to backup"
    fi
    
    if [[ -f "terraform.tfstate.backup" ]]; then
        mv terraform.tfstate.backup "${BACKUP_DIR}/terraform.tfstate.backup.final.${TIMESTAMP}"
        log_info "State backup moved to backup"
    fi
    
    # Clean .terraform directory
    if [[ -d ".terraform" ]]; then
        log_info "Removing .terraform directory..."
        rm -rf .terraform
    fi
    
    # Clean lock file
    if [[ -f ".terraform.lock.hcl" ]]; then
        log_info "Removing lock file..."
        rm -f .terraform.lock.hcl
    fi
    
    log_info "Local cleanup completed"
    return 0
}

################################################################################
# Function: print_summary
# Description: Print rollback summary
################################################################################
print_summary() {
    local duration=$1
    
    echo ""
    echo "=========================================="
    echo "Rollback Summary"
    echo "=========================================="
    echo "Status: SUCCESS"
    echo "Duration: ${duration}s"
    echo "Timestamp: $(date)"
    echo ""
    echo "Actions Completed:"
    echo "  ✓ Infrastructure destroyed"
    echo "  ✓ Resources removed from state"
    echo "  ✓ Local state files backed up"
    echo "  ✓ Terraform directory cleaned"
    echo ""
    echo "Backups Location: $BACKUP_DIR"
    echo ""
    echo "To redeploy infrastructure:"
    echo "  1. Review configuration: cd $TERRAFORM_DIR"
    echo "  2. Run deployment: ../../scripts/deployment/deploy-all.sh"
    echo ""
    echo "Logs: $LOG_FILE"
    echo "=========================================="
}

################################################################################
# Function: cleanup_on_error
# Description: Cleanup on rollback failure
################################################################################
cleanup_on_error() {
    log_error "=========================================="
    log_error "Rollback Failed"
    log_error "=========================================="
    log_error ""
    log_error "Some resources may still exist in Azure."
    log_error ""
    log_error "Manual cleanup may be required:"
    log_error "  1. Check Azure portal for remaining resources"
    log_error "  2. Delete resource group manually if needed"
    log_error "  3. Review Terraform state"
    log_error ""
    log_error "Logs: $LOG_FILE"
    log_error "Backups: $BACKUP_DIR"
    log_error "=========================================="
}

################################################################################
# Main execution
################################################################################
main() {
    local start_time=$(date +%s)
    
    print_banner
    
    log_info "=========================================="
    log_info "Starting infrastructure rollback"
    log_info "=========================================="
    
    # Set up error handler
    trap cleanup_on_error ERR
    
    # Execute rollback steps
    check_prerequisites || exit 1
    backup_current_state || exit 1
    show_current_resources || exit 1
    generate_destroy_plan || exit 1
    
    # Confirm before destroy
    confirm_destroy || {
        log_info "Rollback cancelled"
        exit 0
    }
    
    terraform_destroy || exit 1
    verify_destruction || exit 1
    cleanup_local_state || exit 1
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_info "=========================================="
    log_info "Rollback completed successfully"
    log_info "=========================================="
    
    print_summary "$duration"
    exit 0
}

# Execute main function
main "$@"
