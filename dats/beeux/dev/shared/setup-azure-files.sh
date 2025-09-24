#!/bin/bash
# =============================================================================
# DATS-BEEUX-DEV - AZURE FILES SETUP SCRIPT
# =============================================================================
# Sets up Azure Files shares on Linux VMs for file sharing
# Usage: ./setup-azure-files.sh <storage_account_name> <storage_account_key>
# =============================================================================

set -euo pipefail

# Import logging functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../scripts/logging-standard-bash.sh"

# Script metadata
SCRIPT_NAME="Azure Files Setup"
SCRIPT_VERSION="1.0.0"
COMPONENT_NAME="SharedStorage"

# Initialize logging
init_logging "${SCRIPT_NAME}" "${SCRIPT_VERSION}" "${COMPONENT_NAME}"

# Parameters
STORAGE_ACCOUNT_NAME="${1:-}"
STORAGE_ACCOUNT_KEY="${2:-}"

if [[ -z "${STORAGE_ACCOUNT_NAME}" || -z "${STORAGE_ACCOUNT_KEY}" ]]; then
    log_error "Usage: $0 <storage_account_name> <storage_account_key>"
    exit 1
fi

# Configuration
MOUNT_BASE="/mnt/azure-files"
SHARES=("shared-data" "config-files" "logs-temp")

log_info "Setting up Azure Files shares for VM file sharing"

# Install required packages
log_info "Installing required packages"
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y cifs-utils
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y cifs-utils
else
    log_error "Unsupported package manager. Please install cifs-utils manually."
    exit 1
fi

# Create mount points
log_info "Creating mount points"
sudo mkdir -p "${MOUNT_BASE}"
for share in "${SHARES[@]}"; do
    sudo mkdir -p "${MOUNT_BASE}/${share}"
    log_info "Created mount point: ${MOUNT_BASE}/${share}"
done

# Create credentials file
CREDS_FILE="/etc/azure-files-credentials"
log_info "Creating credentials file"
sudo tee "${CREDS_FILE}" > /dev/null <<EOF
username=${STORAGE_ACCOUNT_NAME}
password=${STORAGE_ACCOUNT_KEY}
EOF
sudo chmod 600 "${CREDS_FILE}"

# Mount shares
log_info "Mounting Azure Files shares"
for share in "${SHARES[@]}"; do
    log_info "Mounting share: ${share}"
    
    # Unmount if already mounted
    if mountpoint -q "${MOUNT_BASE}/${share}"; then
        log_info "Unmounting existing mount: ${share}"
        sudo umount "${MOUNT_BASE}/${share}" || true
    fi
    
    # Mount the share
    sudo mount -t cifs \
        "//${STORAGE_ACCOUNT_NAME}.file.core.windows.net/${share}" \
        "${MOUNT_BASE}/${share}" \
        -o credentials="${CREDS_FILE}",vers=3.0,dir_mode=0777,file_mode=0666,serverino,uid=$(id -u),gid=$(id -g)
    
    if mountpoint -q "${MOUNT_BASE}/${share}"; then
        log_info "Successfully mounted: ${share}"
    else
        log_error "Failed to mount: ${share}"
        exit 1
    fi
done

# Add to fstab for persistent mounting
log_info "Adding mounts to /etc/fstab for persistence"
FSTAB_BACKUP="/etc/fstab.backup.$(date +%Y%m%d-%H%M%S)"
sudo cp /etc/fstab "${FSTAB_BACKUP}"
log_info "Created fstab backup: ${FSTAB_BACKUP}"

for share in "${SHARES[@]}"; do
    # Remove existing entries for this share
    sudo sed -i "\|${MOUNT_BASE}/${share}|d" /etc/fstab
    
    # Add new entry
    echo "//${STORAGE_ACCOUNT_NAME}.file.core.windows.net/${share} ${MOUNT_BASE}/${share} cifs credentials=${CREDS_FILE},vers=3.0,dir_mode=0777,file_mode=0666,serverino,uid=$(id -u),gid=$(id -g),_netdev 0 0" | sudo tee -a /etc/fstab > /dev/null
    log_info "Added ${share} to fstab"
done

# Test file operations
log_info "Testing file operations on mounted shares"
for share in "${SHARES[@]}"; do
    TEST_FILE="${MOUNT_BASE}/${share}/test-$(hostname)-$(date +%s).txt"
    echo "Test file created by $(hostname) at $(date)" > "${TEST_FILE}"
    
    if [[ -f "${TEST_FILE}" ]]; then
        log_info "Successfully created test file in ${share}: ${TEST_FILE}"
        rm -f "${TEST_FILE}"
    else
        log_error "Failed to create test file in ${share}"
        exit 1
    fi
done

# Create symlinks for easy access
log_info "Creating convenience symlinks"
sudo ln -sf "${MOUNT_BASE}/shared-data" /shared-data 2>/dev/null || true
sudo ln -sf "${MOUNT_BASE}/config-files" /config-files 2>/dev/null || true
sudo ln -sf "${MOUNT_BASE}/logs-temp" /logs-temp 2>/dev/null || true

# Display mount status
log_info "Current Azure Files mount status:"
df -h | grep "${STORAGE_ACCOUNT_NAME}.file.core.windows.net" || log_warning "No Azure Files mounts found in df output"

log_success "Azure Files setup completed successfully!"
log_info "Available shares:"
for share in "${SHARES[@]}"; do
    log_info "  ${MOUNT_BASE}/${share} (symlink: /${share})"
done

log_info "Example usage:"
log_info "  # Copy files between VMs"
log_info "  cp /path/to/file ${MOUNT_BASE}/shared-data/"
log_info "  # Share configuration"
log_info "  cp /etc/myapp.conf ${MOUNT_BASE}/config-files/"
log_info "  # Centralized logging"
log_info "  tail -f ${MOUNT_BASE}/logs-temp/application.log"

complete_logging