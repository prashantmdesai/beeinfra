#!/bin/bash
################################################################################
# Script: deploy-all.sh
# Description: Complete deployment orchestration for Azure infrastructure
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
readonly SCRIPT_NAME="deploy-all"
readonly LOG_FILE="/var/log/deployment/${SCRIPT_NAME}.log"

# Deployment configuration
readonly TERRAFORM_DIR="${TERRAFORM_DIR:-$(cd "${SCRIPT_DIR}/../../terraform/environments/dev" && pwd)}"
readonly BACKUP_DIR="/tmp/terraform-backups"
readonly TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$BACKUP_DIR"

################################################################################
# Function: print_banner
# Description: Print deployment banner
################################################################################
print_banner() {
    echo ""
    echo "=========================================="
    echo "  Azure Infrastructure Deployment"
    echo "=========================================="
    echo "Environment: dev"
    echo "Terraform Dir: $TERRAFORM_DIR"
    echo "Timestamp: $(date)"
    echo "=========================================="
    echo ""
}

################################################################################
# Function: check_prerequisites
# Description: Verify prerequisites for deployment
################################################################################
check_prerequisites() {
    log_info "Checking deployment prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform not found. Please install Terraform first"
        log_error "Visit: https://www.terraform.io/downloads"
        return 1
    fi
    
    local tf_version=$(terraform version | head -n1 | awk '{print $2}')
    log_info "Terraform version: $tf_version"
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI not found. Please install Azure CLI first"
        log_error "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        return 1
    fi
    
    local az_version=$(az version --output json | grep '"azure-cli"' | awk -F'"' '{print $4}')
    log_info "Azure CLI version: $az_version"
    
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
    
    log_info "Prerequisites check completed successfully"
    return 0
}

