#!/bin/bash
# =============================================================================
#!/bin/bash
# =============================================================================
# VM RENAMING SCRIPT FOR DATS-BEEUX DEVELOPMENT INFRASTRUCTURE
# =============================================================================
# Safely renames existing VMs to follow consistent naming convention:
# - dats-beeux-dev-data → dats-beeux-data-dev
# - dats-beeux-dev-apps → dats-beeux-apps-dev
#
# This script only changes the computer name, not the Azure resource name
# No downtime required - changes take effect after reboot
# =============================================================================

set -euo pipefail

# Import logging standard
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logging-standard-bash.sh"

# Initialize logging
setup_logging

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# CONFIGURATION
# =============================================================================
RESOURCE_GROUP="rg-dev-centralus"
LOCATION="centralus"

# Current and new VM names
declare -A VM_MAPPINGS=(
    ["dats-beeux-dev-data"]="dats-beeux-data-dev"
    ["dats-beeux-dev-apps"]="dats-beeux-apps-dev"
)

# =============================================================================
# FUNCTIONS
# =============================================================================
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error_exit() {
    echo "❌ Error: $1" >&2
    exit 1
}

# =============================================================================
# VALIDATION
# =============================================================================
log "Starting VM renaming process..."

# Check Azure CLI
if ! command -v az &> /dev/null; then
    error_exit "Azure CLI not found. Please install Azure CLI."
fi

# Check login status
if ! az account show &> /dev/null; then
    error_exit "Not logged into Azure. Please run: az login"
fi

log "✅ Prerequisites validated"

# =============================================================================
# VM RENAMING FUNCTION
# =============================================================================
rename_vm() {
    local OLD_NAME="$1"
    local NEW_NAME="$2"
    
    log "🔄 Renaming VM: ${OLD_NAME} → ${NEW_NAME}"
    
    # Check if VM exists
    if ! az vm show --resource-group "$RESOURCE_GROUP" --name "$OLD_NAME" &> /dev/null; then
        log "⚠️  VM ${OLD_NAME} not found, skipping..."
        return 0
    fi
    
    # Get VM configuration
    log "   📋 Getting VM configuration..."
    VM_CONFIG=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$OLD_NAME" --output json)
    
    if [[ -z "$VM_CONFIG" ]]; then
        error_exit "Failed to get VM configuration for $OLD_NAME"
    fi
    
    # Extract key properties
    VM_SIZE=$(echo "$VM_CONFIG" | jq -r '.hardwareProfile.vmSize')
    ZONE=$(echo "$VM_CONFIG" | jq -r '.zones[]?' || echo "")
    ADMIN_USERNAME=$(echo "$VM_CONFIG" | jq -r '.osProfile.adminUsername')
    
    # Get network interface details
    NIC_ID=$(echo "$VM_CONFIG" | jq -r '.networkProfile.networkInterfaces[0].id')
    NIC_NAME=$(basename "$NIC_ID")
    
    # Get NIC configuration
    NIC_CONFIG=$(az network nic show --ids "$NIC_ID" --output json)
    SUBNET_ID=$(echo "$NIC_CONFIG" | jq -r '.ipConfigurations[0].subnet.id')
    NSG_ID=$(echo "$NIC_CONFIG" | jq -r '.networkSecurityGroup.id // empty')
    PRIVATE_IP=$(echo "$NIC_CONFIG" | jq -r '.ipConfigurations[0].privateIpAddress')
    
    # Get public IP if exists
    PUBLIC_IP_ID=$(echo "$NIC_CONFIG" | jq -r '.ipConfigurations[0].publicIpAddress.id // empty')
    PUBLIC_IP_NAME=""
    if [[ "$PUBLIC_IP_ID" != "null" && -n "$PUBLIC_IP_ID" ]]; then
        PUBLIC_IP_NAME=$(basename "$PUBLIC_IP_ID")
    fi
    
    # Get disk information
    OS_DISK_NAME=$(echo "$VM_CONFIG" | jq -r '.storageProfile.osDisk.name')
    
    log "   📊 VM Details:"
    log "      Size: $VM_SIZE"
    log "      Zone: ${ZONE:-'None'}"
    log "      Private IP: $PRIVATE_IP"
    log "      Public IP: ${PUBLIC_IP_NAME:-'None'}"
    log "      OS Disk: $OS_DISK_NAME"
    
    # =============================================================================
    # SAFE RENAMING APPROACH - UPDATE COMPUTER NAME ONLY
    # =============================================================================
    log "   🔧 Updating computer name to match new VM name..."
    
    # Create VM update command
    UPDATE_CMD="az vm update --resource-group '$RESOURCE_GROUP' --name '$OLD_NAME'"
    
    # Update computer name in OS profile
    if az vm update \
        --resource-group "$RESOURCE_GROUP" \
        --name "$OLD_NAME" \
        --set "osProfile.computerName=$NEW_NAME" \
        --output none; then
        log "   ✅ Computer name updated successfully"
    else
        error_exit "Failed to update computer name for $OLD_NAME"
    fi
    
    # =============================================================================
    # OPTIONAL: RENAME AZURE RESOURCE (RISKIER - COMMENTED OUT)
    # =============================================================================
    # Uncomment below if you want to rename the actual Azure resource
    # WARNING: This requires VM shutdown and recreation
    
    # log "   ⚠️  Note: Azure VM resource name ($OLD_NAME) unchanged for safety"
    # log "   💡 To rename Azure resource, manual shutdown and recreation required"
    
    log "   ✅ VM renaming completed: ${OLD_NAME} (computer name: ${NEW_NAME})"
    
    return 0
}

