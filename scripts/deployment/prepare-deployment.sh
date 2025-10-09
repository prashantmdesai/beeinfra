#!/bin/bash
################################################################################
# Script: prepare-deployment.sh
# Description: Interactive script to prepare Terraform configuration files
# Author: Infrastructure Team
# Date: 2025-10-09
# Version: 1.0.0
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="${SCRIPT_DIR}/../../terraform/environments/dev"

################################################################################
# Function: print_header
################################################################################
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

################################################################################
# Function: print_info
################################################################################
print_info() {
    echo -e "${GREEN}✓${NC} $1"
}

################################################################################
# Function: print_warning
################################################################################
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

################################################################################
# Function: print_error
################################################################################
print_error() {
    echo -e "${RED}✗${NC} $1"
}

################################################################################
# Function: copy_example_files
################################################################################
copy_example_files() {
    print_header "Copying .example files to actual .tfvars files"
    
    cd "$ENV_DIR"
    
    local files=(
        "terraform.tfvars.example:terraform.tfvars"
        "vm1-infr1-dev.tfvars.example:vm1-infr1-dev.tfvars"
        "vm2-secu1-dev.tfvars.example:vm2-secu1-dev.tfvars"
        "vm3-apps1-dev.tfvars.example:vm3-apps1-dev.tfvars"
        "vm4-apps2-dev.tfvars.example:vm4-apps2-dev.tfvars"
        "vm5-data1-dev.tfvars.example:vm5-data1-dev.tfvars"
    )
    
    for file_pair in "${files[@]}"; do
        local source="${file_pair%%:*}"
        local dest="${file_pair##*:}"
        
        if [[ -f "$dest" ]]; then
            print_warning "$dest already exists, skipping..."
        else
            cp "$source" "$dest"
            print_info "Created $dest"
        fi
    done
    
    echo ""
}

################################################################################
# Function: get_azure_storage_key
################################################################################
get_azure_storage_key() {
    print_header "Retrieving Azure Storage Account Key"
    
    print_info "Checking Azure CLI authentication..."
    if ! az account show &>/dev/null; then
        print_error "Not logged into Azure CLI"
        echo ""
        echo "Please run: az login"
        return 1
    fi
    
    local storage_account="datsbeeuxdevstacct"
    local resource_group="dats-beeux-dev-rg"
    
    print_info "Checking if storage account exists..."
    if az storage account show \
        --name "$storage_account" \
        --resource-group "$resource_group" &>/dev/null; then
        
        print_info "Storage account exists, retrieving key..."
        local storage_key
        storage_key=$(az storage account keys list \
            --account-name "$storage_account" \
            --resource-group "$resource_group" \
            --query "[0].value" \
            --output tsv)
        
        if [[ -n "$storage_key" ]]; then
            print_info "Storage key retrieved successfully"
            echo "$storage_key"
            return 0
        else
            print_warning "Could not retrieve storage key"
            return 1
        fi
    else
        print_warning "Storage account does not exist yet (will be created during deployment)"
        echo "WILL_BE_CREATED"
        return 0
    fi
}