################################################################################
# Function: validate_tfvars
# Description: Validate that required tfvars files exist
################################################################################
validate_tfvars() {
    log_info "Validating Terraform variable files..."
    
    cd "$TERRAFORM_DIR" || return 1
    
    local required_files=(
        "terraform.tfvars"
        "vm1-infr1-dev.tfvars"
        "vm2-secu1-dev.tfvars"
        "vm3-apps1-dev.tfvars"
        "vm4-apps2-dev.tfvars"
        "vm5-data1-dev.tfvars"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "Missing required tfvars files:"
        for file in "${missing_files[@]}"; do
            log_error "  - $file"
        done
        log_error ""
        log_error "Please copy .example files and configure them:"
        for file in "${missing_files[@]}"; do
            log_error "  cp ${file}.example ${file}"
        done
        return 1
    fi
    
    log_info "All required tfvars files are present"
    return 0
}

################################################################################
# Function: backup_state
# Description: Backup current Terraform state if it exists
################################################################################
backup_state() {
    log_info "Backing up Terraform state..."
    
    cd "$TERRAFORM_DIR" || return 1
    
    if [[ -f "terraform.tfstate" ]]; then
        local backup_file="${BACKUP_DIR}/terraform.tfstate.${TIMESTAMP}"
        cp terraform.tfstate "$backup_file"
        log_info "State backed up to: $backup_file"
    else
        log_info "No existing state file to backup"
    fi
    
    return 0
}

################################################################################
# Function: terraform_init
# Description: Initialize Terraform working directory
################################################################################
terraform_init() {
    log_info "Initializing Terraform..."
    
    cd "$TERRAFORM_DIR" || return 1
    
    terraform init -upgrade 2>&1 | tee -a "$LOG_FILE" || {
        log_error "Terraform initialization failed"
        return 1
    }
    
    log_info "Terraform initialized successfully"
    return 0
}

################################################################################
# Function: terraform_validate
# Description: Validate Terraform configuration
################################################################################
terraform_validate() {
    log_info "Validating Terraform configuration..."
    
    cd "$TERRAFORM_DIR" || return 1
    
    terraform validate 2>&1 | tee -a "$LOG_FILE" || {
        log_error "Terraform validation failed"
        return 1
    }
    
    log_info "Terraform configuration is valid"
    return 0
}

################################################################################
# Function: terraform_plan
# Description: Generate and review Terraform execution plan
################################################################################
terraform_plan() {
    log_info "Generating Terraform execution plan..."
    
    cd "$TERRAFORM_DIR" || return 1
    
    local plan_file="${BACKUP_DIR}/terraform.plan.${TIMESTAMP}"
    
    terraform plan \
        -var-file="terraform.tfvars" \
        -var-file="vm1-infr1-dev.tfvars" \
        -var-file="vm2-secu1-dev.tfvars" \
        -var-file="vm3-apps1-dev.tfvars" \
        -var-file="vm4-apps2-dev.tfvars" \
        -var-file="vm5-data1-dev.tfvars" \
        -out="$plan_file" 2>&1 | tee -a "$LOG_FILE" || {
        log_error "Terraform plan failed"
        return 1
    }
    
    log_info "Execution plan saved to: $plan_file"
    
    # Display plan summary
    echo ""
    echo "=========================================="
    echo "Terraform Plan Summary"
    echo "=========================================="
    terraform show -no-color "$plan_file" | grep -E "Plan:|No changes" | tee -a "$LOG_FILE"
    echo "=========================================="
    echo ""
    
    # Save plan file path for apply step
    echo "$plan_file" > "${BACKUP_DIR}/latest-plan.txt"
    
    return 0
}

################################################################################
# Function: confirm_apply
# Description: Ask user to confirm apply
################################################################################
confirm_apply() {
    log_info "Awaiting user confirmation to proceed with apply..."
    
    echo ""
    echo "=========================================="
    echo "IMPORTANT: Review the plan above carefully"
    echo "=========================================="
    echo ""
    read -p "Do you want to proceed with applying this plan? (yes/no): " response
    
    if [[ "$response" != "yes" ]]; then
        log_info "Deployment cancelled by user"
        return 1
    fi
    
    log_info "User confirmed deployment"
    return 0
}

################################################################################
# Function: terraform_apply
# Description: Apply Terraform execution plan
################################################################################
terraform_apply() {
    log_info "Applying Terraform execution plan..."
    
    cd "$TERRAFORM_DIR" || return 1
    
    local plan_file=$(cat "${BACKUP_DIR}/latest-plan.txt")
    
    if [[ ! -f "$plan_file" ]]; then
        log_error "Plan file not found: $plan_file"
        return 1
    fi
    
    terraform apply "$plan_file" 2>&1 | tee -a "$LOG_FILE" || {
        log_error "Terraform apply failed"
        log_error "Check logs for details: $LOG_FILE"
        return 1
    }
    
    log_info "Terraform apply completed successfully"
    return 0
}

################################################################################
# Function: save_outputs
# Description: Save Terraform outputs
################################################################################
save_outputs() {
    log_info "Saving Terraform outputs..."
    
    cd "$TERRAFORM_DIR" || return 1
    
    local output_file="${BACKUP_DIR}/terraform-outputs.${TIMESTAMP}.json"
    
    terraform output -json > "$output_file" 2>&1 || {
        log_warning "Failed to save outputs"
        return 0
    }
    
    log_info "Outputs saved to: $output_file"
    
    # Display key outputs
    echo ""
    echo "=========================================="
    echo "Deployment Outputs"
    echo "=========================================="
    terraform output 2>&1 | tee -a "$LOG_FILE"
    echo "=========================================="
    echo ""
    
    return 0
}

################################################################################
# Function: verify_resources
# Description: Verify that resources were created
################################################################################
verify_resources() {
    log_info "Verifying deployed resources..."
    
    cd "$TERRAFORM_DIR" || return 1
    
    # Count resources
    local resource_count=$(terraform state list 2>/dev/null | wc -l)
    log_info "Total resources in state: $resource_count"
    
    # Check resource group
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
    if [[ -n "$rg_name" ]]; then
        log_info "Verifying resource group: $rg_name"
        if az group show --name "$rg_name" &>/dev/null; then
            log_info "✓ Resource group exists"
        else
            log_error "✗ Resource group not found"
            return 1
        fi
    fi
    
    # Check VMs
    log_info "Checking virtual machines..."
    local vm_count=$(az vm list --resource-group "$rg_name" --query "length(@)" -o tsv 2>/dev/null || echo "0")
    log_info "VMs deployed: $vm_count"
    
    if [[ "$vm_count" -eq 5 ]]; then
        log_info "✓ All 5 VMs deployed"
    else
        log_warning "Expected 5 VMs, found $vm_count"
    fi
    
    # List VMs
    if [[ "$vm_count" -gt 0 ]]; then
        echo ""
        echo "Deployed Virtual Machines:"
        az vm list --resource-group "$rg_name" --query "[].{Name:name, State:powerState, IP:privateIps}" -o table 2>&1 | tee -a "$LOG_FILE"
    fi
    
    log_info "Resource verification completed"
    return 0
}

################################################################################
# Function: print_summary
# Description: Print deployment summary
################################################################################
print_summary() {
    local duration=$1
    
    cd "$TERRAFORM_DIR" || return 1
    
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null || echo "N/A")
    local vnet_name=$(terraform output -raw vnet_name 2>/dev/null || echo "N/A")
    local storage_account=$(terraform output -raw storage_account_name 2>/dev/null || echo "N/A")
    
    echo ""
    echo "=========================================="
    echo "Deployment Summary"
    echo "=========================================="
    echo "Status: SUCCESS"
    echo "Duration: ${duration}s"
    echo "Timestamp: $(date)"
    echo ""
    echo "Infrastructure:"
    echo "  - Resource Group: $rg_name"
    echo "  - Virtual Network: $vnet_name"
    echo "  - Storage Account: $storage_account"
    echo ""
    echo "Virtual Machines:"
    echo "  - vm1-infr1-dev (Master Node)"
    echo "  - vm2-secu1-dev (Worker Node 1)"
    echo "  - vm3-apps1-dev (Worker Node 2)"
    echo "  - vm4-apps2-dev (Worker Node 3)"
    echo "  - vm5-data1-dev (Worker Node 4)"
    echo ""
    echo "Next Steps:"
    echo "  1. Verify deployment: ./validate-deployment.sh"
    echo "  2. SSH to master: ssh beeuser@<master-ip>"
    echo "  3. Check cluster: kubectl get nodes"
    echo ""
    echo "Logs: $LOG_FILE"
    echo "Backups: $BACKUP_DIR"
    echo "=========================================="
}

