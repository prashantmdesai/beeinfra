#!/bin/bash

# =============================================================================
# BlobFuse2 Installation and BLBS Mount Setup Script
# =============================================================================
# Purpose: Install BlobFuse2 and configure Azure Blob Storage (BLBS) mounting
# Component: BLBS (Blob Storage for media files)
# Target: All 5 VMs (infr1, secu1, apps1, apps2, data1)
# =============================================================================

set -euo pipefail

echo "============================================================================="
echo "🚀 BlobFuse2 Installation and BLBS Setup - $(date)"
echo "============================================================================="
echo "Hostname: $(hostname)"
echo "User: $USER"
echo "============================================================================="

# Variables
STORAGE_ACCOUNT="datsbeeuxdevstacct"
CONTAINER_NAME="dats-beeux-dev-blbs-media"
MOUNT_POINT="/mnt/${CONTAINER_NAME}"
CACHE_DIR="/mnt/blobfusetmp"
CONFIG_DIR="/etc/blobfuse"
CONFIG_FILE="${CONFIG_DIR}/${STORAGE_ACCOUNT}.cfg"
LOGS_DIR="/home/beeuser/plt/logs"

# Storage account key (will be provided as argument or environment variable)
STORAGE_KEY="${1:-${AZURE_STORAGE_KEY:-}}"

if [[ -z "$STORAGE_KEY" ]]; then
    echo "❌ Error: Storage account key not provided"
    echo "Usage: $0 <storage-account-key>"
    echo "   or: export AZURE_STORAGE_KEY=<key> && $0"
    exit 1
fi

echo "✅ Storage account key provided (${#STORAGE_KEY} characters)"

# =============================================================================
# Step 1: Install BlobFuse2
# =============================================================================
echo ""
echo "📦 Step 1: Installing BlobFuse2..."

# Check if already installed
if command -v blobfuse2 &> /dev/null; then
    INSTALLED_VERSION=$(blobfuse2 --version 2>&1 | head -1)
    echo "✅ BlobFuse2 already installed: $INSTALLED_VERSION"
else
    echo "⏳ Installing BlobFuse2..."
    
    # Add Microsoft package repository for Ubuntu 22.04
    wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    
    # Update package list
    sudo apt-get update
    
    # Install BlobFuse2
    sudo apt-get install -y blobfuse2
    
    # Install fuse3 (required by BlobFuse2)
    sudo apt-get install -y fuse3 libfuse3-dev
    
    # Verify installation
    if command -v blobfuse2 &> /dev/null; then
        INSTALLED_VERSION=$(blobfuse2 --version 2>&1 | head -1)
        echo "✅ BlobFuse2 installed successfully: $INSTALLED_VERSION"
    else
        echo "❌ BlobFuse2 installation failed"
        exit 1
    fi
fi

# =============================================================================
# Step 2: Create directories
# =============================================================================
echo ""
echo "📁 Step 2: Creating required directories..."

# Mount point
sudo mkdir -p "$MOUNT_POINT"
sudo chown beeuser:beeuser "$MOUNT_POINT"
sudo chmod 775 "$MOUNT_POINT"
echo "✅ Mount point created: $MOUNT_POINT"

# Cache directory
sudo mkdir -p "$CACHE_DIR"
sudo chown beeuser:beeuser "$CACHE_DIR"
sudo chmod 770 "$CACHE_DIR"
echo "✅ Cache directory created: $CACHE_DIR"

# Config directory
sudo mkdir -p "$CONFIG_DIR"
sudo chmod 755 "$CONFIG_DIR"
echo "✅ Config directory created: $CONFIG_DIR"

# Logs directory
sudo mkdir -p "$LOGS_DIR"
sudo chown beeuser:beeuser "$LOGS_DIR"
sudo chmod 775 "$LOGS_DIR"
echo "✅ Logs directory created: $LOGS_DIR"

# =============================================================================
# Step 3: Create BlobFuse2 configuration file
# =============================================================================
echo ""
echo "⚙️  Step 3: Creating BlobFuse2 configuration..."

cat > /tmp/blobfuse2-config.yaml << EOF
# BlobFuse2 Configuration for BLBS (Azure Blob Storage Media Files)
# Generated: $(date)

# Allow other users to access the mount
allow-other: true

# Logging configuration
logging:
  type: syslog
  level: log_debug
  file-path: ${LOGS_DIR}/blobfuse2.log

# Component configuration
components:
  - libfuse
  - block_cache
  - attr_cache
  - azstorage

# libfuse options (FUSE filesystem layer)
libfuse:
  attribute-expiration-sec: 120
  entry-expiration-sec: 120
  negative-entry-expiration-sec: 240
  
# Block cache configuration (local caching for performance)
block_cache:
  path: ${CACHE_DIR}
  timeout-sec: 120
  max-size-mb: 4096

# Attribute cache configuration (metadata caching)
attr_cache:
  timeout-sec: 7200

# Azure Storage configuration
azstorage:
  type: block
  account-name: ${STORAGE_ACCOUNT}
  container: ${CONTAINER_NAME}
  account-key: ${STORAGE_KEY}
  mode: key
  endpoint: https://${STORAGE_ACCOUNT}.blob.core.windows.net
  max-retries: 3
  max-timeout: 900
  back-off-time: 4
  max-retry-delay: 60
  virtual-directory: true
  subdirectory: ""
  disable-symlinks: true
