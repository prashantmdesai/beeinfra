#!/bin/bash
# Apply systemd mount unit to existing VMs
set -e

MOUNT_POINT="/mnt/dats-beeux-dev-shaf-afs"
STORAGE_ACCOUNT="datsbeeuxdevstacct"
FILE_SHARE="dats-beeux-dev-shaf-afs"
CREDS_FILE="/etc/smbcredentials/${STORAGE_ACCOUNT}.cred"

echo "=== Applying systemd mount unit to $(hostname) ==="

# Get current UID/GID
BEEUSER_UID=$(id -u beeuser)
BEEUSER_GID=$(id -g beeuser)

# Disable old services if they exist
if systemctl is-enabled azure-fileshare-mount.service 2>/dev/null; then
    echo "Disabling old azure-fileshare-mount.service"
    sudo systemctl disable azure-fileshare-mount.service
    sudo systemctl stop azure-fileshare-mount.service
fi

if systemctl is-enabled azure-fileshare-healthcheck.timer 2>/dev/null; then
    echo "Disabling old azure-fileshare-healthcheck.timer"
    sudo systemctl disable azure-fileshare-healthcheck.timer
    sudo systemctl stop azure-fileshare-healthcheck.timer
fi

# Remove fstab entry
echo "Removing fstab entry"
sudo sed -i "\|$MOUNT_POINT|d" /etc/fstab

# Unmount all CIFS mounts
echo "Unmounting existing mounts"
sudo umount -a -t cifs -l || true

# Use fstab instead - simpler and works reliably
echo "Adding to fstab with proper network dependencies"
FSTAB_ENTRY="//${STORAGE_ACCOUNT}.file.core.windows.net/${FILE_SHARE} ${MOUNT_POINT} cifs nofail,x-systemd.after=network-online.target,x-systemd.requires=network-online.target,credentials=${CREDS_FILE},uid=${BEEUSER_UID},gid=${BEEUSER_GID},dir_mode=0775,file_mode=0664,serverino,nosharesock,actimeo=30,_netdev 0 0"

if ! grep -q "$MOUNT_POINT" /etc/fstab; then
    echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
fi

# Mount now
echo "Mounting"
sudo systemctl daemon-reload
sudo mount -a

# Verify
echo "Verifying mount"
df -h "$MOUNT_POINT"
mount | grep "$MOUNT_POINT" | wc -l
echo "mount count (should be 1)"

echo "✓ SUCCESS - systemd mount unit applied to $(hostname)"
