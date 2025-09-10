#!/bin/bash
# =============================================================================
# UBUNTU DEV VM 01 - DEPLOYMENT SCRIPT
# =============================================================================
# Description: Deploy Ubuntu development VM to Azure using Bicep
# Environment: Development
# VM: ubuntu-dev-01 (Standard_B2s with Premium SSD)
# =============================================================================

set -e  # Exit on any error

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_NAME="ubuntu-dev-01"
ENVIRONMENT="dev"
RESOURCE_GROUP_NAME="beeinfra-${ENVIRONMENT}-rg"
LOCATION="eastus"  # Change this to your preferred Azure region
DEPLOYMENT_NAME="${VM_NAME}-deployment-$(date +%Y%m%d-%H%M%S)"

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
    print_header "CHECKING PREREQUISITES"
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        print_info "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check if logged into Azure
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure. Please login first."
        print_info "Run: az login"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

show_cost_estimate() {
    print_header "COST ESTIMATE"
    echo -e "${YELLOW}Estimated Monthly Cost for ${VM_NAME}:${NC}"
    echo "  • VM (Standard_B2s):     $30.37/month"
    echo "  • Premium SSD (30GB):    $6.14/month"
    echo "  • Static Public IP:      $3.65/month"
    echo "  • Network (minimal):     $0.00/month"
    echo "  ─────────────────────────────────────"
    echo "  • TOTAL:                $40.16/month"
    echo ""
    echo -e "${YELLOW}Hourly Cost: ~$0.056/hour${NC}"
    echo ""
}

confirm_deployment() {
    show_cost_estimate
    echo -e "${YELLOW}You are about to deploy the following VM:${NC}"
    echo "  • VM Name:           ${VM_NAME}"
    echo "  • Environment:       ${ENVIRONMENT}"
    echo "  • Resource Group:    ${RESOURCE_GROUP_NAME}"
    echo "  • Location:          ${LOCATION}"
    echo "  • VM Size:           Standard_B2s (2 vCPU, 4GB RAM)"
    echo "  • Disk:              30GB Premium SSD"
    echo "  • OS:                Ubuntu 24.04 LTS"
    echo "  • Network:           Static Public IP + NSG"
    echo ""
    
    read -p "Do you want to proceed with this deployment? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Deployment cancelled by user"
        exit 0
    fi
}

check_ssh_key() {
    print_header "SSH KEY CONFIGURATION"
    
    SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
    
    if [[ -f "$SSH_KEY_PATH" ]]; then
        print_success "SSH public key found at $SSH_KEY_PATH"
        SSH_PUBLIC_KEY=$(cat "$SSH_KEY_PATH")
    else
        print_warning "No SSH public key found at $SSH_KEY_PATH"
        print_info "You can either:"
        print_info "1. Generate an SSH key pair: ssh-keygen -t rsa -b 4096"
        print_info "2. Use password authentication instead"
        echo ""
        read -p "Do you want to use password authentication? (yes/no): " -r
        if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            SSH_PUBLIC_KEY=""
            print_info "Password authentication will be used"
        else
            print_error "Please generate an SSH key pair first"
            exit 1
        fi
    fi
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
                CreatedBy="deployment-script" \
                CreatedOn="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        
        print_success "Resource group created successfully"
    fi
}

deploy_vm() {
    print_header "DEPLOYING VIRTUAL MACHINE"
    
    BICEP_FILE="$SCRIPT_DIR/../bicep/main.bicep"
    PARAMETERS_FILE="$SCRIPT_DIR/../bicep/parameters.json"
    
    if [[ ! -f "$BICEP_FILE" ]]; then
        print_error "Bicep template not found: $BICEP_FILE"
        exit 1
    fi
    
    print_info "Starting deployment: $DEPLOYMENT_NAME"
    print_info "Using Bicep template: $BICEP_FILE"
    
    # Build deployment command
    DEPLOY_CMD="az deployment group create \
        --resource-group '$RESOURCE_GROUP_NAME' \
        --name '$DEPLOYMENT_NAME' \
        --template-file '$BICEP_FILE'"
    
    # Add parameters
    if [[ -f "$PARAMETERS_FILE" ]]; then
        DEPLOY_CMD="$DEPLOY_CMD --parameters '@$PARAMETERS_FILE'"
        print_info "Using parameters file: $PARAMETERS_FILE"
    fi
    
    # Add SSH key if available
    if [[ -n "$SSH_PUBLIC_KEY" ]]; then
        DEPLOY_CMD="$DEPLOY_CMD --parameters sshPublicKey='$SSH_PUBLIC_KEY'"
        print_info "SSH public key will be configured"
    fi
    
    # Execute deployment
    print_info "Executing deployment..."
    eval "$DEPLOY_CMD"
    
    if [[ $? -eq 0 ]]; then
        print_success "VM deployment completed successfully"
    else
        print_error "VM deployment failed"
        exit 1
    fi
}

show_deployment_results() {
    print_header "DEPLOYMENT RESULTS"
    
    print_info "Retrieving deployment outputs..."
    
    # Get deployment outputs
    OUTPUTS=$(az deployment group show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --query 'properties.outputs' \
        --output json)
    
    if [[ -n "$OUTPUTS" && "$OUTPUTS" != "null" ]]; then
        # Extract key information
        PUBLIC_IP=$(echo "$OUTPUTS" | jq -r '.publicIPAddress.value // "N/A"')
        FQDN=$(echo "$OUTPUTS" | jq -r '.fqdn.value // "N/A"')
        SSH_COMMAND=$(echo "$OUTPUTS" | jq -r '.sshCommand.value // "N/A"')
        
        echo -e "${GREEN}VM Successfully Deployed!${NC}"
        echo "─────────────────────────────────────────────────"
        echo "  • VM Name:           $VM_NAME"
        echo "  • Public IP:         $PUBLIC_IP"
        echo "  • FQDN:              $FQDN"
        echo "  • SSH Command:       $SSH_COMMAND"
        echo "  • Resource Group:    $RESOURCE_GROUP_NAME"
        echo "─────────────────────────────────────────────────"
        echo ""
        
        if [[ "$SSH_COMMAND" != "N/A" ]]; then
            print_info "To connect to your VM:"
            echo "  $SSH_COMMAND"
        fi
    else
        print_warning "Could not retrieve deployment outputs"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "UBUNTU DEV VM 01 - DEPLOYMENT"
    
    check_prerequisites
    confirm_deployment
    check_ssh_key
    create_resource_group
    deploy_vm
    show_deployment_results
    
    print_success "Deployment process completed!"
    print_info "VM is now ready for use"
}

# Execute main function
main "$@"
