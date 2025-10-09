#!/bin/bash
# ==============================================================================
# ENVIRONMENT CONFIGURATION - COMMON SCRIPT
# ==============================================================================
# Sets environment variables used across all infrastructure scripts
# Usage: source terraform/scripts/common/env-config.sh
# ==============================================================================

# Organization, Platform, and Environment identifiers
export ORGNM="${ORGNM:-dats}"
export PLTNM="${PLTNM:-beeux}"
export ENVNM="${ENVNM:-dev}"

# Azure Configuration
export AZURE_LOCATION="${AZURE_LOCATION:-centralus}"
export AZURE_ZONE="${AZURE_ZONE:-1}"

# Resource Naming Convention: {org}-{platform}-{component}-{env}
export RESOURCE_GROUP="${ORGNM}-${PLTNM}-${ENVNM}-rg"
export VNET_NAME="${ORGNM}-${PLTNM}-${ENVNM}-vnet"
export SUBNET_NAME="${ORGNM}-${PLTNM}-${ENVNM}-subnet"
export NSG_NAME="${ORGNM}-${PLTNM}-${ENVNM}-nsg"
export STORAGE_ACCOUNT="${ORGNM}${PLTNM}${ENVNM}stacct"  # No hyphens in storage account names
export FILE_SHARE_NAME="${ORGNM}-${PLTNM}-${ENVNM}-shaf-afs"

# VM Configuration
export VM_SIZE="${VM_SIZE:-Standard_B2s}"
export VM_DISK_SIZE="${VM_DISK_SIZE:-20}"
export VM_DISK_SKU="${VM_DISK_SKU:-StandardSSD_LRS}"
export VM_ADMIN_USER="${VM_ADMIN_USER:-beeuser}"

# Kubernetes Configuration
export K8S_VERSION="${K8S_VERSION:-1.30}"
export K8S_CNI="${K8S_CNI:-calico}"
export K8S_POD_NETWORK_CIDR="${K8S_POD_NETWORK_CIDR:-192.168.0.0/16}"

# GitHub Configuration
export GITHUB_INFRA_REPO="${GITHUB_INFRA_REPO:-https://github.com/prashantmdesai/infra}"
export GITHUB_INFRA_PATH="${GITHUB_INFRA_PATH:-/home/beeuser/plt}"

# File Share Mount Point
export FILE_SHARE_MOUNT="${FILE_SHARE_MOUNT:-/mnt/${ORGNM}-${PLTNM}-${ENVNM}-shaf-afs}"

# Network Configuration
export LAPTOP_IP="${LAPTOP_IP:-136.56.79.92/32}"
export WIFI_CIDR="${WIFI_CIDR:-136.56.79.0/24}"

# Logging Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
export LOGS_DIR="${PROJECT_ROOT}/logs"
export SCRIPT_REGISTRY="${PROJECT_ROOT}/script-execution.registry"

# Color codes for output
export COLOR_RESET='\033[0m'
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[0;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_CYAN='\033[0;36m'

# Helper function to display environment info
show_env_info() {
    echo -e "${COLOR_CYAN}=== Environment Configuration ===${COLOR_RESET}"
    echo -e "${COLOR_BLUE}Organization:${COLOR_RESET} ${ORGNM}"
    echo -e "${COLOR_BLUE}Platform:${COLOR_RESET} ${PLTNM}"
    echo -e "${COLOR_BLUE}Environment:${COLOR_RESET} ${ENVNM}"
    echo -e "${COLOR_BLUE}Location:${COLOR_RESET} ${AZURE_LOCATION}"
    echo -e "${COLOR_BLUE}Resource Group:${COLOR_RESET} ${RESOURCE_GROUP}"
    echo -e "${COLOR_CYAN}===================================${COLOR_RESET}"
}

# Export helper function
export -f show_env_info

# Display info if script is sourced interactively
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -t 1 ]]; then
    show_env_info
fi