################################################################################
# Function: get_current_ip
################################################################################
get_current_ip() {
    print_header "Detecting Your Current IP Address"
    
    local ip
    ip=$(curl -s https://api.ipify.org)
    
    if [[ -n "$ip" ]]; then
        print_info "Your current IP: $ip"
        echo "$ip"
    else
        print_warning "Could not detect IP automatically"
        echo "UNKNOWN"
    fi
}

################################################################################
# Function: update_terraform_tfvars
################################################################################
update_terraform_tfvars() {
    local storage_key="$1"
    local laptop_ip="$2"
    
    print_header "Updating terraform.tfvars"
    
    cd "$ENV_DIR"
    
    if [[ "$storage_key" != "WILL_BE_CREATED" ]]; then
        print_info "Updating storage_access_key..."
        sed -i "s|storage_access_key = \"your_storage_access_key_here\"|storage_access_key = \"$storage_key\"|g" terraform.tfvars
    else
        print_warning "Skipping storage_access_key (will add after storage account creation)"
    fi
    
    print_info "Updating laptop_ip..."
    sed -i "s|laptop_ip = \"YOUR_LAPTOP_IP\"|laptop_ip = \"$laptop_ip\"|g" terraform.tfvars
    
    echo ""
    print_warning "Manual updates still needed:"
    echo "  1. github_pat - Your GitHub Personal Access Token"
    echo "  2. wifi_network_range - Your WiFi network range (optional)"
    echo ""
    echo "Edit file: $ENV_DIR/terraform.tfvars"
    echo ""
}

################################################################################
# Function: show_ssh_key_instructions
################################################################################
show_ssh_key_instructions() {
    print_header "SSH Key Setup"
    
    local ssh_key="$HOME/.ssh/id_ed25519.pub"
    
    if [[ -f "$ssh_key" ]]; then
        print_info "SSH key found: $ssh_key"
        echo ""
        echo "Your SSH public key:"
        echo "----------------------------------------"
        cat "$ssh_key"
        echo "----------------------------------------"
        echo ""
        print_info "This key is already configured in the tfvars files"
    else
        print_warning "SSH key not found: $ssh_key"
        echo ""
        echo "To generate a new SSH key:"
        echo "  ssh-keygen -t ed25519 -C \"your-email@example.com\""
        echo ""
        echo "Then update all vm*.tfvars files with your public key"
    fi
    
    echo ""
}

################################################################################
# Function: show_next_steps
################################################################################
show_next_steps() {
    print_header "Next Steps"
    
    echo "1. Review and update terraform.tfvars:"
    echo "   ${ENV_DIR}/terraform.tfvars"
    echo ""
    echo "   Required updates:"
    echo "   - github_pat: Your GitHub Personal Access Token"
    echo "   - wifi_network_range: Your WiFi network range (optional)"
    echo ""
    
    echo "2. Review VM configuration files (optional):"
    echo "   ${ENV_DIR}/vm1-infr1-dev.tfvars"
    echo "   ${ENV_DIR}/vm2-secu1-dev.tfvars"
    echo "   ${ENV_DIR}/vm3-apps1-dev.tfvars"
    echo "   ${ENV_DIR}/vm4-apps2-dev.tfvars"
    echo "   ${ENV_DIR}/vm5-data1-dev.tfvars"
    echo ""
    
    echo "3. Run Terraform deployment:"
    echo "   cd ${ENV_DIR}"
    echo "   bash ../../scripts/deployment/deploy-all.sh"
    echo ""
    
    echo "4. Or run Terraform manually:"
    echo "   cd ${ENV_DIR}"
    echo "   terraform init"
    echo "   terraform plan \\"
    echo "     -var-file=\"terraform.tfvars\" \\"
    echo "     -var-file=\"vm1-infr1-dev.tfvars\" \\"
    echo "     -var-file=\"vm2-secu1-dev.tfvars\" \\"
    echo "     -var-file=\"vm3-apps1-dev.tfvars\" \\"
    echo "     -var-file=\"vm4-apps2-dev.tfvars\" \\"
    echo "     -var-file=\"vm5-data1-dev.tfvars\""
    echo "   terraform apply"
    echo ""
    
    print_warning "IMPORTANT: Never commit actual .tfvars files to git!"
    echo ""
}

################################################################################
# Main execution
################################################################################
main() {
    print_header "Terraform Deployment Preparation"
    echo ""
    
    # Step 1: Copy example files
    copy_example_files
    
    # Step 2: Get Azure storage key (if storage exists)
    local storage_key
    storage_key=$(get_azure_storage_key) || storage_key="WILL_BE_CREATED"
    echo ""
    
    # Step 3: Get current IP
    local laptop_ip
    laptop_ip=$(get_current_ip)
    echo ""
    
    # Step 4: Update terraform.tfvars
    if [[ "$laptop_ip" != "UNKNOWN" ]]; then
        update_terraform_tfvars "$storage_key" "$laptop_ip"
    else
        print_warning "Skipping automatic updates, manual configuration required"
        echo ""
    fi
    
    # Step 5: SSH key instructions
    show_ssh_key_instructions
    
    # Step 6: Show next steps
    show_next_steps
    
    print_header "Preparation Complete!"
    echo ""
    
    exit 0
}

# Execute main function
main "$@"
