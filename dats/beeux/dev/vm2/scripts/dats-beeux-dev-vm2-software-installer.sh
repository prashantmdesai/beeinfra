#!/bin/bash

# =============================================================================
# DATS-BEEUX-DEV VM2 - SOFTWARE INSTALLATION SCRIPT
# =============================================================================
# This script installs development software and tools on the Ubuntu VM2
# Based on the same configuration as VM1 for consistency
# =============================================================================

set -e  # Exit on any error

# Variables
LOG_FILE="/var/log/vm2-software-install.log"
USER_HOME="/home/beeuser"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting VM2 software installation..."

# Update system
log "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install essential tools
log "Installing essential development tools..."
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    tree \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential

# Install Docker
log "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
usermod -aG docker beeuser

# Install Docker Compose
log "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Node.js and npm
log "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install Python and pip
log "Installing Python development tools..."
apt-get install -y python3 python3-pip python3-venv python3-dev

# Install PostgreSQL client
log "Installing PostgreSQL client..."
apt-get install -y postgresql-client-14

# Install Redis client
log "Installing Redis client..."
apt-get install -y redis-tools

# Install additional development tools
log "Installing additional development tools..."
apt-get install -y \
    jq \
    yq \
    net-tools \
    telnet \
    nmap \
    tcpdump \
    dnsutils

# Install Kubernetes tools
log "Installing Kubernetes tools..."
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube
log "Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# Install Helm
log "Installing Helm..."
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update -y
apt-get install -y helm

# Install HashiCorp Vault
log "Installing HashiCorp Vault..."
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update -y
apt-get install -y vault

# Install Go
log "Installing Go..."
GO_VERSION="1.21.4"
wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz

# Add Go to PATH for all users
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
echo 'export GOPATH=$HOME/go' >> /etc/profile
echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/profile

# Set up user environment
log "Setting up user environment..."
sudo -u beeuser bash -c "
    # Create development directories
    mkdir -p $USER_HOME/{projects,scripts,data,logs}
    
    # Set up shell environment
    echo 'export PATH=\$PATH:/usr/local/go/bin' >> $USER_HOME/.bashrc
    echo 'export GOPATH=\$HOME/go' >> $USER_HOME/.bashrc
    echo 'export PATH=\$PATH:\$GOPATH/bin' >> $USER_HOME/.bashrc
    echo 'alias ll=\"ls -la\"' >> $USER_HOME/.bashrc
    echo 'alias la=\"ls -A\"' >> $USER_HOME/.bashrc
    echo 'alias l=\"ls -CF\"' >> $USER_HOME/.bashrc
    
    # Create Go workspace
    mkdir -p $USER_HOME/go/{bin,src,pkg}
"

# Enable and start services
log "Enabling services..."
systemctl enable docker
systemctl start docker

# Clean up
log "Cleaning up..."
apt-get autoremove -y
apt-get autoclean

# Create VM2 identification file
echo "VM2 - $(date)" > /etc/vm-instance
echo "INSTANCE=VM2" >> /etc/environment

# Set up firewall (UFW) - same as VM1
log "Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow from 192.168.86.0/24

log "VM2 software installation completed successfully!"
log "Instance: VM2"
log "Installed software: Docker, Node.js, Python, PostgreSQL client, Redis client, Kubernetes tools, Vault, Go"
log "Next steps: Reboot recommended to complete installation"

# Create installation summary
cat > /home/beeuser/vm2-installation-summary.txt << EOF
VM2 Installation Summary
========================
Date: $(date)
Instance: VM2 (Fresh Installation)

Installed Software:
- Docker & Docker Compose
- Node.js 20.x
- Python 3 with pip
- PostgreSQL client
- Redis client
- Kubernetes tools (kubectl, minikube, helm)
- HashiCorp Vault
- Go 1.21.4
- Essential development tools

Network Configuration:
- UFW firewall enabled
- SSH access allowed
- WiFi network access (192.168.86.0/24) allowed

Directories Created:
- ~/projects/
- ~/scripts/
- ~/data/
- ~/logs/
- ~/go/

Next Steps:
1. Reboot the VM
2. Test Docker: docker run hello-world
3. Test Node.js: node --version
4. Test Python: python3 --version
5. Set up development environment as needed

EOF

chown beeuser:beeuser /home/beeuser/vm2-installation-summary.txt

log "Installation summary created at /home/beeuser/vm2-installation-summary.txt"