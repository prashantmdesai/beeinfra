#!/bin/bash
# =============================================================================
# DEPLOY-DATS-BEEUX-DATA-DEV.SH
# =============================================================================
# Deploy dats-beeux-data-dev (VM1) using Azure CLI
# Kubernetes Worker Node (Data Services)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# Import logging standard
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../../../scripts/logging-standard-bash.sh"

# Initialize logging
setup_logging

# =============================================================================
# SCRIPT CONFIGURATION
# =============================================================================
SCRIPT_NAME="deploy-dats-beeux-data-dev.sh"
VM_NAME="dats-beeux-data-dev"
TEMPLATE_FILE="dats-beeux-data-dev-main.bicep"

# =============================================================================
# COMMAND LINE ARGUMENTS
# =============================================================================
usage() {
    echo "Usage: $0 -k SSH_PUBLIC_KEY [-w] [-h]"
    echo "  -k SSH_PUBLIC_KEY    SSH public key for VM access (required)"
    echo "  -w                   Run What-If analysis only"
    echo "  -h                   Show this help message"
    exit 1
}

WHAT_IF=false
SSH_PUBLIC_KEY=""

while getopts "k:wh" opt; do
    case ${opt} in
        k)
            SSH_PUBLIC_KEY="$OPTARG"
            ;;
        w)
            WHAT_IF=true
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: $OPTARG" 1>&2
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$SSH_PUBLIC_KEY" ]]; then
    echo "❌ Error: SSH public key is required"
    usage
fi

# Validate SSH key format
if [[ ! "$SSH_PUBLIC_KEY" =~ ^ssh-(rsa|ed25519) ]]; then
    echo "❌ Error: SSH public key must start with 'ssh-rsa' or 'ssh-ed25519'"
    exit 1
fi

# =============================================================================
# AZURE CLI CONFIGURATION
# =============================================================================
LOCATION="centralus"
SUBSCRIPTION="d1f25f66-8914-4652-bcc4-8c6e0e0f1216"
DEPLOYMENT_NAME="deploy-${VM_NAME}-$(date +%Y%m%d-%H%M%S)"

echo "=============================================================================="
echo "🚀 DEPLOYING ${VM_NAME} - KUBERNETES WORKER (DATA)"
echo "=============================================================================="
echo "📋 Configuration:"
echo "   • VM Name: ${VM_NAME}"
echo "   • Template: ${TEMPLATE_FILE}"
echo "   • Location: ${LOCATION}"
echo "   • Deployment: ${DEPLOYMENT_NAME}"
echo "   • What-If Mode: ${WHAT_IF}"
echo ""

# =============================================================================
# VALIDATION
# =============================================================================
echo "🔍 Validating prerequisites..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Please install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure CLI. Please run: az login"
    exit 1
fi

# Set subscription
echo "📝 Setting subscription..."
az account set --subscription "${SUBSCRIPTION}"

# Verify template exists
if [[ ! -f "${TEMPLATE_FILE}" ]]; then
    echo "❌ Template file not found: ${TEMPLATE_FILE}"
    exit 1
fi

echo "✅ Prerequisites validated"
echo ""

# =============================================================================
# WHAT-IF ANALYSIS (OPTIONAL)
# =============================================================================
if [[ "${WHAT_IF}" == true ]]; then
    echo "🔍 Running What-If analysis..."
    az deployment sub what-if \
        --location "${LOCATION}" \
        --template-file "${TEMPLATE_FILE}" \
        --parameters \
            location="${LOCATION}" \
            sshPublicKey="${SSH_PUBLIC_KEY}"
    
    echo ""
    echo "✅ What-If analysis completed"
    exit 0
fi

# =============================================================================
# DEPLOYMENT
# =============================================================================
echo "🚀 Starting deployment..."
echo ""

DEPLOYMENT_OUTPUT=$(az deployment sub create \
    --name "${DEPLOYMENT_NAME}" \
    --location "${LOCATION}" \
    --template-file "${TEMPLATE_FILE}" \
    --parameters \
        location="${LOCATION}" \
        sshPublicKey="${SSH_PUBLIC_KEY}" \
    --output json)

DEPLOYMENT_STATUS=$?

if [[ ${DEPLOYMENT_STATUS} -eq 0 ]]; then
    echo ""
    echo "=============================================================================="
    echo "✅ DEPLOYMENT SUCCESSFUL"
    echo "=============================================================================="
    echo ""
    
    # Extract outputs
    VM_PUBLIC_IP=$(echo "${DEPLOYMENT_OUTPUT}" | jq -r '.properties.outputs.vmPublicIP.value')
    VM_PRIVATE_IP=$(echo "${DEPLOYMENT_OUTPUT}" | jq -r '.properties.outputs.vmPrivateIP.value')
    SSH_COMMAND=$(echo "${DEPLOYMENT_OUTPUT}" | jq -r '.properties.outputs.sshCommand.value')
    RESOURCE_GROUP=$(echo "${DEPLOYMENT_OUTPUT}" | jq -r '.properties.outputs.resourceGroupName.value')
    
    echo "📊 Deployment Details:"
    echo "   • VM Name: ${VM_NAME}"
    echo "   • Public IP: ${VM_PUBLIC_IP}"
    echo "   • Private IP: ${VM_PRIVATE_IP}"
    echo "   • Resource Group: ${RESOURCE_GROUP}"
    echo "   • Location: ${LOCATION}"
    echo ""
    echo "🔐 SSH Connection:"
    echo "   ${SSH_COMMAND}"
    echo ""
    echo "📝 Next Steps:"
    echo "   1. Wait 2-3 minutes for VM to fully boot"
    echo "   2. SSH into the VM: ${SSH_COMMAND}"
    echo "   3. Run software installer script"
    echo "   4. Mount Azure File Shares"
    echo "   5. Join to Kubernetes cluster"
    echo ""
    
    track_script_execution 0
    exit 0
else
    echo ""
    echo "=============================================================================="
    echo "❌ DEPLOYMENT FAILED"
    echo "=============================================================================="
    echo ""
    echo "Check Azure Portal for detailed error information:"
    echo "https://portal.azure.com/#blade/HubsExtension/DeploymentDetailsBlade/id/%2Fsubscriptions%2F${SUBSCRIPTION}%2Fproviders%2FMicrosoft.Resources%2Fdeployments%2F${DEPLOYMENT_NAME}"
    echo ""
    
    track_script_execution 1
    exit 1
fi
