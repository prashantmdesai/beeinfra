#!/bin/bash
################################################################################
# Script: validate-deployment.sh
# Description: Comprehensive validation of Azure infrastructure deployment
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
readonly SCRIPT_NAME="validate-deployment"
readonly LOG_FILE="/var/log/deployment/${SCRIPT_NAME}.log"

# Terraform configuration
readonly TERRAFORM_DIR="${TERRAFORM_DIR:-$(cd "${SCRIPT_DIR}/../../terraform/environments/dev" && pwd)}"

# Color codes for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Validation counters
declare -i TOTAL_TESTS=0
declare -i PASSED_TESTS=0
declare -i FAILED_TESTS=0
declare -i WARNING_TESTS=0

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

################################################################################
# Function: print_test_header
# Description: Print test section header
################################################################################
print_test_header() {
    local test_name="$1"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo ""
    echo -e "${BLUE}=========================================="
    echo -e "Test $TOTAL_TESTS: $test_name"
    echo -e "==========================================${NC}"
}

################################################################################
# Function: print_success
# Description: Print success message
################################################################################
print_success() {
    local message="$1"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo -e "${GREEN}✓ $message${NC}"
    log_info "✓ $message"
}

################################################################################
# Function: print_failure
# Description: Print failure message
################################################################################
print_failure() {
    local message="$1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo -e "${RED}✗ $message${NC}"
    log_error "✗ $message"
}

################################################################################
# Function: print_warning
# Description: Print warning message
################################################################################
print_warning() {
    local message="$1"
    WARNING_TESTS=$((WARNING_TESTS + 1))
    echo -e "${YELLOW}⚠ $message${NC}"
    log_warning "⚠ $message"
}

################################################################################
# Function: validate_prerequisites
# Description: Validate prerequisites for validation
################################################################################
validate_prerequisites() {
    print_test_header "Prerequisites"
    
    # Check Terraform
    if command -v terraform &> /dev/null; then
        local version=$(terraform version | head -n1 | awk '{print $2}')
        print_success "Terraform installed: $version"
    else
        print_failure "Terraform not installed"
        return 1
    fi
    
    # Check Azure CLI
    if command -v az &> /dev/null; then
        local version=$(az version --output json | grep '"azure-cli"' | awk -F'"' '{print $4}')
        print_success "Azure CLI installed: $version"
    else
        print_failure "Azure CLI not installed"
        return 1
    fi
    
    # Check Azure authentication
    if az account show &> /dev/null; then
        local subscription=$(az account show --query name -o tsv)
        print_success "Azure authenticated: $subscription"
    else
        print_failure "Not authenticated with Azure"
        return 1
    fi
    
    # Check Terraform directory
    if [[ -d "$TERRAFORM_DIR" ]]; then
        print_success "Terraform directory exists: $TERRAFORM_DIR"
    else
        print_failure "Terraform directory not found: $TERRAFORM_DIR"
        return 1
    fi
    
    return 0
}

################################################################################
# Function: validate_terraform_state
# Description: Validate Terraform state
################################################################################
validate_terraform_state() {
    print_test_header "Terraform State"
    
    cd "$TERRAFORM_DIR" || return 1
    
    # Check if state file exists
    if [[ -f "terraform.tfstate" ]]; then
        print_success "Terraform state file exists"
    else
        print_failure "Terraform state file not found"
        return 1
    fi
    
    # Count resources in state
    local resource_count=$(terraform state list 2>/dev/null | wc -l)
    if [[ $resource_count -gt 0 ]]; then
        print_success "Resources in state: $resource_count"
    else
        print_failure "No resources in state"
        return 1
    fi
    
    # Expected minimum resources
    if [[ $resource_count -ge 25 ]]; then
        print_success "Expected resource count met (≥25 resources)"
    else
        print_warning "Resource count lower than expected: $resource_count (expected ≥25)"
    fi
    
    return 0
}

