#!/bin/bash
# =============================================================================
# VM SOFTWARE INVENTORY SCRIPT
# =============================================================================
# This script inventories all installed software on the current VM
# to create an accurate installation script for replication
# =============================================================================

echo "============================================="
echo "VM SOFTWARE INVENTORY"
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "============================================="
echo

echo "=== SYSTEM INFORMATION ==="
uname -a
echo
lsb_release -a
echo

echo "=== INSTALLED PACKAGES (user-installed) ==="
echo "Getting list of manually installed packages..."
comm -23 <(apt-mark showmanual | sort) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort) | head -50
echo

echo "=== PYTHON PACKAGES ==="
if command -v pip3 &> /dev/null; then
    echo "Python3 packages:"
    pip3 list --user 2>/dev/null || echo "No user Python packages"
else
    echo "pip3 not installed"
fi
echo

echo "=== NODE.JS PACKAGES ==="
if command -v npm &> /dev/null; then
    echo "Global npm packages:"
    npm list -g --depth=0 2>/dev/null || echo "No global npm packages"
else
    echo "npm not installed"
fi
echo

echo "=== SYSTEM SERVICES ==="
echo "Active services:"
systemctl list-units --type=service --state=active | grep -v "@" | head -20
echo

echo "=== COMMAND LINE TOOLS ==="
echo "Checking for common development tools..."
for cmd in git vim nano curl wget htop tree unzip zip jq docker docker-compose node npm python3 pip3 az gh terraform kubectl; do
    if command -v $cmd &> /dev/null; then
        version=$($cmd --version 2>/dev/null | head -1 || echo "version unknown")
        echo "✓ $cmd: $version"
    else
        echo "✗ $cmd: not installed"
    fi
done
echo

echo "=== DOCKER INFO ==="
if command -v docker &> /dev/null; then
    echo "Docker status:"
    docker --version
    docker info 2>/dev/null | grep "Server Version" || echo "Docker daemon not running"
    echo "Docker images:"
    docker images 2>/dev/null | head -10 || echo "Cannot access Docker"
else
    echo "Docker not installed"
fi
echo

echo "=== NETWORK PORTS ==="
echo "Listening ports:"
ss -tuln | head -20
echo

echo "=== DISK USAGE ==="
df -h
echo

echo "=== MEMORY USAGE ==="
free -h
echo

echo "=== ENVIRONMENT VARIABLES ==="
echo "Important environment variables:"
env | grep -E "(PATH|JAVA_HOME|NODE_|PYTHON|GO)" | head -10
echo

echo "============================================="
echo "INVENTORY COMPLETE"
echo "============================================="