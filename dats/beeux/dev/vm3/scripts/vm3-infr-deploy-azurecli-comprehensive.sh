#!/bin/bash
# =============================================================================
# VM3-INFR-DEPLOY-AZURECLI-COMPREHENSIVE.SH
# =============================================================================
# Deploy dats-beeux-infr-dev (VM3) using Azure CLI
# Consolidated deployment script following naming convention:
# <component>-<subcomponent>-<purpose>-<function>-<detail>.sh
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# Import logging standard
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../scripts/logging-standard-bash.sh"

# Initialize logging
setup_logging

# =============================================================================
# SCRIPT CONFIGURATION
# =============================================================================
SCRIPT_NAME="vm3-infr-deploy-azurecli-comprehensive.sh"
VM_NUMBER="3"
VM_ROLE="infr"
VM_NAME="dats-beeux-${VM_ROLE}-dev"
TEMPLATE_FILE="../main-template.bicep"
PARAMETERS_FILE="../parameters.json"

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
RESOURCE_GROUP="rg-dev-centralus"
DEPLOYMENT_NAME="deploy-vm${VM_NUMBER}-$(date +%Y%m%d-%H%M%S)"

echo "=============================================================================="
echo "🚀 DEPLOYING VM${VM_NUMBER} (${VM_NAME}) - AZURE CLI COMPREHENSIVE"
echo "=============================================================================="
echo "📋 Configuration:"
echo "   • VM Name: ${VM_NAME}"
echo "   • Template: ${TEMPLATE_FILE}"
echo "   • Parameters: ${PARAMETERS_FILE}" 
echo "   • Location: ${LOCATION}"
echo "   • Resource Group: ${RESOURCE_GROUP}"
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

# Check if logged into Azure
if ! az account show &> /dev/null; then
    echo "❌ Not logged into Azure. Please run: az login"
    exit 1
fi

# Check if template file exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "❌ Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Check if parameters file exists  
if [[ ! -f "$PARAMETERS_FILE" ]]; then
    echo "❌ Parameters file not found: $PARAMETERS_FILE"
    exit 1
fi

echo "✅ Prerequisites validated"

# =============================================================================
# GET AZURE FILE SHARE STORAGE KEY
# =============================================================================
echo "🔑 Retrieving Azure File Share storage key..."
STORAGE_ACCOUNT="stdatsbeeuxdevcus5309"

if STORAGE_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP" \
    --account-name "$STORAGE_ACCOUNT" \
    --query '[0].value' \
    --output tsv 2>/dev/null); then
    echo "✅ Storage key retrieved"
else
    echo "⚠️  Warning: Could not retrieve storage key. Azure File Share will need manual configuration."
    STORAGE_KEY=""
fi

# =============================================================================
# PREPARE DEPLOYMENT PARAMETERS
# =============================================================================
echo "📝 Preparing deployment parameters..."

# Create temporary parameters file with SSH key
TEMP_PARAMS_FILE=$(mktemp)
jq --arg ssh_key "$SSH_PUBLIC_KEY" '.parameters.sshPublicKey.value = $ssh_key' "$PARAMETERS_FILE" > "$TEMP_PARAMS_FILE"

echo "✅ Parameters prepared"

# =============================================================================
# DEPLOYMENT
# =============================================================================
if [[ "$WHAT_IF" == "true" ]]; then
    echo "🔍 Running What-If analysis..."
    echo ""
    
    if az deployment sub what-if \
        --name "$DEPLOYMENT_NAME" \
        --location "$LOCATION" \
        --template-file "$TEMPLATE_FILE" \
        --parameters "@$TEMP_PARAMS_FILE"; then
        echo ""
        echo "✅ What-If analysis completed successfully!"
        echo ""
        echo "📊 Expected Changes:"
        echo "   • New VM: ${VM_NAME} (Zone 1, Standard_B2ms)"
        echo "   • Public IP: pip-${VM_NAME}"
        echo "   • Network Interface: nic-${VM_NAME}"
        echo "   • Uses existing NSG: nsg-dev-ubuntu-vm"
        echo "   • Software: Ubuntu 22.04 + Docker + Kubernetes 1.28.3"
        echo "   • Azure File Share: Auto-mount at /mnt/shared-data"
    else
        echo "❌ What-If analysis failed"
        rm -f "$TEMP_PARAMS_FILE"
        exit 1
    fi
