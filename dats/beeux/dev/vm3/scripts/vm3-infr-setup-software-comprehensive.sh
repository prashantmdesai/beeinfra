#!/bin/bash
# =============================================================================
# VM3-INFR-SETUP-SOFTWARE-COMPREHENSIVE.SH
# =============================================================================
# Comprehensive setup script for VM3 (Kubernetes master) following naming convention:
# <component>-<subcomponent>-<purpose>-<function>-<detail>.sh
# 
# Ensures:
# 1. Identical software stack as VM1 and VM2
# 2. Azure File Share auto-mounting at /mnt/shared-data
# 3. Inter-VM communication setup
# 4. Kubernetes master preparation
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# Import logging standard
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../scripts/logging-standard-bash.sh"

# Initialize logging
setup_logging

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting VM3 comprehensive setup for dats-beeux-infr-dev..."

# =============================================================================
# SYSTEM UPDATE
# =============================================================================
log "Updating system packages..."
apt-get update && apt-get upgrade -y

# =============================================================================
# INSTALL IDENTICAL SOFTWARE STACK
# =============================================================================
log "Installing base software packages (matching VM1 and VM2)..."

# Development tools and utilities
apt-get install -y \
    curl wget git vim nano htop tree \
    build-essential software-properties-common \
    apt-transport-https ca-certificates gnupg lsb-release \
    jq unzip zip \
    net-tools tcpdump telnet nmap \
    python3 python3-pip python3-venv python3-dev \
    nodejs npm \
    openjdk-11-jdk \
    docker.io docker-compose \
    fail2ban ufw \
    cifs-utils nfs-common \
    systemd-timesyncd

# =============================================================================
# INSTALL SPECIFIC VERSION SOFTWARE (MATCHING OTHER VMS)
# =============================================================================
log "Installing specific versions to match other VMs..."

# Node.js 18.19.1 (matching VM1 and VM2)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs=18.19.1-1nodesource1
apt-mark hold nodejs

# Python 3.12
apt-get install -y python3.12 python3.12-venv python3.12-dev
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# =============================================================================
# DOCKER CONFIGURATION
# =============================================================================
log "Configuring Docker for Kubernetes..."
systemctl enable docker
systemctl start docker
usermod -aG docker beeuser

# Configure Docker daemon for Kubernetes
cat > /etc/docker/daemon.json << EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl restart docker

# =============================================================================
# KUBERNETES INSTALLATION
# =============================================================================
log "Installing Kubernetes components..."

# Add Kubernetes APT repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet=1.28.3-1.1 kubeadm=1.28.3-1.1 kubectl=1.28.3-1.1
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

# =============================================================================
# AZURE FILE SHARE SETUP (AUTO-MOUNT)
# =============================================================================
log "Setting up Azure File Share auto-mounting..."

# Azure File Share details (from existing infrastructure)
STORAGE_ACCOUNT="stdatsbeeuxdevcus5309"
SHARE_NAME="shared-data"
MOUNT_POINT="/mnt/shared-data"
CREDENTIALS_DIR="/etc/smbcredentials"
CREDENTIALS_FILE="${CREDENTIALS_DIR}/${STORAGE_ACCOUNT}.cred"

# Create mount point and credentials directory
mkdir -p "$MOUNT_POINT"
mkdir -p "$CREDENTIALS_DIR"

# Get storage account key (this will be provided during deployment)
# Using same format as existing VM1
cat > "$CREDENTIALS_FILE" << EOF
username=${STORAGE_ACCOUNT}
password=STORAGE_KEY_PLACEHOLDER
EOF

chmod 600 "$CREDENTIALS_FILE"

# Create fstab entry for auto-mount (matching existing VM1 configuration)
if ! grep -q "$STORAGE_ACCOUNT" /etc/fstab; then
    echo "//${STORAGE_ACCOUNT}.file.core.windows.net/${SHARE_NAME} ${MOUNT_POINT} cifs nofail,credentials=/etc/smbcredentials/${STORAGE_ACCOUNT}.cred,dir_mode=0755,file_mode=0644,serverino,uid=1000,gid=1000,_netdev" >> /etc/fstab
fi

log "Azure File Share configuration added to fstab"

# =============================================================================
# NETWORK CONFIGURATION FOR INTER-VM COMMUNICATION
# =============================================================================
log "Configuring network for inter-VM communication..."

# Update /etc/hosts with VM private IPs for easy communication
cat >> /etc/hosts << EOF

# DATS-BEEUX Development Infrastructure VMs
10.0.1.4    dats-beeux-data-dev data-vm vm1
10.0.1.5    dats-beeux-apps-dev apps-vm vm2  
10.0.1.6    dats-beeux-infr-dev infr-vm vm3
EOF

# Configure local firewall for Kubernetes and inter-VM communication
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# SSH access
ufw allow 22/tcp

# Kubernetes API server
ufw allow 6443/tcp