EOF

sudo mv /tmp/blobfuse2-config.yaml "$CONFIG_FILE"
sudo chmod 600 "$CONFIG_FILE"
sudo chown root:root "$CONFIG_FILE"
echo "✅ Configuration file created: $CONFIG_FILE"

# =============================================================================
# Step 4: Install systemd service
# =============================================================================
echo ""
echo "🔧 Step 4: Installing systemd service..."

# Copy service file from scripts directory or create it
SERVICE_FILE="/etc/systemd/system/azure-blobfuse-mount.service"

if [[ -f "/home/beeuser/plt/infra/scripts/infrastructure/azure-blobfuse-mount.service" ]]; then
    sudo cp /home/beeuser/plt/infra/scripts/infrastructure/azure-blobfuse-mount.service "$SERVICE_FILE"
    echo "✅ Service file copied from infra repo"
else
    echo "⚠️  Service file not found in infra repo, will be deployed later"
fi

# =============================================================================
# Step 5: Test mount manually first
# =============================================================================
echo ""
echo "🧪 Step 5: Testing manual mount..."

# Unmount if already mounted
if mountpoint -q "$MOUNT_POINT"; then
    echo "⏳ Unmounting existing mount..."
    sudo fusermount -u "$MOUNT_POINT" 2>/dev/null || sudo umount -f "$MOUNT_POINT" 2>/dev/null
fi

# Test mount as beeuser
echo "⏳ Attempting to mount blob container..."
if sudo -u beeuser blobfuse2 mount "$MOUNT_POINT" --config-file="$CONFIG_FILE" --log-level=log_debug --log-file-path="${LOGS_DIR}/blobfuse2-mount-test.log"; then
    echo "✅ Manual mount successful"
    
    # Verify mount
    if mountpoint -q "$MOUNT_POINT"; then
        echo "✅ Mountpoint verification passed"
        
        # List contents
        ITEM_COUNT=$(ls -1 "$MOUNT_POINT" | wc -l)
        echo "✅ Directory accessible, found $ITEM_COUNT items:"
        ls -la "$MOUNT_POINT" | head -10
        
        # Check ownership
        OWNER=$(stat -c "%U:%G" "$MOUNT_POINT")
        echo "✅ Mount ownership: $OWNER"
    else
        echo "❌ Mountpoint verification failed"
        exit 1
    fi
else
    echo "❌ Manual mount failed"
    echo "Check logs at: ${LOGS_DIR}/blobfuse2-mount-test.log"
    exit 1
fi

# =============================================================================
# Step 6: Enable and start systemd service (if service file exists)
# =============================================================================
echo ""
echo "🚀 Step 6: Configuring systemd service..."

if [[ -f "$SERVICE_FILE" ]]; then
    # Reload systemd
    sudo systemctl daemon-reload
    
    # Enable service (auto-start on boot)
    sudo systemctl enable azure-blobfuse-mount.service
    echo "✅ Service enabled for auto-start on boot"
    
    # Note: Don't start the service yet since we already have a manual mount
    echo "ℹ️  Service will be started on next boot"
    echo "ℹ️  To manually start: sudo systemctl start azure-blobfuse-mount.service"
else
    echo "⚠️  Systemd service file not installed yet"
    echo "ℹ️  Manual mount is active, will configure service later"
fi

# =============================================================================
# Step 7: Add to /etc/fstab for additional resilience (optional)
# =============================================================================
echo ""
echo "📝 Step 7: Checking /etc/fstab..."

FSTAB_ENTRY="blobfuse2 ${MOUNT_POINT} fuse _netdev,nofail,config_file=${CONFIG_FILE} 0 0"
if grep -q "blobfuse2.*${MOUNT_POINT}" /etc/fstab; then
    echo "✅ fstab entry already exists"
else
    echo "ℹ️  fstab entry not needed (systemd service handles mounting)"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "============================================================================="
echo "✅ BlobFuse2 Setup Complete!"
echo "============================================================================="
echo "📊 Summary:"
echo "  • BlobFuse2 Version: $(blobfuse2 --version 2>&1 | head -1)"
echo "  • Storage Account: $STORAGE_ACCOUNT"
echo "  • Container: $CONTAINER_NAME"
echo "  • Mount Point: $MOUNT_POINT"
echo "  • Cache Directory: $CACHE_DIR"
echo "  • Config File: $CONFIG_FILE"
echo "  • Logs Directory: $LOGS_DIR"
echo ""
echo "📁 Mounted Content:"
ls -lh "$MOUNT_POINT" | head -10
echo ""
echo "🔧 Management Commands:"
echo "  • Check mount: mountpoint $MOUNT_POINT"
echo "  • List contents: ls -la $MOUNT_POINT"
echo "  • Check service: sudo systemctl status azure-blobfuse-mount.service"
echo "  • View logs: journalctl -u azure-blobfuse-mount.service"
echo "  • BlobFuse logs: tail -f ${LOGS_DIR}/blobfuse2.log"
echo ""
echo "🔄 Next Steps:"
echo "  1. Test read/write access to the mount"
echo "  2. Reboot VM to verify auto-mount on boot"
echo "  3. Configure applications to use ${MOUNT_POINT} for media files"
echo "============================================================================="
