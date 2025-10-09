#!/bin/bash
# =============================================================================
# VALIDATION HELPERS
# =============================================================================
# Reusable validation functions for infrastructure scripts
# Usage: source terraform/scripts/common/validation-helpers.sh
# =============================================================================

# Source logging if not already loaded
if [[ -z "$PROJECT_ROOT" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/logging-standard.sh"
fi

# Validate Azure CLI is installed and logged in
validate_azure_cli() {
    log_info "Validating Azure CLI..."
    
    # Check if az command exists
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI not found. Please install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        return 1
    fi
    
    # Check Azure CLI version
    local az_version=$(az version --query '"azure-cli"' -o tsv 2>/dev/null)
    log_info "Azure CLI version: ${az_version}"
    
    # Check if logged in
    if ! az account show &> /dev/null; then
        log_error "Not logged into Azure. Please run: az login"
        return 1
    fi
    
    local account_name=$(az account show --query 'name' -o tsv)
    log_success "Logged into Azure account: ${account_name}"
    return 0
}

# Validate Terraform is installed
validate_terraform() {
    log_info "Validating Terraform..."
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform not found. Please install: https://www.terraform.io/downloads"
        return 1
    fi
    
    local tf_version=$(terraform version -json 2>/dev/null | jq -r '.terraform_version' || terraform version | head -1 | cut -d'v' -f2)
    log_info "Terraform version: ${tf_version}"
    
    # Check minimum version (1.5.0)
    local min_version="1.5.0"
    if [[ "$(printf '%s\n' "$min_version" "$tf_version" | sort -V | head -n1)" != "$min_version" ]]; then
        log_warn "Terraform version ${tf_version} is below recommended ${min_version}"
    fi
    
    log_success "Terraform validated"
    return 0
}

# Validate kubectl is installed
validate_kubectl() {
    log_info "Validating kubectl..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install: https://kubernetes.io/docs/tasks/tools/"
        return 1
    fi
    
    local kubectl_version=$(kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' || kubectl version --client --short | cut -d' ' -f3)
    log_info "kubectl version: ${kubectl_version}"
    log_success "kubectl validated"
    return 0
}

# Validate required environment variables
validate_env_vars() {
    log_info "Validating environment variables..."
    
    local required_vars=("ORGNM" "PLTNM" "ENVNM")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        log_info "Please source: terraform/scripts/common/env-config.sh"
        return 1
    fi
    
    log_success "Environment variables validated: ORGNM=${ORGNM}, PLTNM=${PLTNM}, ENVNM=${ENVNM}"
    return 0
}

# Validate Azure resource group exists
validate_resource_group() {
    local rg_name="$1"
    
    log_info "Validating resource group: ${rg_name}..."
    
    if az group show --name "$rg_name" &> /dev/null; then
        log_success "Resource group ${rg_name} exists"
        return 0
    else
        log_warn "Resource group ${rg_name} does not exist"
        return 1
    fi
}

# Validate VM exists and is running
validate_vm_running() {
    local vm_name="$1"
    local rg_name="$2"
    
    log_info "Validating VM: ${vm_name}..."
    
    if ! az vm show --name "$vm_name" --resource-group "$rg_name" &> /dev/null; then
        log_error "VM ${vm_name} not found in resource group ${rg_name}"
        return 1
    fi
    
    local power_state=$(az vm get-instance-view --name "$vm_name" --resource-group "$rg_name" --query 'instanceView.statuses[?starts_with(code, `PowerState/`)].displayStatus' -o tsv)
    
    if [[ "$power_state" == "VM running" ]]; then
        log_success "VM ${vm_name} is running"
        return 0
    else
        log_warn "VM ${vm_name} power state: ${power_state}"
        return 1
    fi
}

# Validate SSH connectivity to VM
validate_ssh_connection() {
    local vm_ip="$1"
    local ssh_user="${2:-beeuser}"
    
    log_info "Validating SSH connection to ${ssh_user}@${vm_ip}..."
    
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${ssh_user}@${vm_ip}" "echo 'SSH OK'" &> /dev/null; then
        log_success "SSH connection to ${vm_ip} successful"
        return 0
    else
        log_error "Cannot establish SSH connection to ${vm_ip}"
        return 1
    fi
}

# Validate file exists on remote VM
validate_remote_file() {
    local vm_ip="$1"
    local file_path="$2"
    local ssh_user="${3:-beeuser}"
    
    log_info "Checking if ${file_path} exists on ${vm_ip}..."
    
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${ssh_user}@${vm_ip}" "test -f ${file_path}" &> /dev/null; then
        log_success "File ${file_path} exists on ${vm_ip}"
        return 0
    else
        log_warn "File ${file_path} not found on ${vm_ip}"
        return 1
    fi
}

# Validate directory exists on remote VM
validate_remote_directory() {
    local vm_ip="$1"
    local dir_path="$2"
    local ssh_user="${3:-beeuser}"
    
    log_info "Checking if ${dir_path} exists on ${vm_ip}..."
    
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${ssh_user}@${vm_ip}" "test -d ${dir_path}" &> /dev/null; then
        log_success "Directory ${dir_path} exists on ${vm_ip}"
        return 0
    else
        log_warn "Directory ${dir_path} not found on ${vm_ip}"
        return 1
    fi
}

# Validate port is open
validate_port_open() {
    local host="$1"
    local port="$2"
    local timeout="${3:-5}"
    
    log_info "Checking if port ${port} is open on ${host}..."
    
    if timeout "$timeout" bash -c "</dev/tcp/${host}/${port}" 2>/dev/null; then
        log_success "Port ${port} is open on ${host}"
        return 0
    else
        log_warn "Port ${port} is not accessible on ${host}"
        return 1
    fi
}

# Validate all prerequisites
validate_all_prerequisites() {
    log_info "Running all prerequisite validations..."
    
    local failures=0
    
    validate_azure_cli || ((failures++))
    validate_terraform || ((failures++))
    validate_env_vars || ((failures++))
    
    if [[ $failures -eq 0 ]]; then
        log_success "All prerequisites validated successfully"
        return 0
    else
        log_error "${failures} prerequisite validation(s) failed"
        return 1
    fi
}

# Export functions
export -f validate_azure_cli validate_terraform validate_kubectl validate_env_vars
export -f validate_resource_group validate_vm_running validate_ssh_connection
export -f validate_remote_file validate_remote_directory validate_port_open
export -f validate_all_prerequisites
