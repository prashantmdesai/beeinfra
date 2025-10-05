#!/bin/bash#!/bin/bash

# Simple Azure Files setup script# Simple Azure Files setup script

set -eset -e



# Configuration# Configuration

STORAGE_ACCOUNT="stdatsbeeuxdevshared"STORAGE_ACCOUNT="stdatsbeeuxdevshared"

# Get storage key securely - either from environment variable or Azure CLI# Get storage key securely - either from environment variable or Azure CLI

if [ -n "$AZURE_STORAGE_KEY" ]; thenif [ -n "$AZURE_STORAGE_KEY" ]; then

    STORAGE_KEY="$AZURE_STORAGE_KEY"    STORAGE_KEY="$AZURE_STORAGE_KEY"

elif command -v az >/dev/null 2>&1; thenelif command -v az >/dev/null 2>&1; then

    echo "Retrieving storage key from Azure CLI..."    echo "Retrieving storage key from Azure CLI..."

    STORAGE_KEY=$(az storage account keys list --account-name "$STORAGE_ACCOUNT" --resource-group "rg-dev-eastus" --query "[0].value" --output tsv)    STORAGE_KEY=$(az storage account keys list --account-name "$STORAGE_ACCOUNT" --resource-group "rg-dev-eastus" --query "[0].value" --output tsv)

elseelse

    echo "ERROR: No storage key found. Please set AZURE_STORAGE_KEY environment variable or install Azure CLI."    echo "ERROR: No storage key found. Please set AZURE_STORAGE_KEY environment variable or install Azure CLI."

    exit 1    exit 1

fifi

MOUNT_BASE="/mnt/azure-files"MOUNT_BASE="/mnt/azure-files"



echo "Setting up Azure Files shares..."echo "Setting up Azure Files shares..."



# Install cifs-utils# Install cifs-utils

echo "Installing cifs-utils..."echo "Installing cifs-utils..."

sudo apt-get update -ysudo apt-get update -y

sudo apt-get install -y cifs-utilssudo apt-get install -y cifs-utils



# Create mount points# Create mount points

echo "Creating mount points..."echo "Creating mount points..."

sudo mkdir -p ${MOUNT_BASE}/{shared-data,config-files,logs-temp}sudo mkdir -p ${MOUNT_BASE}/{shared-data,config-files,logs-temp}



# Create credentials file# Create credentials file

echo "Creating credentials file..."echo "Creating credentials file..."

sudo tee /etc/azure-files-credentials > /dev/null <<EOFsudo tee /etc/azure-files-credentials > /dev/null <<EOF

username=${STORAGE_ACCOUNT}username=${STORAGE_ACCOUNT}

password=${STORAGE_KEY}password=${STORAGE_KEY}

EOFEOF

sudo chmod 600 /etc/azure-files-credentialssudo chmod 600 /etc/azure-files-credentials



# Mount shares# Mount shares

echo "Mounting file shares..."echo "Mounting file shares..."

for share in shared-data config-files logs-temp; dofor share in shared-data config-files logs-temp; do

    echo "Mounting ${share}..."    echo "Mounting ${share}..."

    sudo mount -t cifs \    sudo mount -t cifs \

        "//${STORAGE_ACCOUNT}.file.core.windows.net/${share}" \        "//${STORAGE_ACCOUNT}.file.core.windows.net/${share}" \

        "${MOUNT_BASE}/${share}" \        "${MOUNT_BASE}/${share}" \

        -o credentials=/etc/azure-files-credentials,vers=3.0,dir_mode=0777,file_mode=0666,serverino,uid=$(id -u),gid=$(id -g) || echo "Failed to mount ${share}"        -o credentials=/etc/azure-files-credentials,vers=3.0,dir_mode=0777,file_mode=0666,serverino,uid=$(id -u),gid=$(id -g) || echo "Failed to mount ${share}"

donedone



# Add to fstab# Add to fstab

echo "Adding to fstab for persistence..."echo "Adding to fstab for persistence..."

sudo cp /etc/fstab /etc/fstab.backupsudo cp /etc/fstab /etc/fstab.backup

for share in shared-data config-files logs-temp; dofor share in shared-data config-files logs-temp; do

    sudo sed -i "\|${MOUNT_BASE}/${share}|d" /etc/fstab    sudo sed -i "\|${MOUNT_BASE}/${share}|d" /etc/fstab

    echo "//${STORAGE_ACCOUNT}.file.core.windows.net/${share} ${MOUNT_BASE}/${share} cifs credentials=/etc/azure-files-credentials,vers=3.0,dir_mode=0777,file_mode=0666,serverino,uid=$(id -u),gid=$(id -g),_netdev 0 0" | sudo tee -a /etc/fstab > /dev/null    echo "//${STORAGE_ACCOUNT}.file.core.windows.net/${share} ${MOUNT_BASE}/${share} cifs credentials=/etc/azure-files-credentials,vers=3.0,dir_mode=0777,file_mode=0666,serverino,uid=$(id -u),gid=$(id -g),_netdev 0 0" | sudo tee -a /etc/fstab > /dev/null

donedone



# Create symlinks# Create symlinks

echo "Creating convenience symlinks..."echo "Creating convenience symlinks..."

sudo ln -sf ${MOUNT_BASE}/shared-data /shared-data 2>/dev/null || truesudo ln -sf ${MOUNT_BASE}/shared-data /shared-data 2>/dev/null || true

sudo ln -sf ${MOUNT_BASE}/config-files /config-files 2>/dev/null || truesudo ln -sf ${MOUNT_BASE}/config-files /config-files 2>/dev/null || true

sudo ln -sf ${MOUNT_BASE}/logs-temp /logs-temp 2>/dev/null || truesudo ln -sf ${MOUNT_BASE}/logs-temp /logs-temp 2>/dev/null || true



# Test# Test

echo "Testing file shares..."echo "Testing file shares..."

for share in shared-data config-files logs-temp; dofor share in shared-data config-files logs-temp; do

    test_file="${MOUNT_BASE}/${share}/test-$(hostname)-$(date +%s).txt"    test_file="${MOUNT_BASE}/${share}/test-$(hostname)-$(date +%s).txt"

    echo "Test from $(hostname) at $(date)" > "${test_file}" && rm -f "${test_file}" && echo "${share}: OK" || echo "${share}: FAILED"    echo "Test from $(hostname) at $(date)" > "${test_file}" && rm -f "${test_file}" && echo "${share}: OK" || echo "${share}: FAILED"

donedone



echo "Azure Files setup completed!"echo "Azure Files setup completed!"

echo "Available shares:"echo "Available shares:"

echo "  /mnt/azure-files/shared-data (symlink: /shared-data)"echo "  /mnt/azure-files/shared-data (symlink: /shared-data)"

echo "  /mnt/azure-files/config-files (symlink: /config-files)"  echo "  /mnt/azure-files/config-files (symlink: /config-files)"  

echo "  /mnt/azure-files/logs-temp (symlink: /logs-temp)"echo "  /mnt/azure-files/logs-temp (symlink: /logs-temp)"