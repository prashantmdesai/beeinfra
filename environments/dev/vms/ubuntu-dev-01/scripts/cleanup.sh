#!/bin/bash
# =============================================================================
# UBUNTU DEV VM 01 - CLEANUP SCRIPT
# =============================================================================
# Description: Delete ubuntu-dev-01 VM and all associated resources
# Environment: Development
# VM: ubuntu-dev-01 (Standard_B2s with Premium SSD)
# WARNING: This script will PERMANENTLY DELETE the VM and all data
# =============================================================================

set -e  # Exit on any error

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_NAME="ubuntu-dev-01"
ENVIRONMENT="dev"
RESOURCE_GROUP_NAME="beeinfra-${ENVIRONMENT}-rg"
VM_RESOURCE_NAME="beeinfra-${ENVIRONMENT}-${VM_NAME}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# FUNCTIONS
# =============================================================================

print_header() {
    echo -e "${BLUE}=============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=============================================================================${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if logged into Azure
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure. Please login first."
        print_info "Run: az login"
        exit 1
    fi
}

show_warning() {
    print_header "⚠️  DANGER ZONE ⚠️"
    echo -e "${RED}WARNING: This will PERMANENTLY DELETE the following VM and ALL associated resources:${NC}"
    echo ""
    echo "  • VM Name:           $VM_NAME"
    echo "  • Resource Name:     $VM_RESOURCE_NAME"
    echo "  • Resource Group:    $RESOURCE_GROUP_NAME"
    echo "  • Environment:       $ENVIRONMENT"
    echo ""
    echo -e "${RED}The following resources will be DELETED:${NC}"
    echo "  • Virtual Machine (including OS disk)"
    echo "  • Network Interface"
    echo "  • Public IP Address"
    echo "  • Network Security Group"
    echo "  • Virtual Network (if not shared)"
    echo ""
    echo -e "${RED}ALL DATA ON THE VM WILL BE LOST${NC}"
    echo -e "${YELLOW}This action CANNOT be undone${NC}"
    echo ""
}

confirm_deletion() {
    show_warning
    
    # First confirmation
    echo -e "${YELLOW}Please type the VM name '${VM_NAME}' to confirm deletion:${NC}"
    read -p "> " -r
    if [[ "$REPLY" != "$VM_NAME" ]]; then
        print_info "VM name doesn't match. Deletion cancelled."
        exit 0
    fi
    
    # Second confirmation
    echo -e "${YELLOW}Are you absolutely sure you want to DELETE this VM? Type 'DELETE' to confirm:${NC}"
    read -p "> " -r
    if [[ "$REPLY" != "DELETE" ]]; then
        print_info "Deletion cancelled by user"
        exit 0
    fi
    
    # Final confirmation
    echo -e "${RED}FINAL WARNING: This will permanently delete VM '${VM_NAME}' and all data${NC}"
    read -p "Type 'YES I AM SURE' to proceed: " -r
    if [[ "$REPLY" != "YES I AM SURE" ]]; then
        print_info "Deletion cancelled by user"
        exit 0
    fi
    
    print_warning "Proceeding with VM deletion..."
}

check_vm_exists() {
    print_header "CHECKING VM EXISTENCE"
    
    if ! az vm show --resource-group "$RESOURCE_GROUP_NAME" --name "$VM_RESOURCE_NAME" &> /dev/null; then
        print_warning "VM $VM_RESOURCE_NAME not found in resource group $RESOURCE_GROUP_NAME"
        print_info "VM may already be deleted or never existed"
        exit 0
    fi
    
    print_info "VM found: $VM_RESOURCE_NAME"
}

