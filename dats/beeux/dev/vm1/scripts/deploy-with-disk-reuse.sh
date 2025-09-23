#!/bin/bash

# =============================================================================
# DATS-BEEUX-DEV VM1 - DEPLOYMENT SCRIPT WITH DISK REUSE
# =============================================================================
# This script deploys the dats-beeux-dev VM using the existing disk from dev-scsm-vault
# =============================================================================

set -e

# Source Infrastructure Command Logging Standard v1.1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../../../scripts/logging-standard-bash.sh"

# Initialize logging
setup_logging

# Configuration
SOURCE_SUBSCRIPTION="f82e8e5e-cf53-4ef7-b717-dacc295d4ee4"
TARGET_SUBSCRIPTION="d1f25f66-8914-4652-bcc4-8c6e0e0f1216"
SOURCE_RG="beeinfra-dev-rg"
SOURCE_VM="dev-scsm-vault"
DISK_NAME="dev-scsm-vault_OsDisk_1_b230a675a9f34aaaa7f750e7d041b061"

echo "=============================================================================="
echo "DATS-BEEUX-DEV VM1 - DEPLOYMENT WITH DISK REUSE"
echo "=============================================================================="
echo ""

# Check Azure CLI login
echo "🔍 Validating Azure CLI login..."
if ! az account show > /dev/null 2>&1; then
    echo "❌ Error: Please run 'az login' first"
    exit 1
fi
echo "✅ Azure CLI logged in"

# Set source subscription
echo ""
echo "🔄 Setting source subscription context..."
az account set --subscription "$SOURCE_SUBSCRIPTION"
echo "✅ Source subscription set"

# Check VM status
echo ""
echo "🔍 Checking existing VM status..."
VM_STATUS=$(az vm get-instance-view --resource-group "$SOURCE_RG" --name "$SOURCE_VM" --query "instanceView.statuses[?starts_with(code, 'PowerState')].displayStatus" -o tsv)

if [ "$VM_STATUS" = "VM running" ]; then
    echo "⚠️  VM is running. Stopping it..."
    az vm stop --resource-group "$SOURCE_RG" --name "$SOURCE_VM"
    echo "✅ VM stopped"
fi

# Delete VM (disk will remain)
echo ""
echo "🗑️  Deleting VM (disk will be preserved)..."
read -p "Delete VM $SOURCE_VM? The disk will remain safe. (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    az vm delete --resource-group "$SOURCE_RG" --name "$SOURCE_VM" --yes
    echo "✅ VM deleted, disk preserved"
else
    echo "❌ Deployment cancelled"
    exit 1
fi

# Set target subscription
echo ""
echo "🔄 Setting target subscription context..."
az account set --subscription "$TARGET_SUBSCRIPTION"
echo "✅ Target subscription set"

# Deploy template
echo ""
echo "🚀 Deploying dats-beeux-dev VM..."
DEPLOYMENT_NAME="dats-beeux-dev-$(date +%Y%m%d-%H%M%S)"

az deployment sub create \
    --template-file "dats-beeux-dev-vm1-main.bicep" \
    --parameters "dats-beeux-dev-vm1-parameters.json" \
    --location eastus \
    --name "$DEPLOYMENT_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment completed successfully!"
    echo "🎉 Your dats-beeux-dev VM is ready!"
    echo "🔑 The existing SSH key will work since we're reusing the disk"
    echo "💾 All data and software from dev-scsm-vault is preserved"
else
    echo "❌ Deployment failed"
    exit 1
fi

echo ""
echo "=============================================================================="
echo "DEPLOYMENT COMPLETE"
echo "=============================================================================="