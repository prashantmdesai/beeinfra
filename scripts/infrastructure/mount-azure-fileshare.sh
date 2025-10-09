#!/bin/bash
################################################################################
# Script: mount-azure-fileshare.sh
# Description: Mount Azure File Share using SMB/CIFS protocol
# Author: Infrastructure Team
# Date: 2025-10-08
# Version: 1.0.0
################################################################################

set -euo pipefail

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../common"

source "${COMMON_DIR}/logging-standard.sh"
source "${COMMON_DIR}/error-handlers.sh"
source "${COMMON_DIR}/validation-helpers.sh"

# Script configuration
readonly SCRIPT_NAME="mount-azure-fileshare"
readonly LOG_FILE="/var/log/infrastructure/${SCRIPT_NAME}.log"

# Azure File Share configuration (can be overridden by environment variables)
readonly STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME:-datsbeeuxdevstacct}"
readonly FILE_SHARE_NAME="${FILE_SHARE_NAME:-dats-beeux-dev-shaf-afs}"
readonly STORAGE_ACCESS_KEY="${STORAGE_ACCESS_KEY:-}"
readonly MOUNT_POINT="${MOUNT_POINT:-/mnt/${FILE_SHARE_NAME}}"

# Mount options
readonly MOUNT_OPTIONS="nofail,credentials=/etc/smbcredentials/${STORAGE_ACCOUNT_NAME}.cred,dir_mode=0777,file_mode=0666,serverino,nosharesock,actimeo=30"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

################################################################################
# Function: check_prerequisites
# Description: Verify system prerequisites for mounting
################################################################################
check_prerequisites() {
    log_info "Checking prerequisites for Azure File Share mounting..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        return 1
    fi
    
    # Check if cifs-utils is installed
    if ! command -v mount.cifs &> /dev/null; then
        log_info "cifs-utils not found, installing..."
        apt-get update -qq
        apt-get install -y -qq cifs-utils || {
            log_error "Failed to install cifs-utils"
            return 1
        }
        log_info "cifs-utils installed successfully"
    fi
    
    # Verify configuration
    if [[ -z "$STORAGE_ACCOUNT_NAME" ]]; then
        log_error "STORAGE_ACCOUNT_NAME is not set"
        return 1
    fi
    
    if [[ -z "$FILE_SHARE_NAME" ]]; then
        log_error "FILE_SHARE_NAME is not set"
        return 1
    fi
    
    if [[ -z "$STORAGE_ACCESS_KEY" ]]; then
        log_warning "STORAGE_ACCESS_KEY not set, will try to read from config file"
    fi
    
    log_info "Prerequisites check completed successfully"
    return 0
}

################################################################################
# Function: check_if_mounted
# Description: Check if file share is already mounted
################################################################################
check_if_mounted() {
    log_info "Checking if file share is already mounted..."
    
    # Check if mount point exists and is mounted
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        log_info "File share is already mounted at $MOUNT_POINT"
        
        # Verify it's accessible
        if [[ -d "$MOUNT_POINT" ]] && [[ -r "$MOUNT_POINT" ]]; then
            log_info "Mount point is accessible"
            return 0
        else
            log_warning "Mount point exists but not accessible"
            return 1
        fi
    fi
    
    log_info "File share is not mounted"
    return 1
}

################################################################################
# Function: create_mount_point
# Description: Create mount point directory
################################################################################
create_mount_point() {
    log_info "Creating mount point: $MOUNT_POINT"
    
    if [[ -d "$MOUNT_POINT" ]]; then
        log_info "Mount point already exists"
        return 0
    fi
    
    mkdir -p "$MOUNT_POINT" || {
        log_error "Failed to create mount point"
        return 1
    }
    
    # Set permissions
    chmod 755 "$MOUNT_POINT"
    
    log_info "Mount point created successfully"
    return 0
}