################################################################################
# Function: validate_resource_group
# Description: Validate resource group
################################################################################
validate_resource_group() {
    print_test_header "Resource Group"
    
    cd "$TERRAFORM_DIR" || return 1
    
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
    
    if [[ -z "$rg_name" ]]; then
        print_failure "Resource group name not in outputs"
        return 1
    fi
    
    print_success "Resource group name: $rg_name"
    
    # Verify in Azure
    if az group show --name "$rg_name" &>/dev/null; then
        print_success "Resource group exists in Azure"
        
        local location=$(az group show --name "$rg_name" --query location -o tsv)
        print_success "Location: $location"
        
        local resource_count=$(az resource list --resource-group "$rg_name" --query "length(@)" -o tsv)
        print_success "Resources in group: $resource_count"
    else
        print_failure "Resource group not found in Azure"
        return 1
    fi
    
    return 0
}

################################################################################
# Function: validate_networking
# Description: Validate networking resources
################################################################################
validate_networking() {
    print_test_header "Networking"
    
    cd "$TERRAFORM_DIR" || return 1
    
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    local vnet_name=$(terraform output -raw vnet_name 2>/dev/null || echo "")
    
    if [[ -z "$vnet_name" ]]; then
        print_failure "VNet name not in outputs"
        return 1
    fi
    
    print_success "VNet name: $vnet_name"
    
    # Verify VNet
    if az network vnet show --resource-group "$rg_name" --name "$vnet_name" &>/dev/null; then
        print_success "VNet exists in Azure"
        
        local address_space=$(az network vnet show --resource-group "$rg_name" --name "$vnet_name" --query "addressSpace.addressPrefixes[0]" -o tsv)
        print_success "Address space: $address_space"
    else
        print_failure "VNet not found in Azure"
        return 1
    fi
    
    # Verify subnet
    local subnet_count=$(az network vnet subnet list --resource-group "$rg_name" --vnet-name "$vnet_name" --query "length(@)" -o tsv 2>/dev/null)
    if [[ $subnet_count -gt 0 ]]; then
        print_success "Subnets: $subnet_count"
    else
        print_failure "No subnets found"
        return 1
    fi
    
    # Verify NSG
    local nsg_count=$(az network nsg list --resource-group "$rg_name" --query "length(@)" -o tsv 2>/dev/null)
    if [[ $nsg_count -gt 0 ]]; then
        print_success "Network Security Groups: $nsg_count"
    else
        print_failure "No NSGs found"
        return 1
    fi
    
    return 0
}

################################################################################
# Function: validate_storage
# Description: Validate storage resources
################################################################################
validate_storage() {
    print_test_header "Storage"
    
    cd "$TERRAFORM_DIR" || return 1
    
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    local storage_account=$(terraform output -raw storage_account_name 2>/dev/null || echo "")
    
    if [[ -z "$storage_account" ]]; then
        print_failure "Storage account name not in outputs"
        return 1
    fi
    
    print_success "Storage account: $storage_account"
    
    # Verify storage account
    if az storage account show --name "$storage_account" --resource-group "$rg_name" &>/dev/null; then
        print_success "Storage account exists in Azure"
        
        local sku=$(az storage account show --name "$storage_account" --resource-group "$rg_name" --query "sku.name" -o tsv)
        print_success "SKU: $sku"
        
        # Verify file share
        local file_share_name=$(terraform output -raw file_share_name 2>/dev/null || echo "")
        if [[ -n "$file_share_name" ]]; then
            local key=$(az storage account keys list --account-name "$storage_account" --resource-group "$rg_name" --query "[0].value" -o tsv)
            if az storage share show --name "$file_share_name" --account-name "$storage_account" --account-key "$key" &>/dev/null; then
                print_success "File share exists: $file_share_name"
                
                local quota=$(az storage share show --name "$file_share_name" --account-name "$storage_account" --account-key "$key" --query "properties.quota" -o tsv)
                print_success "File share quota: ${quota}GB"
            else
                print_failure "File share not found: $file_share_name"
            fi
        fi
    else
        print_failure "Storage account not found in Azure"
        return 1
    fi
    
    return 0
}

