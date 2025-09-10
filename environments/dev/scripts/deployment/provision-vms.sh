#!/bin/bash
# =============================================================================
# DEV ENVIRONMENT - VM PROVISIONING SCRIPT
# =============================================================================
# Description: Deploy multiple VMs based on naming convention
# Environment: Development
# Purpose: Scalable VM deployment for up to 40 VMs
# =============================================================================

set -e  # Exit on any error

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENT="dev"
RESOURCE_GROUP_NAME="beeinfra-${ENVIRONMENT}-rg"
VMS_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/vms"
LOCATION="eastus"  # Change this to your preferred Azure region

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

create_vm_directory() {
    local vm_name="$1"
    local vm_dir="$VMS_DIR/$vm_name"
    
    print_info "Creating directory structure for VM: $vm_name"
    
    # Create VM directory structure
    mkdir -p "$vm_dir/bicep"
    mkdir -p "$vm_dir/scripts"
    
    # Copy template files from ubuntu-dev-01
    local template_dir="$VMS_DIR/ubuntu-dev-01"
    
    if [[ -d "$template_dir" ]]; then
        # Copy and customize Bicep template
        cp "$template_dir/bicep/main.bicep" "$vm_dir/bicep/main.bicep"
        
        # Update VM name in parameters
        cat "$template_dir/bicep/parameters.json" | \
            jq --arg vmname "$vm_name" '.parameters.vmName.value = $vmname' > \
            "$vm_dir/bicep/parameters.json"
        
        # Copy and customize scripts
        for script in deploy.sh manage.sh cleanup.sh; do
            cp "$template_dir/scripts/$script" "$vm_dir/scripts/$script"
            
            # Update VM name in scripts
            sed -i "s/VM_NAME=\"ubuntu-dev-01\"/VM_NAME=\"$vm_name\"/g" "$vm_dir/scripts/$script"
            sed -i "s/ubuntu-dev-01/$vm_name/g" "$vm_dir/scripts/$script"
        done
        
        print_success "Created directory structure for VM: $vm_name"
    else
        print_error "Template directory not found: $template_dir"
        print_info "Please ensure ubuntu-dev-01 exists as a template"
        return 1
    fi
}

generate_vm_name() {
    local vm_number="$1"
    printf "ubuntu-dev-%02d" "$vm_number"
}

create_resource_group() {
    print_header "CREATING RESOURCE GROUP"
    
    if az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_success "Resource group $RESOURCE_GROUP_NAME already exists"
    else
        print_info "Creating resource group: $RESOURCE_GROUP_NAME"
        az group create \
            --name "$RESOURCE_GROUP_NAME" \
            --location "$LOCATION" \
            --tags \
                Environment="$ENVIRONMENT" \
                Purpose="Development Infrastructure" \
                CreatedBy="provisioning-script" \
                CreatedOn="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        
        print_success "Resource group created successfully"
    fi
}

provision_single_vm() {
    local vm_name="$1"
    local vm_dir="$VMS_DIR/$vm_name"
    
    print_header "PROVISIONING VM: $vm_name"
    
    # Check if VM directory exists
    if [[ ! -d "$vm_dir" ]]; then
        print_warning "VM directory doesn't exist. Creating it..."
        create_vm_directory "$vm_name"
    fi
    
    # Check if deployment script exists
    local deploy_script="$vm_dir/scripts/deploy.sh"
    if [[ ! -f "$deploy_script" ]]; then
        print_error "Deploy script not found: $deploy_script"
        return 1
    fi
    
    # Execute deployment script
    print_info "Executing deployment script for $vm_name"
    bash "$deploy_script"
    
    if [[ $? -eq 0 ]]; then
        print_success "Successfully provisioned VM: $vm_name"
    else
        print_error "Failed to provision VM: $vm_name"
        return 1
    fi
}

