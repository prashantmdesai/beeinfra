#!/bin/bash
# =============================================================================
# UBUNTU DEV VM 01 - MANAGEMENT SCRIPT
# =============================================================================
# Description: Start, stop, restart and manage ubuntu-dev-01 VM
# Environment: Development
# VM: ubuntu-dev-01 (Standard_B2s with Premium SSD)
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

get_vm_status() {
    print_info "Checking VM status..."
    
    VM_STATUS=$(az vm get-instance-view \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$VM_RESOURCE_NAME" \
        --query 'instanceView.statuses[1].displayStatus' \
        --output tsv 2>/dev/null || echo "Not Found")
    
    echo "$VM_STATUS"
}

show_vm_info() {
    print_header "VM INFORMATION"
    
    if ! az vm show --resource-group "$RESOURCE_GROUP_NAME" --name "$VM_RESOURCE_NAME" &> /dev/null; then
        print_error "VM $VM_RESOURCE_NAME not found in resource group $RESOURCE_GROUP_NAME"
        exit 1
    fi
    
    VM_INFO=$(az vm show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$VM_RESOURCE_NAME" \
        --show-details \
        --output json)
    
    VM_STATUS=$(echo "$VM_INFO" | jq -r '.powerState // "Unknown"')
    VM_SIZE=$(echo "$VM_INFO" | jq -r '.hardwareProfile.vmSize // "Unknown"')
    PRIVATE_IP=$(echo "$VM_INFO" | jq -r '.privateIps[0] // "N/A"')
    PUBLIC_IP=$(echo "$VM_INFO" | jq -r '.publicIps // "N/A"')
    OS_DISK_SIZE=$(echo "$VM_INFO" | jq -r '.storageProfile.osDisk.diskSizeGb // "Unknown"')
    
    echo "─────────────────────────────────────────────────"
    echo "  • VM Name:           $VM_NAME"
    echo "  • Resource Name:     $VM_RESOURCE_NAME"
    echo "  • Status:            $VM_STATUS"
    echo "  • VM Size:           $VM_SIZE"
    echo "  • Private IP:        $PRIVATE_IP"
    echo "  • Public IP:         $PUBLIC_IP"
    echo "  • OS Disk Size:      ${OS_DISK_SIZE}GB"
    echo "  • Resource Group:    $RESOURCE_GROUP_NAME"
    echo "─────────────────────────────────────────────────"
}

start_vm() {
    print_header "STARTING VM"
    
    STATUS=$(get_vm_status)
    
    if [[ "$STATUS" == "VM running" ]]; then
        print_warning "VM is already running"
        return 0
    fi
    
    # Show cost warning
    echo -e "${YELLOW}Cost Warning:${NC}"
    echo "  • Hourly Cost: ~$0.056/hour"
    echo "  • Daily Cost:  ~$1.34/day"
    echo ""
    
    read -p "Do you want to start the VM? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "VM start cancelled by user"
        return 0
    fi
    
    print_info "Starting VM: $VM_RESOURCE_NAME"
    az vm start \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$VM_RESOURCE_NAME" \
        --no-wait
    
    print_success "VM start initiated"
    print_info "VM will be ready in a few minutes"
}

stop_vm() {
    print_header "STOPPING VM"
    
    STATUS=$(get_vm_status)
    
    if [[ "$STATUS" == "VM deallocated" ]] || [[ "$STATUS" == "VM stopped" ]]; then
        print_warning "VM is already stopped/deallocated"
        return 0
    fi
    
    print_info "Stopping VM: $VM_RESOURCE_NAME"
    print_info "This will deallocate the VM to stop compute charges"
    
    read -p "Do you want to stop and deallocate the VM? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "VM stop cancelled by user"
        return 0
    fi
    
    az vm deallocate \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$VM_RESOURCE_NAME" \
        --no-wait
    
    print_success "VM stop/deallocation initiated"
    print_info "Compute charges will stop once VM is fully deallocated"
}

restart_vm() {
    print_header "RESTARTING VM"
    
    STATUS=$(get_vm_status)
    
    if [[ "$STATUS" != "VM running" ]]; then
        print_error "VM is not running. Current status: $STATUS"
        print_info "Use 'start' command to start the VM first"
        return 1
    fi
    
    print_info "Restarting VM: $VM_RESOURCE_NAME"
    
    read -p "Do you want to restart the VM? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "VM restart cancelled by user"
        return 0
    fi
    
    az vm restart \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$VM_RESOURCE_NAME" \
        --no-wait
    
    print_success "VM restart initiated"
}

connect_ssh() {
    print_header "SSH CONNECTION"
    
    STATUS=$(get_vm_status)
    
    if [[ "$STATUS" != "VM running" ]]; then
        print_error "VM is not running. Current status: $STATUS"
        print_info "Use 'start' command to start the VM first"
        return 1
    fi
    
    print_info "Getting VM connection information..."
    
    PUBLIC_IP=$(az vm show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$VM_RESOURCE_NAME" \
        --show-details \
        --query 'publicIps' \
        --output tsv)
    
    if [[ -z "$PUBLIC_IP" || "$PUBLIC_IP" == "None" ]]; then
        print_error "No public IP found for VM"
        return 1
    fi
    
    SSH_COMMAND="ssh beeuser@$PUBLIC_IP"
    
    print_info "VM is ready for SSH connection"
    echo "  • Public IP:     $PUBLIC_IP"
    echo "  • SSH Command:   $SSH_COMMAND"
    echo ""
    
    read -p "Do you want to connect now? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Connecting to VM..."
        eval "$SSH_COMMAND"
    else
        print_info "Connection cancelled. Use this command to connect later:"
        echo "  $SSH_COMMAND"
    fi
}

show_help() {
    echo "Ubuntu Dev VM 01 Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  info      Show VM information and status"
    echo "  start     Start the VM"
    echo "  stop      Stop and deallocate the VM"
    echo "  restart   Restart the VM"
    echo "  connect   Connect to VM via SSH"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 info                 # Show VM status"
    echo "  $0 start                # Start the VM"
    echo "  $0 connect              # SSH to the VM"
    echo "  $0 stop                 # Stop the VM"
    echo ""
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    check_prerequisites
    
    case "${1:-}" in
        "info"|"status")
            show_vm_info
            ;;
        "start")
            start_vm
            ;;
        "stop")
            stop_vm
            ;;
        "restart")
            restart_vm
            ;;
        "connect"|"ssh")
            connect_ssh
            ;;
        "help"|"-h"|"--help"|"")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