################################################################################
# Function: validate_virtual_machines
# Description: Validate virtual machines
################################################################################
validate_virtual_machines() {
    print_test_header "Virtual Machines"
    
    cd "$TERRAFORM_DIR" || return 1
    
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    
    # Get VM list
    local vms=$(az vm list --resource-group "$rg_name" --query "[].name" -o tsv 2>/dev/null)
    local vm_count=$(echo "$vms" | wc -w)
    
    if [[ $vm_count -eq 5 ]]; then
        print_success "All 5 VMs deployed"
    elif [[ $vm_count -gt 0 ]]; then
        print_warning "Only $vm_count VMs found (expected 5)"
    else
        print_failure "No VMs found"
        return 1
    fi
    
    # Check each VM
    echo ""
    echo "VM Status:"
    for vm in $vms; do
        local power_state=$(az vm get-instance-view --resource-group "$rg_name" --name "$vm" --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" -o tsv 2>/dev/null)
        local private_ip=$(az vm show --resource-group "$rg_name" --name "$vm" --query "privateIps" -o tsv 2>/dev/null)
        
        if [[ "$power_state" == "VM running" ]]; then
            print_success "$vm: Running ($private_ip)"
        else
            print_warning "$vm: $power_state ($private_ip)"
        fi
    done
    
    # Check VM sizes
    echo ""
    echo "VM Sizes:"
    for vm in $vms; do
        local size=$(az vm show --resource-group "$rg_name" --name "$vm" --query "hardwareProfile.vmSize" -o tsv 2>/dev/null)
        echo "  - $vm: $size"
    done
    
    return 0
}

################################################################################
# Function: validate_network_connectivity
# Description: Validate network connectivity
################################################################################
validate_network_connectivity() {
    print_test_header "Network Connectivity"
    
    cd "$TERRAFORM_DIR" || return 1
    
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    
    # Check public IPs
    local public_ip_count=$(az network public-ip list --resource-group "$rg_name" --query "length(@)" -o tsv 2>/dev/null)
    if [[ $public_ip_count -eq 5 ]]; then
        print_success "All 5 public IPs allocated"
    else
        print_warning "Public IP count: $public_ip_count (expected 5)"
    fi
    
    # List public IPs
    echo ""
    echo "Public IP Addresses:"
    az network public-ip list --resource-group "$rg_name" --query "[].{Name:name, IP:ipAddress}" -o table 2>/dev/null
    
    # Check NICs
    local nic_count=$(az network nic list --resource-group "$rg_name" --query "length(@)" -o tsv 2>/dev/null)
    if [[ $nic_count -eq 5 ]]; then
        print_success "All 5 network interfaces created"
    else
        print_warning "Network interface count: $nic_count (expected 5)"
    fi
    
    return 0
}

################################################################################
# Function: validate_nsg_rules
# Description: Validate NSG rules
################################################################################
validate_nsg_rules() {
    print_test_header "NSG Rules"
    
    cd "$TERRAFORM_DIR" || return 1
    
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    
    # Get NSG name
    local nsg_name=$(az network nsg list --resource-group "$rg_name" --query "[0].name" -o tsv 2>/dev/null)
    
    if [[ -z "$nsg_name" ]]; then
        print_failure "No NSG found"
        return 1
    fi
    
    print_success "NSG: $nsg_name"
    
    # Count rules
    local rule_count=$(az network nsg rule list --resource-group "$rg_name" --nsg-name "$nsg_name" --query "length(@)" -o tsv 2>/dev/null)
    
    if [[ $rule_count -ge 30 ]]; then
        print_success "NSG rules configured: $rule_count"
    else
        print_warning "NSG rule count: $rule_count (expected ≥30)"
    fi
    
    # Check key rules
    echo ""
    echo "Key NSG Rules:"
    local ssh_rule=$(az network nsg rule show --resource-group "$rg_name" --nsg-name "$nsg_name" --name "AllowSSH" --query "name" -o tsv 2>/dev/null || echo "")
    if [[ -n "$ssh_rule" ]]; then
        echo "  ✓ SSH rule exists"
    else
        echo "  ✗ SSH rule missing"
    fi
    
    local k8s_api_rule=$(az network nsg rule show --resource-group "$rg_name" --nsg-name "$nsg_name" --name "AllowKubernetesAPI" --query "name" -o tsv 2>/dev/null || echo "")
    if [[ -n "$k8s_api_rule" ]]; then
        echo "  ✓ Kubernetes API rule exists"
    else
        echo "  ✗ Kubernetes API rule missing"
    fi
    
    return 0
}

################################################################################
# Function: validate_ssh_access
# Description: Validate SSH access to VMs
################################################################################
validate_ssh_access() {
    print_test_header "SSH Access"
    
    cd "$TERRAFORM_DIR" || return 1
    
    local rg_name=$(terraform output -raw resource_group_name 2>/dev/null)
    
    print_warning "SSH access validation requires manual testing"
    print_warning "To test SSH access, run:"
    echo ""
    
    local vms=$(az vm list --resource-group "$rg_name" --query "[].name" -o tsv 2>/dev/null)
    for vm in $vms; do
        local public_ip=$(az network public-ip list --resource-group "$rg_name" --query "[?contains(name, '${vm}')].ipAddress" -o tsv 2>/dev/null | head -n1)
        if [[ -n "$public_ip" ]]; then
            echo "  ssh beeuser@$public_ip  # $vm"
        fi
    done
    
    return 0
}

################################################################################
# Function: validate_cloud_init
# Description: Validate cloud-init execution
################################################################################
validate_cloud_init() {
    print_test_header "Cloud-Init Status"
    
    print_warning "Cloud-init validation requires SSH access to VMs"
    print_warning "After SSH access, run on each VM:"
    echo ""
    echo "  cloud-init status --wait"
    echo "  cat /var/log/cloud-init-output.log"
    echo ""
    
    return 0
}

################################################################################
# Function: validate_kubernetes_readiness
# Description: Validate Kubernetes cluster readiness
################################################################################
validate_kubernetes_readiness() {
    print_test_header "Kubernetes Cluster Readiness"
    
    print_warning "Kubernetes validation requires SSH access to master node"
    print_warning "After SSH to master, run:"
    echo ""
    echo "  kubectl get nodes"
    echo "  kubectl get pods --all-namespaces"
    echo "  kubectl cluster-info"
    echo ""
    
    return 0
}

################################################################################
# Function: print_summary
# Description: Print validation summary
################################################################################
print_summary() {
    echo ""
    echo "=========================================="
    echo "Validation Summary"
    echo "=========================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    echo -e "${YELLOW}Warnings: $WARNING_TESTS${NC}"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        if [[ $WARNING_TESTS -eq 0 ]]; then
            echo -e "${GREEN}Status: ALL CHECKS PASSED ✓${NC}"
        else
            echo -e "${YELLOW}Status: PASSED WITH WARNINGS ⚠${NC}"
        fi
    else
        echo -e "${RED}Status: SOME CHECKS FAILED ✗${NC}"
    fi
    
    echo ""
    echo "Logs: $LOG_FILE"
    echo "=========================================="
}

################################################################################
# Main execution
################################################################################
main() {
    echo ""
    echo "=========================================="
    echo "  Azure Infrastructure Validation"
    echo "=========================================="
    echo "Timestamp: $(date)"
    echo "=========================================="
    
    log_info "Starting infrastructure validation"
    
    # Run validation tests
    validate_prerequisites || true
    validate_terraform_state || true
    validate_resource_group || true
    validate_networking || true
    validate_storage || true
    validate_virtual_machines || true
    validate_network_connectivity || true
    validate_nsg_rules || true
    validate_ssh_access || true
    validate_cloud_init || true
    validate_kubernetes_readiness || true
    
    print_summary
    
    # Exit with appropriate code
    if [[ $FAILED_TESTS -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Execute main function
main "$@"