list_vm_resources() {
    print_header "IDENTIFYING ASSOCIATED RESOURCES"
    
    print_info "Finding all resources associated with VM: $VM_RESOURCE_NAME"
    
    # Get VM details
    VM_INFO=$(az vm show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$VM_RESOURCE_NAME" \
        --output json)
    
    # Extract resource IDs
    NIC_ID=$(echo "$VM_INFO" | jq -r '.networkProfile.networkInterfaces[0].id')
    OS_DISK_NAME=$(echo "$VM_INFO" | jq -r '.storageProfile.osDisk.name')
    
    # Get NIC details
    if [[ "$NIC_ID" != "null" ]]; then
        NIC_INFO=$(az network nic show --ids "$NIC_ID" --output json)
        PUBLIC_IP_ID=$(echo "$NIC_INFO" | jq -r '.ipConfigurations[0].publicIPAddress.id // empty')
        NSG_ID=$(echo "$NIC_INFO" | jq -r '.networkSecurityGroup.id // empty')
        VNET_ID=$(echo "$NIC_INFO" | jq -r '.ipConfigurations[0].subnet.id' | sed 's|/subnets/.*||')
    fi
    
    echo "Resources to be deleted:"
    echo "  • VM:                    $VM_RESOURCE_NAME"
    echo "  • OS Disk:               $OS_DISK_NAME"
    [[ -n "$NIC_ID" ]] && echo "  • Network Interface:     $(basename "$NIC_ID")"
    [[ -n "$PUBLIC_IP_ID" ]] && echo "  • Public IP:             $(basename "$PUBLIC_IP_ID")"
    [[ -n "$NSG_ID" ]] && echo "  • Network Security Group: $(basename "$NSG_ID")"
    echo ""
    print_warning "Virtual Network will be preserved as it may be shared with other VMs"
}

delete_vm() {
    print_header "DELETING VIRTUAL MACHINE"
    
    print_info "Deleting VM: $VM_RESOURCE_NAME"
    print_info "This may take several minutes..."
    
    az vm delete \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$VM_RESOURCE_NAME" \
        --yes \
        --force-deletion true
    
    print_success "Virtual Machine deleted successfully"
}

delete_associated_resources() {
    print_header "CLEANING UP ASSOCIATED RESOURCES"
    
    # Delete OS disk
    print_info "Deleting OS disk: $OS_DISK_NAME"
    az disk delete \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$OS_DISK_NAME" \
        --yes \
        --no-wait || print_warning "OS disk may already be deleted"
    
    # Delete Network Interface
    if [[ -n "$NIC_ID" ]]; then
        print_info "Deleting Network Interface: $(basename "$NIC_ID")"
        az network nic delete --ids "$NIC_ID" --no-wait || print_warning "NIC may already be deleted"
    fi
    
    # Delete Public IP
    if [[ -n "$PUBLIC_IP_ID" ]]; then
        print_info "Deleting Public IP: $(basename "$PUBLIC_IP_ID")"
        az network public-ip delete --ids "$PUBLIC_IP_ID" --no-wait || print_warning "Public IP may already be deleted"
    fi
    
    # Delete Network Security Group
    if [[ -n "$NSG_ID" ]]; then
        print_info "Deleting Network Security Group: $(basename "$NSG_ID")"
        az network nsg delete --ids "$NSG_ID" --no-wait || print_warning "NSG may already be deleted"
    fi
    
    print_success "Associated resources cleanup initiated"
    print_info "Some resources may take a few minutes to be fully deleted"
}

show_cleanup_summary() {
    print_header "CLEANUP SUMMARY"
    
    echo -e "${GREEN}VM Deletion Completed Successfully!${NC}"
    echo "─────────────────────────────────────────────────"
    echo "  • VM Name:           $VM_NAME (DELETED)"
    echo "  • Resource Name:     $VM_RESOURCE_NAME (DELETED)"
    echo "  • Cost Savings:      ~$40.16/month"
    echo "  • Hourly Savings:    ~$0.056/hour"
    echo "─────────────────────────────────────────────────"
    echo ""
    print_info "All compute charges for this VM have stopped"
    print_info "Storage charges will stop once disk deletion completes"
    echo ""
    print_warning "To recreate this VM, run the deployment script again:"
    echo "  $SCRIPT_DIR/deploy.sh"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "UBUNTU DEV VM 01 - CLEANUP"
    
    check_prerequisites
    check_vm_exists
    list_vm_resources
    confirm_deletion
    delete_vm
    delete_associated_resources
    show_cleanup_summary
    
    print_success "VM cleanup process completed!"
}

# Execute main function
main "$@"