################################################################################
# Function: create_credentials_file
# Description: Create SMB credentials file
################################################################################
create_credentials_file() {
    log_info "Creating SMB credentials file..."
    
    local creds_dir="/etc/smbcredentials"
    local creds_file="${creds_dir}/${STORAGE_ACCOUNT_NAME}.cred"
    
    # Create directory if it doesn't exist
    if [[ ! -d "$creds_dir" ]]; then
        mkdir -p "$creds_dir" || {
            log_error "Failed to create credentials directory"
            return 1
        }
    fi
    
    # Check if credentials file already exists
    if [[ -f "$creds_file" ]]; then
        log_info "Credentials file already exists: $creds_file"
        
        # Verify it has the right permissions
        chmod 600 "$creds_file"
        return 0
    fi
    
    # Get storage access key
    local access_key="$STORAGE_ACCESS_KEY"
    
    if [[ -z "$access_key" ]]; then
        # Try to read from environment configuration
        if [[ -f /etc/azure-fileshare.conf ]]; then
            source /etc/azure-fileshare.conf
            access_key="$STORAGE_ACCESS_KEY"
        fi
    fi
    
    if [[ -z "$access_key" ]]; then
        log_error "Storage access key not found"
        log_error "Please set STORAGE_ACCESS_KEY environment variable or /etc/azure-fileshare.conf"
        return 1
    fi
    
    # Create credentials file
    cat > "$creds_file" <<EOF
username=${STORAGE_ACCOUNT_NAME}
password=${access_key}
EOF
    
    # Set restrictive permissions
    chmod 600 "$creds_file"
    
    log_info "Credentials file created: $creds_file"
    return 0
}

################################################################################
# Function: mount_file_share
# Description: Mount the Azure File Share
################################################################################
mount_file_share() {
    log_info "Mounting Azure File Share..."
    log_info "Storage Account: $STORAGE_ACCOUNT_NAME"
    log_info "File Share: $FILE_SHARE_NAME"
    log_info "Mount Point: $MOUNT_POINT"
    
    # Construct the UNC path
    local unc_path="//${STORAGE_ACCOUNT_NAME}.file.core.windows.net/${FILE_SHARE_NAME}"
    
    # Mount the file share
    mount -t cifs "$unc_path" "$MOUNT_POINT" -o "$MOUNT_OPTIONS" || {
        log_error "Failed to mount file share"
        log_error "UNC Path: $unc_path"
        log_error "Mount Options: $MOUNT_OPTIONS"
        return 1
    }
    
    log_info "File share mounted successfully"
    return 0
}

################################################################################
# Function: add_to_fstab
# Description: Add mount to /etc/fstab for persistence
################################################################################
add_to_fstab() {
    log_info "Adding mount to /etc/fstab for persistence..."
    
    local unc_path="//${STORAGE_ACCOUNT_NAME}.file.core.windows.net/${FILE_SHARE_NAME}"
    local fstab_entry="$unc_path $MOUNT_POINT cifs $MOUNT_OPTIONS 0 0"
    
    # Check if entry already exists
    if grep -q "$MOUNT_POINT" /etc/fstab 2>/dev/null; then
        log_info "fstab entry already exists for $MOUNT_POINT"
        
        # Verify the entry matches
        if grep -q "$fstab_entry" /etc/fstab; then
            log_info "fstab entry is correct"
            return 0
        else
            log_warning "fstab entry exists but differs, updating..."
            # Remove old entry
            sed -i "\|$MOUNT_POINT|d" /etc/fstab
        fi
    fi
    
    # Add new entry
    echo "$fstab_entry" >> /etc/fstab
    
    log_info "fstab entry added successfully"
    return 0
}

################################################################################
# Function: create_directory_structure
# Description: Create standard directory structure on file share
################################################################################
create_directory_structure() {
    log_info "Creating directory structure on file share..."
    
    # Standard directories
    local directories=(
        "k8s-join-token"
        "logs"
        "configs"
        "data"
        "backups"
        "scripts"
    )
    
    for dir in "${directories[@]}"; do
        local dir_path="${MOUNT_POINT}/${dir}"
        
        if [[ ! -d "$dir_path" ]]; then
            mkdir -p "$dir_path" || {
                log_warning "Failed to create directory: $dir"
                continue
            }
            log_info "Created directory: $dir"
        else
            log_info "Directory already exists: $dir"
        fi
    done
    
    log_info "Directory structure created successfully"
    return 0
}