################################################################################
# Function: cleanup_on_error
# Description: Cleanup on deployment failure
################################################################################
cleanup_on_error() {
    log_error "=========================================="
    log_error "Deployment Failed"
    log_error "=========================================="
    log_error ""
    log_error "Troubleshooting steps:"
    log_error "  1. Check logs: tail -f $LOG_FILE"
    log_error "  2. Review plan: terraform show ${BACKUP_DIR}/terraform.plan.${TIMESTAMP}"
    log_error "  3. Check Azure portal for partial resources"
    log_error "  4. Consider cleanup: terraform destroy"
    log_error ""
    log_error "State backup: ${BACKUP_DIR}/terraform.tfstate.${TIMESTAMP}"
    log_error "=========================================="
}

################################################################################
# Main execution
################################################################################
main() {
    local start_time=$(date +%s)
    
    print_banner
    
    log_info "=========================================="
    log_info "Starting Azure infrastructure deployment"
    log_info "=========================================="
    
    # Set up error handler
    trap cleanup_on_error ERR
    
    # Execute deployment steps
    check_prerequisites || exit 1
    validate_tfvars || exit 1
    backup_state || exit 1
    terraform_init || exit 1
    terraform_validate || exit 1
    terraform_plan || exit 1
    
    # Confirm before apply
    confirm_apply || exit 0
    
    terraform_apply || exit 1
    save_outputs || exit 1
    verify_resources || exit 1
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_info "=========================================="
    log_info "Deployment completed successfully"
    log_info "=========================================="
    
    print_summary "$duration"
    exit 0
}

# Execute main function
main "$@"