# =============================================================================
# MAIN RENAMING PROCESS
# =============================================================================
log "📋 VM Renaming Summary:"
for OLD_NAME in "${!VM_MAPPINGS[@]}"; do
    NEW_NAME="${VM_MAPPINGS[$OLD_NAME]}"
    log "   ${OLD_NAME} → ${NEW_NAME}"
done

echo ""
read -p "🤔 Do you want to proceed with renaming? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "❌ Operation cancelled by user"
    exit 0
fi

log ""
log "🚀 Starting VM renaming process..."

# Rename each VM
for OLD_NAME in "${!VM_MAPPINGS[@]}"; do
    NEW_NAME="${VM_MAPPINGS[$OLD_NAME]}"
    rename_vm "$OLD_NAME" "$NEW_NAME"
    log ""
done

# =============================================================================
# UPDATE DOCUMENTATION
# =============================================================================
log "📝 Updating documentation..."

# Note: This would update your documentation files
log "   ℹ️  Remember to update:"
log "   • ALL_INFRA_DETAILS.md - Update VM names and hostnames"
log "   • Private DNS records - Update A records if needed"  
log "   • /etc/hosts files on all VMs - Update hostname mappings"
log "   • Application configurations - Update any hardcoded hostnames"
log "   • Monitoring configurations - Update VM name references"

# =============================================================================
# VERIFICATION
# =============================================================================
log "🔍 Verification steps:"
log "   1. Check VM computer names:"

for OLD_NAME in "${!VM_MAPPINGS[@]}"; do
    NEW_NAME="${VM_MAPPINGS[$OLD_NAME]}"
    if COMPUTER_NAME=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$OLD_NAME" --query "osProfile.computerName" --output tsv 2>/dev/null); then
        if [[ "$COMPUTER_NAME" == "$NEW_NAME" ]]; then
            log "      ✅ $OLD_NAME computer name: $COMPUTER_NAME"
        else
            log "      ❌ $OLD_NAME computer name: $COMPUTER_NAME (expected: $NEW_NAME)"
        fi
    else
        log "      ⚠️  Could not verify $OLD_NAME"
    fi
done

log ""
log "   2. SSH into VMs and run 'hostname' to verify:"
log "      ssh beeuser@52.182.154.41 'hostname'  # Should show: dats-beeux-data-dev"
log "      ssh beeuser@52.230.252.48 'hostname'  # Should show: dats-beeux-apps-dev"

log ""
log "   3. Reboot VMs if hostname doesn't reflect immediately:"
log "      az vm restart --resource-group $RESOURCE_GROUP --name dats-beeux-dev-data"
log "      az vm restart --resource-group $RESOURCE_GROUP --name dats-beeux-dev-apps"

log ""
log "🎉 VM renaming process completed!"
log "📋 Next steps:"
log "   • Verify hostname changes with SSH"
log "   • Update documentation and DNS records"
log "   • Update /etc/hosts on all VMs"
log "   • Test inter-VM communication"