################################################################################
# Function: verify_mount
# Description: Verify mount is working correctly
################################################################################
verify_mount() {
    log_info "Verifying file share mount..."
    
    # Check if mounted
    if ! mountpoint -q "$MOUNT_POINT"; then
        log_error "Mount point is not mounted"
        return 1
    fi
    
    # Check if accessible
    if [[ ! -d "$MOUNT_POINT" ]]; then
        log_error "Mount point directory not accessible"
        return 1
    fi
    
    # Check if writable
    local test_file="${MOUNT_POINT}/.mount-test-$(date +%s)"
    if echo "test" > "$test_file" 2>/dev/null; then
        rm -f "$test_file"
        log_info "Mount point is writable"
    else
        log_error "Mount point is not writable"
        return 1
    fi
    
    # Get mount information
    log_info "Mount information:"
    df -h "$MOUNT_POINT" | tee -a "$LOG_FILE"
    
    # Show mount options
    log_info "Mount options:"
    mount | grep "$MOUNT_POINT" | tee -a "$LOG_FILE"
    
    log_info "Mount verification completed successfully"
    return 0
}

################################################################################
# Function: print_summary
# Description: Print mount summary
################################################################################
print_summary() {
    local mount_size=$(df -h "$MOUNT_POINT" | awk 'NR==2 {print $2}')
    local mount_used=$(df -h "$MOUNT_POINT" | awk 'NR==2 {print $3}')
    local mount_avail=$(df -h "$MOUNT_POINT" | awk 'NR==2 {print $4}')
    local mount_pct=$(df -h "$MOUNT_POINT" | awk 'NR==2 {print $5}')
    
    echo ""
    echo "=========================================="
    echo "Azure File Share Mount Summary"
    echo "=========================================="
    echo "Status: SUCCESS"
    echo "Storage Account: $STORAGE_ACCOUNT_NAME"
    echo "File Share: $FILE_SHARE_NAME"
    echo "Mount Point: $MOUNT_POINT"
    echo ""
    echo "Storage Information:"
    echo "  - Size: $mount_size"
    echo "  - Used: $mount_used ($mount_pct)"
    echo "  - Available: $mount_avail"
    echo ""
    echo "Configuration Files:"
    echo "  - Credentials: /etc/smbcredentials/${STORAGE_ACCOUNT_NAME}.cred"
    echo "  - fstab entry: Added for persistence"
    echo ""
    echo "Standard Directories Created:"
    echo "  - ${MOUNT_POINT}/k8s-join-token"
    echo "  - ${MOUNT_POINT}/logs"
    echo "  - ${MOUNT_POINT}/configs"
    echo "  - ${MOUNT_POINT}/data"
    echo "  - ${MOUNT_POINT}/backups"
    echo "  - ${MOUNT_POINT}/scripts"
    echo ""
    echo "Verification:"
    echo "  - Mounted: Yes"
    echo "  - Accessible: Yes"
    echo "  - Writable: Yes"
    echo ""
    echo "View logs: tail -f $LOG_FILE"
    echo "=========================================="
}

################################################################################
# Main execution
################################################################################
main() {
    log_info "=========================================="
    log_info "Starting Azure File Share mount"
    log_info "=========================================="
    
    # Check if already mounted (idempotency)
    if check_if_mounted; then
        log_info "File share is already mounted and accessible"
        verify_mount
        print_summary
        exit 0
    fi
    
    # Execute mount steps
    check_prerequisites || exit 1
    create_mount_point || exit 1
    create_credentials_file || exit 1
    mount_file_share || exit 1
    add_to_fstab || exit 1
    create_directory_structure || exit 1
    verify_mount || exit 1
    
    log_info "=========================================="
    log_info "Azure File Share mounted successfully"
    log_info "=========================================="
    
    print_summary
    exit 0
}

# Execute main function
main "$@"
