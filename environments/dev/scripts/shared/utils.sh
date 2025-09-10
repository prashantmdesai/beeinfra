#!/bin/bash
# =============================================================================
# DEV ENVIRONMENT - SHARED UTILITIES
# =============================================================================
# Description: Common functions and utilities for VM management
# Environment: Development
# Purpose: Shared functions used across multiple scripts
# =============================================================================

# Color codes for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export NC='\033[0m' # No Color

# Environment configuration
export ENVIRONMENT="dev"
export RESOURCE_GROUP_NAME="beeinfra-${ENVIRONMENT}-rg"
export LOCATION="eastus"
export VM_SIZE="Standard_B2s"
export OS_DISK_TYPE="Premium_LRS"
export OS_DISK_SIZE="30"
export UBUNTU_VERSION="24.04-LTS"

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

print_header() {
    echo -e "${BLUE}=============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=============================================================================${NC}"
}

print_subheader() {
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
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

print_debug() {
    if [[ "${DEBUG:-}" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1"
    fi
}

# =============================================================================
# AZURE UTILITY FUNCTIONS
# =============================================================================

check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        print_info "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        return 1
    fi
    return 0
}

check_azure_login() {
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure. Please login first."
        print_info "Run: az login"
        return 1
    fi
    return 0
}

check_azure_prerequisites() {
    check_azure_cli || return 1
    check_azure_login || return 1
    return 0
}

get_current_subscription() {
    az account show --query 'name' --output tsv 2>/dev/null || echo "Unknown"
}

get_current_subscription_id() {
    az account show --query 'id' --output tsv 2>/dev/null || echo "Unknown"
}

# =============================================================================
# VM UTILITY FUNCTIONS
# =============================================================================

validate_vm_name() {
    local vm_name="$1"
    
    if [[ ! "$vm_name" =~ ^ubuntu-dev-[0-9]{2}$ ]]; then
        print_error "Invalid VM name format: $vm_name"
        print_info "Expected format: ubuntu-dev-XX (e.g., ubuntu-dev-01, ubuntu-dev-15)"
        return 1
    fi
    
    local vm_number="${vm_name#ubuntu-dev-}"
    if [[ "$vm_number" -lt 1 || "$vm_number" -gt 40 ]]; then
        print_error "VM number must be between 01 and 40"
        return 1
    fi
    
    return 0
}

get_vm_resource_name() {
    local vm_name="$1"
    echo "beeinfra-${ENVIRONMENT}-${vm_name}"
}

get_vm_status() {
    local vm_name="$1"
    local vm_resource_name=$(get_vm_resource_name "$vm_name")
    
    az vm get-instance-view \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$vm_resource_name" \
        --query 'instanceView.statuses[1].displayStatus' \
        --output tsv 2>/dev/null || echo "Not Found"
}

vm_exists() {
    local vm_name="$1"
    local vm_resource_name=$(get_vm_resource_name "$vm_name")
    
    az vm show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$vm_resource_name" \
        &> /dev/null
}

get_vm_public_ip() {
    local vm_name="$1"
    local vm_resource_name=$(get_vm_resource_name "$vm_name")
    
    az vm show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$vm_resource_name" \
        --show-details \
        --query 'publicIps' \
        --output tsv 2>/dev/null || echo "N/A"
}

get_vm_private_ip() {
    local vm_name="$1"
    local vm_resource_name=$(get_vm_resource_name "$vm_name")
    
    az vm show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$vm_resource_name" \
        --show-details \
        --query 'privateIps[0]' \
        --output tsv 2>/dev/null || echo "N/A"
}

# =============================================================================
# COST CALCULATION FUNCTIONS
# =============================================================================

calculate_vm_hourly_cost() {
    # Standard_B2s pricing (pay-as-you-go)
    # VM: $0.0416/hour, Premium SSD: $0.00845/hour, Public IP: $0.005/hour
    echo "0.056"
}

calculate_vm_monthly_cost() {
    # VM: $30.37, Premium SSD: $6.14, Public IP: $3.65
    echo "40.16"
}

calculate_total_cost() {
    local vm_count="$1"
    local period="$2"  # hourly or monthly
    
    if [[ "$period" == "hourly" ]]; then
        local per_vm_cost=$(calculate_vm_hourly_cost)
    else
        local per_vm_cost=$(calculate_vm_monthly_cost)
    fi
    
    echo "$vm_count * $per_vm_cost" | bc -l | xargs printf "%.2f"
}

show_cost_breakdown() {
    local vm_count="${1:-1}"
    
    echo -e "${YELLOW}Cost Breakdown (per VM):${NC}"
    echo "  • Standard_B2s VM:      $30.37/month ($0.0416/hour)"
    echo "  • Premium SSD (30GB):   $6.14/month ($0.00845/hour)"
    echo "  • Static Public IP:     $3.65/month ($0.005/hour)"
    echo "  • Network (minimal):    $0.00/month"
    echo "  ─────────────────────────────────────────────"
    echo "  • Total per VM:         $40.16/month ($0.056/hour)"
    
    if [[ "$vm_count" -gt 1 ]]; then
        local total_monthly=$(calculate_total_cost "$vm_count" "monthly")
        local total_hourly=$(calculate_total_cost "$vm_count" "hourly")
        echo ""
        echo -e "${YELLOW}Total for $vm_count VMs:${NC}"
        echo "  • Monthly Cost:         \$${total_monthly}"
        echo "  • Hourly Cost:          \$${total_hourly}"
    fi
}

# =============================================================================
# RESOURCE GROUP FUNCTIONS
# =============================================================================

create_resource_group() {
    if az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_info "Resource group $RESOURCE_GROUP_NAME already exists"
        return 0
    fi
    
    print_info "Creating resource group: $RESOURCE_GROUP_NAME"
    az group create \
        --name "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --tags \
            Environment="$ENVIRONMENT" \
            Purpose="Development Infrastructure" \
            CreatedBy="shared-utilities" \
            CreatedOn="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        &> /dev/null
    
    if [[ $? -eq 0 ]]; then
        print_success "Resource group created successfully"
        return 0
    else
        print_error "Failed to create resource group"
        return 1
    fi
}

# =============================================================================
# FILE SYSTEM FUNCTIONS
# =============================================================================

get_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

get_vms_dir() {
    local script_dir=$(get_script_dir)
    echo "$(dirname "$(dirname "$script_dir")")/vms"
}

get_vm_dir() {
    local vm_name="$1"
    local vms_dir=$(get_vms_dir)
    echo "$vms_dir/$vm_name"
}

vm_config_exists() {
    local vm_name="$1"
    local vm_dir=$(get_vm_dir "$vm_name")
    [[ -d "$vm_dir" ]]
}

# =============================================================================
# CONFIRMATION FUNCTIONS
# =============================================================================

confirm_action() {
    local message="$1"
    local default="${2:-no}"
    
    if [[ "$default" == "yes" ]]; then
        read -p "$message (Y/n): " -r
        [[ $REPLY =~ ^[Nn]$ ]] && return 1
    else
        read -p "$message (y/N): " -r
        [[ $REPLY =~ ^[Yy]$ ]] || return 1
    fi
    
    return 0
}

confirm_with_cost() {
    local vm_count="$1"
    local action="${2:-operation}"
    
    show_cost_breakdown "$vm_count"
    echo ""
    confirm_action "Do you want to proceed with this $action?"
}

# =============================================================================
# SSH FUNCTIONS
# =============================================================================

check_ssh_key() {
    local ssh_key_path="${1:-$HOME/.ssh/id_rsa.pub}"
    
    if [[ -f "$ssh_key_path" ]]; then
        print_success "SSH public key found at $ssh_key_path"
        cat "$ssh_key_path"
        return 0
    else
        print_warning "No SSH public key found at $ssh_key_path"
        print_info "Generate one with: ssh-keygen -t rsa -b 4096"
        return 1
    fi
}

get_ssh_connection_string() {
    local vm_name="$1"
    local username="${2:-beeuser}"
    local public_ip=$(get_vm_public_ip "$vm_name")
    
    if [[ "$public_ip" != "N/A" && -n "$public_ip" ]]; then
        echo "ssh $username@$public_ip"
    else
        echo "N/A"
    fi
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_number_range() {
    local number="$1"
    local min="$2"
    local max="$3"
    
    if ! [[ "$number" =~ ^[0-9]+$ ]]; then
        print_error "Value must be a number: $number"
        return 1
    fi
    
    if [[ "$number" -lt "$min" || "$number" -gt "$max" ]]; then
        print_error "Value must be between $min and $max: $number"
        return 1
    fi
    
    return 0
}

# =============================================================================
# ENVIRONMENT INFO FUNCTIONS
# =============================================================================

show_environment_info() {
    print_subheader "ENVIRONMENT INFORMATION"
    echo "  • Environment:       $ENVIRONMENT"
    echo "  • Resource Group:    $RESOURCE_GROUP_NAME"
    echo "  • Location:          $LOCATION"
    echo "  • Subscription:      $(get_current_subscription)"
    echo "  • Subscription ID:   $(get_current_subscription_id)"
    echo "  • VM Size:           $VM_SIZE"
    echo "  • OS Disk:           $OS_DISK_TYPE ($OS_DISK_SIZE GB)"
    echo "  • Ubuntu Version:    $UBUNTU_VERSION"
    echo ""
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log_action() {
    local action="$1"
    local vm_name="${2:-N/A}"
    echo "$(timestamp) [$ENVIRONMENT] $action - VM: $vm_name" >> "/tmp/beeinfra-vm-actions.log"
}

# Usage example:
# source "$(dirname "$0")/../../shared/utils.sh"
# check_azure_prerequisites || exit 1
# validate_vm_name "ubuntu-dev-01" || exit 1
# show_cost_breakdown 5
