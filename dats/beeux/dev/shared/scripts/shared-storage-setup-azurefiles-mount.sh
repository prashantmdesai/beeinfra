#!/bin/bash
# =============================================================================
# SHARED-STORAGE-SETUP-AZUREFILES-MOUNT.SH
# =============================================================================
# Azure File Share setup script following naming convention:
# <component>-<subcomponent>-<purpose>-<function>-<detail>.sh
#
# Sets up Azure File Share mounting for DATS-BEEUX infrastructure
# Uses correct storage account and mount points matching existing VM1 setup
# =============================================================================

set -euo pipefail

# Import logging standard
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../scripts/logging-standard-bash.sh"

# Initialize logging
setup_logging

# Configuration matching existing infrastructure
STORAGE_ACCOUNT="stdatsbeeuxdevcus5309"
RESOURCE_GROUP="rg-dev-centralus"
SHARE_NAME="shared-data"
MOUNT_POINT="/mnt/shared-data"
CREDENTIALS_FILE="/etc/smbcredentials/${STORAGE_ACCOUNT}.cred"

echo "=============================================================================="
echo "🔗 AZURE FILE SHARE SETUP - ${STORAGE_ACCOUNT}"
echo "=============================================================================="
echo "Share: ${SHARE_NAME}"
echo "Mount Point: ${MOUNT_POINT}"
echo "Credentials: ${CREDENTIALS_FILE}"
echo ""

# Get storage key
echo "🔑 Retrieving storage account key..."
if command -v az >/dev/null 2>&1; then
    STORAGE_KEY=$(az storage account keys list \
        --resource-group "$RESOURCE_GROUP" \
        --account-name "$STORAGE_ACCOUNT" \
        --query '[0].value' \
        --output tsv 2>/dev/null)
    
    if [[ -z "$STORAGE_KEY" ]]; then
        echo "❌ Failed to retrieve storage key via Azure CLI"
        exit 1
    fi
    echo "✅ Storage key retrieved"
else
    echo "❌ Azure CLI not found. Please install or provide storage key manually."
    exit 1
fi

# Install required packages
echo ""
echo "📦 Installing required packages..."
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -q
    sudo apt-get install -y cifs-utils
    echo "✅ cifs-utils installed"
else
    echo "❌ Unsupported package manager. Please install cifs-utils manually."
    exit 1
fi

# Create mount point
echo ""
echo "📁 Setting up mount point..."
sudo mkdir -p "$MOUNT_POINT"
sudo mkdir -p "$(dirname "$CREDENTIALS_FILE")"
echo "✅ Mount point created: $MOUNT_POINT"

# Create credentials file
echo ""
echo "🔐 Setting up credentials..."
sudo tee "$CREDENTIALS_FILE" > /dev/null <<EOF
username=$STORAGE_ACCOUNT
password=$STORAGE_KEY
EOF
sudo chmod 600 "$CREDENTIALS_FILE"
echo "✅ Credentials file created: $CREDENTIALS_FILE"

# Unmount if already mounted
if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo ""
    echo "🔄 Unmounting existing mount..."
    sudo umount "$MOUNT_POINT" || true
fi

# Mount the share
echo ""
echo "🔗 Mounting Azure File Share..."
sudo mount -t cifs \
    "//${STORAGE_ACCOUNT}.file.core.windows.net/${SHARE_NAME}" \
    "$MOUNT_POINT" \
    -o credentials="$CREDENTIALS_FILE",dir_mode=0755,file_mode=0644,serverino,uid=1000,gid=1000,vers=3.0

if mountpoint -q "$MOUNT_POINT"; then
    echo "✅ Successfully mounted Azure File Share"
else
    echo "❌ Failed to mount Azure File Share"
    exit 1
fi

# Add to fstab for persistence (matching VM1 configuration)
echo ""
echo "💾 Configuring persistent mounting..."
FSTAB_BACKUP="/etc/fstab.backup.$(date +%Y%m%d-%H%M%S)"
sudo cp /etc/fstab "$FSTAB_BACKUP"
echo "✅ Created fstab backup: $FSTAB_BACKUP"

# Remove any existing entries for this mount
sudo sed -i "\|$MOUNT_POINT|d" /etc/fstab

# Add new entry (matching VM1 format exactly)
FSTAB_ENTRY="//${STORAGE_ACCOUNT}.file.core.windows.net/${SHARE_NAME} ${MOUNT_POINT} cifs nofail,credentials=${CREDENTIALS_FILE},dir_mode=0755,file_mode=0644,serverino,uid=1000,gid=1000,_netdev 0 0"
echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
echo "✅ Added to fstab for persistent mounting"

# Test file operations
echo ""
echo "🧪 Testing file operations..."
TEST_FILE="$MOUNT_POINT/test-$(hostname)-$(date +%s).txt"
echo "Test file created by $(hostname) at $(date)" > "$TEST_FILE"

if [[ -f "$TEST_FILE" ]]; then
    echo "✅ Successfully created test file: $TEST_FILE"
    rm -f "$TEST_FILE"
    echo "✅ Test file removed successfully"
else
    echo "❌ Failed to create test file"
    exit 1
fi

# Display current status
echo ""
echo "=============================================================================="
echo "✅ AZURE FILE SHARE SETUP COMPLETED SUCCESSFULLY!"
echo "=============================================================================="
echo "📊 Mount Status:"
df -h | grep "$STORAGE_ACCOUNT" || echo "Mount not visible in df (this is sometimes normal)"
echo ""
echo "📋 Configuration Summary:"
echo "   • Storage Account: $STORAGE_ACCOUNT"
echo "   • Share Name: $SHARE_NAME"
echo "   • Mount Point: $MOUNT_POINT"
echo "   • Credentials: $CREDENTIALS_FILE"
echo "   • Persistent: Configured in /etc/fstab"
echo ""
echo "💡 Usage Examples:"
echo "   • List files: ls -la $MOUNT_POINT/"
echo "   • Copy files: cp /path/to/file $MOUNT_POINT/"
echo "   • Check mount: mountpoint $MOUNT_POINT"
echo "   • Remount: sudo mount -a"
echo ""
echo "🔍 Verification:"
echo "   • Check mount: mountpoint $MOUNT_POINT && echo 'Mounted' || echo 'Not mounted'"
echo "   • Test write: touch $MOUNT_POINT/test.txt && rm $MOUNT_POINT/test.txt"
echo "   • View fstab: grep '$STORAGE_ACCOUNT' /etc/fstab"