else
    echo "🚀 Starting deployment..."
    echo ""
    
    if DEPLOYMENT_OUTPUT=$(az deployment sub create \
        --name "$DEPLOYMENT_NAME" \
        --location "$LOCATION" \
        --template-file "$TEMPLATE_FILE" \
        --parameters "@$TEMP_PARAMS_FILE" \
        --output json 2>/dev/null); then
        
        echo "✅ VM deployment completed successfully!"
        echo ""
        
        # Extract outputs
        VM_PUBLIC_IP=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.vmPublicIP.value')
        VM_PRIVATE_IP=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.vmPrivateIP.value')
        SSH_COMMAND=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.sshCommand.value')
        
        echo "📊 VM Information:"
        echo "   • Name: ${VM_NAME}"
        echo "   • Role: Kubernetes Master Node"  
        echo "   • Public IP: ${VM_PUBLIC_IP}"
        echo "   • Private IP: ${VM_PRIVATE_IP}"
        echo "   • Zone: 1 (same as other VMs)"
        echo "   • SSH: ${SSH_COMMAND}"
        echo ""
        
        # =============================================================================
        # POST-DEPLOYMENT AZURE FILE SHARE CONFIGURATION
        # =============================================================================
        if [[ -n "$STORAGE_KEY" ]]; then
            echo "🔧 Configuring Azure File Share..."
            
            # Wait for VM to be fully ready
            echo "   ⏳ Waiting for VM to be ready..."
            sleep 90
            
            # Create credentials content
            CREDENTIALS_CONTENT="username=${STORAGE_ACCOUNT}\npassword=${STORAGE_KEY}"
            
            # Configure Azure File Share via SSH (with retries)
            RETRY_COUNT=0
            MAX_RETRIES=3
            
            while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
                if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 "beeuser@${VM_PUBLIC_IP}" \
                    "sudo mkdir -p /etc/smbcredentials && \
                     echo -e '${CREDENTIALS_CONTENT}' | sudo tee /etc/smbcredentials/${STORAGE_ACCOUNT}.cred > /dev/null && \
                     sudo chmod 600 /etc/smbcredentials/${STORAGE_ACCOUNT}.cred && \
                     sudo mount -a && \
                     df -h | grep shared-data" 2>/dev/null; then
                    echo "✅ Azure File Share configured successfully"
                    break
                else
                    ((RETRY_COUNT++))
                    if [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; then
                        echo "   ⚠️  Retry ${RETRY_COUNT}/${MAX_RETRIES} - waiting for VM..."
                        sleep 30
                    fi
                fi
            done
            
            if [[ $RETRY_COUNT -eq $MAX_RETRIES ]]; then
                echo "⚠️  Warning: Could not configure Azure File Share automatically"
                echo "   Manual configuration will be needed after VM is fully ready"
            fi
        fi
        
        echo ""
        echo "🏗️  3-VM Architecture Summary:"
        echo "   VM1 (dats-beeux-data-dev): 52.182.154.41 (10.0.1.4) - Infrastructure Services"
        echo "   VM2 (dats-beeux-apps-dev):  52.230.252.48 (10.0.1.5) - Kubernetes Applications"  
        echo "   VM3 (dats-beeux-infr-dev):  ${VM_PUBLIC_IP} (${VM_PRIVATE_IP}) - Kubernetes Master"
        echo ""
        echo "✅ Inter-VM Communication Setup:"
        echo "   • All VMs in same subnet (10.0.1.0/24) and Zone 1"
        echo "   • Same NSG allows full inter-VM communication"
        echo "   • /etc/hosts configured for easy SSH between VMs"
        echo "   • Identical software stacks installed"
        echo "   • Azure File Share mounted at /mnt/shared-data"
        echo ""
        echo "🔍 Verification Steps:"
        echo "   1. SSH into VM3: ${SSH_COMMAND}"
        echo "   2. Check status: cat ~/vm3-deployment-status.txt"  
        echo "   3. Run health check: /usr/local/bin/vm-health-check.sh"
        echo "   4. Test inter-VM connectivity:"
        echo "      ssh beeuser@10.0.1.4  # VM1 (data)"
        echo "      ssh beeuser@10.0.1.5  # VM2 (apps)"
        echo "   5. Check Azure File Share: ls -la /mnt/shared-data/"
        echo ""
        echo "🎛️  Kubernetes Setup (when ready):"
        echo "   1. Initialize: sudo kubeadm init --pod-network-cidr=192.168.0.0/16"
        echo "   2. Configure kubectl: mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config"  
        echo "   3. Install CNI: kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
        echo "   4. Join worker nodes from VM1 and VM2"
        
    else
        echo "❌ Deployment failed"
        rm -f "$TEMP_PARAMS_FILE"
        exit 1
    fi
fi

# Cleanup
rm -f "$TEMP_PARAMS_FILE"

echo ""
echo "🎉 VM${VM_NUMBER} deployment script completed!"
echo "All VMs now have identical configurations and can communicate with each other!"