provision_multiple_vms() {
    local start_num="$1"
    local end_num="$2"
    
    print_header "BULK VM PROVISIONING"
    
    local vm_count=$((end_num - start_num + 1))
    local estimated_cost=$(echo "$vm_count * 40.16" | bc -l)
    
    echo -e "${YELLOW}Bulk Provisioning Details:${NC}"
    echo "  • VM Range:          ubuntu-dev-$(printf "%02d" "$start_num") to ubuntu-dev-$(printf "%02d" "$end_num")"
    echo "  • Number of VMs:     $vm_count"
    echo "  • Estimated Cost:    \$${estimated_cost}/month"
    echo "  • Environment:       $ENVIRONMENT"
    echo ""
    
    read -p "Do you want to provision $vm_count VMs? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Bulk provisioning cancelled by user"
        return 0
    fi
    
    local success_count=0
    local failed_count=0
    
    for ((i=start_num; i<=end_num; i++)); do
        local vm_name=$(generate_vm_name "$i")
        
        print_info "Provisioning VM $((i - start_num + 1)) of $vm_count: $vm_name"
        
        if provision_single_vm "$vm_name"; then
            ((success_count++))
        else
            ((failed_count++))
            print_warning "Continuing with next VM..."
        fi
        
        # Add delay between deployments to avoid conflicts
        if [[ $i -lt $end_num ]]; then
            print_info "Waiting 30 seconds before next deployment..."
            sleep 30
        fi
    done
    
    print_header "BULK PROVISIONING SUMMARY"
    echo -e "${GREEN}Successfully provisioned: $success_count VMs${NC}"
    if [[ $failed_count -gt 0 ]]; then
        echo -e "${RED}Failed to provision: $failed_count VMs${NC}"
    fi
    
    local actual_cost=$(echo "$success_count * 40.16" | bc -l)
    echo "  • Monthly cost: \$${actual_cost}"
}

create_vm_config() {
    local vm_name="$1"
    
    if [[ -z "$vm_name" ]]; then
        echo "Enter VM name (e.g., ubuntu-dev-05):"
        read -p "> " vm_name
    fi
    
    if [[ ! "$vm_name" =~ ^ubuntu-dev-[0-9]{2}$ ]]; then
        print_error "Invalid VM name format. Use: ubuntu-dev-XX (e.g., ubuntu-dev-05)"
        return 1
    fi
    
    local vm_dir="$VMS_DIR/$vm_name"
    
    if [[ -d "$vm_dir" ]]; then
        print_warning "VM configuration already exists: $vm_name"
        read -p "Do you want to overwrite it? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            print_info "Operation cancelled"
            return 0
        fi
    fi
    
    create_vm_directory "$vm_name"
    print_success "VM configuration created: $vm_name"
    print_info "You can now deploy it using: $0 deploy $vm_name"
}

show_help() {
    echo "Dev Environment VM Provisioning Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  create <vm-name>              Create VM configuration (e.g., ubuntu-dev-05)"
    echo "  deploy <vm-name>              Deploy a specific VM"
    echo "  bulk <start-num> <end-num>    Deploy multiple VMs (e.g., bulk 2 5)"
    echo "  help                          Show this help message"
    echo ""
    echo "VM Naming Convention:"
    echo "  • ubuntu-dev-01, ubuntu-dev-02, ..., ubuntu-dev-40"
    echo "  • Always use 2-digit numbers (01, 02, 03, etc.)"
    echo ""
    echo "Examples:"
    echo "  $0 create ubuntu-dev-02       # Create config for VM 02"
    echo "  $0 deploy ubuntu-dev-01       # Deploy single VM"
    echo "  $0 bulk 2 5                   # Deploy VMs 02-05"
    echo "  $0 bulk 10 15                 # Deploy VMs 10-15"
    echo ""
    echo "Cost Information:"
    echo "  • Per VM: ~$40.16/month (~$0.056/hour)"
    echo "  • 10 VMs: ~$401.60/month"
    echo "  • 40 VMs: ~$1,606.40/month"
    echo ""
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    check_prerequisites
    
    case "${1:-}" in
        "create")
            create_vm_config "${2:-}"
            ;;
        "deploy")
            if [[ -z "${2:-}" ]]; then
                print_error "VM name is required for deployment"
                echo ""
                show_help
                exit 1
            fi
            create_resource_group
            provision_single_vm "$2"
            ;;
        "bulk")
            if [[ -z "${2:-}" || -z "${3:-}" ]]; then
                print_error "Start and end numbers are required for bulk deployment"
                echo ""
                show_help
                exit 1
            fi
            
            if ! [[ "$2" =~ ^[0-9]+$ && "$3" =~ ^[0-9]+$ ]]; then
                print_error "Start and end numbers must be integers"
                exit 1
            fi
            
            if [[ "$2" -gt "$3" ]]; then
                print_error "Start number cannot be greater than end number"
                exit 1
            fi
            
            if [[ "$3" -gt 40 ]]; then
                print_error "Maximum supported VMs is 40 (ubuntu-dev-40)"
                exit 1
            fi
            
            create_resource_group
            provision_multiple_vms "$2" "$3"
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
