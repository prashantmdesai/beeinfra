#!/bin/bash
# =============================================================================
# DEV ENVIRONMENT - BULK VM MANAGEMENT SCRIPT
# =============================================================================
# Description: Manage multiple VMs in the dev environment
# Environment: Development
# Purpose: Start, stop, restart all VMs or specific VMs
# =============================================================================

set -e  # Exit on any error

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENT="dev"
RESOURCE_GROUP_NAME="beeinfra-${ENVIRONMENT}-rg"
VMS_DIR="$(dirname "$SCRIPT_DIR")/vms"

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

get_available_vms() {
    if [[ ! -d "$VMS_DIR" ]]; then
        echo ""
        return
    fi
    
    find "$VMS_DIR" -maxdepth 1 -type d -name "ubuntu-*" -exec basename {} \; | sort
}

list_vms() {
    print_header "AVAILABLE VMS IN DEV ENVIRONMENT"
    
    VMS=($(get_available_vms))
    
    if [[ ${#VMS[@]} -eq 0 ]]; then
        print_warning "No VM configurations found in $VMS_DIR"
        return
    fi
    
    print_info "Found ${#VMS[@]} VM configuration(s):"
    for vm in "${VMS[@]}"; do
        VM_RESOURCE_NAME="beeinfra-${ENVIRONMENT}-${vm}"
        
        # Check if VM exists in Azure
        if az vm show --resource-group "$RESOURCE_GROUP_NAME" --name "$VM_RESOURCE_NAME" &> /dev/null; then
            STATUS=$(az vm get-instance-view \
                --resource-group "$RESOURCE_GROUP_NAME" \
                --name "$VM_RESOURCE_NAME" \
                --query 'instanceView.statuses[1].displayStatus' \
                --output tsv 2>/dev/null || echo "Unknown")
            
            if [[ "$STATUS" == "VM running" ]]; then
                echo -e "  • ${GREEN}$vm${NC} (${GREEN}Running${NC})"
            elif [[ "$STATUS" == "VM deallocated" ]]; then
                echo -e "  • ${YELLOW}$vm${NC} (${YELLOW}Stopped${NC})"
            else
                echo -e "  • ${BLUE}$vm${NC} (${BLUE}$STATUS${NC})"
            fi
        else
            echo -e "  • ${RED}$vm${NC} (${RED}Not Deployed${NC})"
        fi
    done
}

show_cost_estimate() {
    VMS=($(get_available_vms))
    DEPLOYED_COUNT=0
    
    for vm in "${VMS[@]}"; do
        VM_RESOURCE_NAME="beeinfra-${ENVIRONMENT}-${vm}"
        if az vm show --resource-group "$RESOURCE_GROUP_NAME" --name "$VM_RESOURCE_NAME" &> /dev/null; then
            ((DEPLOYED_COUNT++))
        fi
    done
    
    if [[ $DEPLOYED_COUNT -eq 0 ]]; then
        print_info "No VMs are currently deployed"
        return
    fi
    
    echo -e "${YELLOW}Cost Estimate for Running VMs:${NC}"
    echo "  • Per VM (Standard_B2s):  ~$0.056/hour"
    echo "  • Deployed VMs:           $DEPLOYED_COUNT"
    echo "  • Total Hourly:           \$$(echo "$DEPLOYED_COUNT * 0.056" | bc -l | xargs printf "%.3f")"
    echo "  • Total Daily:            \$$(echo "$DEPLOYED_COUNT * 0.056 * 24" | bc -l | xargs printf "%.2f")"
    echo "  • Total Monthly:          \$$(echo "$DEPLOYED_COUNT * 40.16" | bc -l | xargs printf "%.2f")"
    echo ""
}

start_all_vms() {
    print_header "STARTING ALL VMS"
    
    VMS=($(get_available_vms))
    
    if [[ ${#VMS[@]} -eq 0 ]]; then
        print_warning "No VMs found to start"
        return
    fi
    
    show_cost_estimate
    
    read -p "Do you want to start ALL VMs in the dev environment? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Operation cancelled by user"
        return
    fi
    
    STARTED_COUNT=0
    for vm in "${VMS[@]}"; do
        VM_RESOURCE_NAME="beeinfra-${ENVIRONMENT}-${vm}"
        
        if az vm show --resource-group "$RESOURCE_GROUP_NAME" --name "$VM_RESOURCE_NAME" &> /dev/null; then
            STATUS=$(az vm get-instance-view \
                --resource-group "$RESOURCE_GROUP_NAME" \
                --name "$VM_RESOURCE_NAME" \
                --query 'instanceView.statuses[1].displayStatus' \
                --output tsv 2>/dev/null || echo "Unknown")
            
            if [[ "$STATUS" != "VM running" ]]; then
                print_info "Starting VM: $vm"
                az vm start \
                    --resource-group "$RESOURCE_GROUP_NAME" \
                    --name "$VM_RESOURCE_NAME" \
                    --no-wait
                ((STARTED_COUNT++))
            else
                print_info "VM $vm is already running"
            fi
        else
            print_warning "VM $vm is not deployed - skipping"
        fi
    done
    
    if [[ $STARTED_COUNT -gt 0 ]]; then
        print_success "Started $STARTED_COUNT VM(s)"
        print_info "VMs will be ready in a few minutes"
    else
        print_info "No VMs needed to be started"
    fi
}

stop_all_vms() {
    print_header "STOPPING ALL VMS"
    
    VMS=($(get_available_vms))
    
    if [[ ${#VMS[@]} -eq 0 ]]; then
        print_warning "No VMs found to stop"
        return
    fi
    
    print_warning "This will stop and deallocate ALL running VMs in the dev environment"
    print_info "This will stop all compute charges for these VMs"
    
    read -p "Do you want to stop ALL VMs? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Operation cancelled by user"
        return
    fi
    
    STOPPED_COUNT=0
    for vm in "${VMS[@]}"; do
        VM_RESOURCE_NAME="beeinfra-${ENVIRONMENT}-${vm}"
        
        if az vm show --resource-group "$RESOURCE_GROUP_NAME" --name "$VM_RESOURCE_NAME" &> /dev/null; then
            STATUS=$(az vm get-instance-view \
                --resource-group "$RESOURCE_GROUP_NAME" \
                --name "$VM_RESOURCE_NAME" \
                --query 'instanceView.statuses[1].displayStatus' \
                --output tsv 2>/dev/null || echo "Unknown")
            
            if [[ "$STATUS" == "VM running" ]]; then
                print_info "Stopping VM: $vm"
                az vm deallocate \
                    --resource-group "$RESOURCE_GROUP_NAME" \
                    --name "$VM_RESOURCE_NAME" \
                    --no-wait
                ((STOPPED_COUNT++))
            else
                print_info "VM $vm is already stopped"
            fi
        else
            print_warning "VM $vm is not deployed - skipping"
        fi
    done
    
    if [[ $STOPPED_COUNT -gt 0 ]]; then
        print_success "Initiated stop for $STOPPED_COUNT VM(s)"
        print_info "Compute charges will stop once VMs are fully deallocated"
    else
        print_info "No VMs needed to be stopped"
    fi
}

restart_all_vms() {
    print_header "RESTARTING ALL VMS"
    
    VMS=($(get_available_vms))
    
    if [[ ${#VMS[@]} -eq 0 ]]; then
        print_warning "No VMs found to restart"
        return
    fi
    
    read -p "Do you want to restart ALL running VMs? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Operation cancelled by user"
        return
    fi
    
    RESTARTED_COUNT=0
    for vm in "${VMS[@]}"; do
        VM_RESOURCE_NAME="beeinfra-${ENVIRONMENT}-${vm}"
        
        if az vm show --resource-group "$RESOURCE_GROUP_NAME" --name "$VM_RESOURCE_NAME" &> /dev/null; then
            STATUS=$(az vm get-instance-view \
                --resource-group "$RESOURCE_GROUP_NAME" \
                --name "$VM_RESOURCE_NAME" \
                --query 'instanceView.statuses[1].displayStatus' \
                --output tsv 2>/dev/null || echo "Unknown")
            
            if [[ "$STATUS" == "VM running" ]]; then
                print_info "Restarting VM: $vm"
                az vm restart \
                    --resource-group "$RESOURCE_GROUP_NAME" \
                    --name "$VM_RESOURCE_NAME" \
                    --no-wait
                ((RESTARTED_COUNT++))
            else
                print_warning "VM $vm is not running - skipping"
            fi
        else
            print_warning "VM $vm is not deployed - skipping"
        fi
    done
    
    if [[ $RESTARTED_COUNT -gt 0 ]]; then
        print_success "Initiated restart for $RESTARTED_COUNT VM(s)"
    else
        print_info "No running VMs found to restart"
    fi
}

manage_specific_vm() {
    local vm_name="$1"
    local action="$2"
    
    VM_SCRIPT_PATH="$VMS_DIR/$vm_name/scripts/manage.sh"
    
    if [[ ! -f "$VM_SCRIPT_PATH" ]]; then
        print_error "Management script not found for VM: $vm_name"
        print_info "Expected location: $VM_SCRIPT_PATH"
        return 1
    fi
    
    print_info "Executing $action for VM: $vm_name"
    bash "$VM_SCRIPT_PATH" "$action"
}

show_help() {
    echo "Dev Environment VM Management Script"
    echo ""
    echo "Usage: $0 [COMMAND] [VM_NAME]"
    echo ""
    echo "Commands:"
    echo "  list              List all VMs and their status"
    echo "  start-all         Start all deployed VMs"
    echo "  stop-all          Stop all running VMs"
    echo "  restart-all       Restart all running VMs"
    echo "  start <vm-name>   Start a specific VM"
    echo "  stop <vm-name>    Stop a specific VM"
    echo "  restart <vm-name> Restart a specific VM"
    echo "  info <vm-name>    Show info for a specific VM"
    echo "  help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 list                      # Show all VMs and status"
    echo "  $0 start-all                 # Start all VMs"
    echo "  $0 stop ubuntu-dev-01        # Stop specific VM"
    echo "  $0 info ubuntu-dev-01        # Show VM info"
    echo ""
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    check_prerequisites
    
    case "${1:-}" in
        "list"|"status")
            list_vms
            echo ""
            show_cost_estimate
            ;;
        "start-all")
            start_all_vms
            ;;
        "stop-all")
            stop_all_vms
            ;;
        "restart-all")
            restart_all_vms
            ;;
        "start"|"stop"|"restart"|"info")
            if [[ -z "${2:-}" ]]; then
                print_error "VM name is required for command: $1"
                echo ""
                show_help
                exit 1
            fi
            manage_specific_vm "$2" "$1"
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