# Kubernetes cluster communication
ufw allow 2379:2380/tcp  # etcd
ufw allow 10250/tcp      # kubelet API
ufw allow 10259/tcp      # kube-scheduler
ufw allow 10257/tcp      # kube-controller-manager

# Inter-VM communication (allow from private subnet)
ufw allow from 10.0.1.0/24

# Web services
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8080/tcp
ufw allow 8443/tcp

ufw --force enable

# =============================================================================
# SYSTEM OPTIMIZATIONS
# =============================================================================
log "Applying system optimizations..."

# Kubernetes requirements
echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf

# Load br_netfilter module
modprobe br_netfilter
echo 'br_netfilter' >> /etc/modules-load.d/k8s.conf

# Disable swap (required for Kubernetes)
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Apply sysctl settings
sysctl --system

# =============================================================================
# USER CONFIGURATION
# =============================================================================
log "Configuring beeuser account..."

# Add beeuser to necessary groups
usermod -aG docker,sudo beeuser

# Create useful aliases for beeuser
cat >> /home/beeuser/.bashrc << 'EOF'

# Kubernetes aliases
alias k='kubectl'
alias kgs='kubectl get services'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'

# VM shortcuts
alias ssh-vm1='ssh beeuser@10.0.1.4'  # data VM
alias ssh-vm2='ssh beeuser@10.0.1.5'  # apps VM

# Azure File Share management
alias mount-shared='mount -t cifs //stdatsbeeuxdevcus5309.file.core.windows.net/shared-data /mnt/shared-data -o credentials=/etc/smbcredentials/stdatsbeeuxdevcus5309.cred'
alias check-shared='df -h | grep shared-data'

EOF

# =============================================================================
# SERVICE MONITORING SETUP
# =============================================================================
log "Setting up basic monitoring..."

# Install htop, iotop for monitoring
apt-get install -y htop iotop

# Create a simple health check script
cat > /usr/local/bin/vm-health-check.sh << 'EOF'
#!/bin/bash
# Simple health check for VM3
echo "=== VM3 Health Check $(date) ==="
echo "CPU Load: $(uptime | awk '{print $10,$11,$12}')"
echo "Memory Usage: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "Disk Usage: $(df -h / | tail -1 | awk '{print $5}')"
echo "Docker Status: $(systemctl is-active docker)"
echo "Kubelet Status: $(systemctl is-active kubelet)"
echo "Azure Share: $(df -h | grep shared-data | awk '{print $5}' || echo 'Not mounted')"
echo "Network Connectivity:"
ping -c 1 10.0.1.4 > /dev/null && echo "  VM1 (data): OK" || echo "  VM1 (data): FAIL"
ping -c 1 10.0.1.5 > /dev/null && echo "  VM2 (apps): OK" || echo "  VM2 (apps): FAIL"
EOF

chmod +x /usr/local/bin/vm-health-check.sh

# =============================================================================
# TIMEZONE AND NTP
# =============================================================================
log "Configuring timezone and time synchronization..."
timedatectl set-timezone UTC
systemctl enable systemd-timesyncd
systemctl start systemd-timesyncd

# =============================================================================
# CREATE DEPLOYMENT STATUS FILE
# =============================================================================
cat > /home/beeuser/vm3-deployment-status.txt << EOF
DATS-BEEUX-INFR-DEV (VM3) Deployment Status
===========================================
Deployment Date: $(date)
VM Role: Kubernetes Master Node
Private IP: 10.0.1.6
Public IP: $(curl -s https://api.ipify.org 2>/dev/null || echo "Not detected")

Software Installed:
- Ubuntu 22.04 LTS
- Docker $(docker --version 2>/dev/null || echo "Not installed")
- Kubernetes v1.28.3 (kubelet, kubeadm, kubectl)
- Node.js 18.19.1
- Python 3.12
- Java 11

Configuration Status:
- Azure File Share: $(grep azure /etc/fstab > /dev/null && echo "Configured" || echo "Not configured")
- Inter-VM networking: Configured
- Firewall rules: Configured
- Docker daemon: $(systemctl is-active docker)
- Kubelet service: $(systemctl is-active kubelet)

Next Steps:
1. Update Azure File Share storage key in /etc/smbcredentials/stdatsbeeuxdevcus5309.cred
2. Mount Azure File Share: sudo mount -a
3. Initialize Kubernetes master: kubeadm init
4. Configure kubectl for beeuser
5. Install CNI plugin (Calico/Flannel)
6. Join worker nodes to cluster

Health Check Command: /usr/local/bin/vm-health-check.sh
EOF

chown beeuser:beeuser /home/beeuser/vm3-deployment-status.txt

log "VM3 setup completed successfully!"
log "Status file created at: /home/beeuser/vm3-deployment-status.txt"
log "Run '/usr/local/bin/vm-health-check.sh' to verify system health"

# =============================================================================
# FINAL SYSTEM STATUS
# =============================================================================
log "Final system status:"
systemctl status docker --no-pager -l
systemctl status kubelet --no-pager -l
df -h
free -h