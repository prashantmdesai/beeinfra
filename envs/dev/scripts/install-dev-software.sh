#!/bin/bash
# =============================================================================
# CONSERVATIVE DEVELOPMENT VM SOFTWARE INSTALLATION SCRIPT
# =============================================================================
# This script installs only essential software packages for the development VM
# Based on common Ubuntu development patterns and VM configuration analysis
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root"
   exit 1
fi

log "Starting CONSERVATIVE development software installation..."
log "Installing only essential packages for development work"

# =============================================================================
# SYSTEM UPDATE
# =============================================================================
log "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# =============================================================================
# ESSENTIAL DEVELOPMENT TOOLS
# =============================================================================
log "Installing essential development tools..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    tree \
    unzip \
    zip \
    jq \
    build-essential \
    ca-certificates \
    software-properties-common

# =============================================================================
# AZURE CLI (for Azure management)
# =============================================================================
log "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# =============================================================================
# DOCKER (commonly needed for development)
# =============================================================================
log "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker
rm -f get-docker.sh

# =============================================================================
# NODE.JS LTS (for web development)
# =============================================================================
log "Installing Node.js LTS..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# =============================================================================
# PYTHON3 DEVELOPMENT
# =============================================================================
log "Installing Python3 development tools..."
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv

# =============================================================================
# SSH AND NETWORK TOOLS
# =============================================================================
log "Installing SSH and network tools..."
sudo apt-get install -y \
    openssh-client \
    net-tools \
    telnet

# =============================================================================
# USER CONFIGURATION
# =============================================================================
log "Setting up basic user configuration..."

# Create a basic Git configuration helper
cat > ~/setup-git.sh << 'EOF'
#!/bin/bash
echo "Git Configuration Setup"
echo "======================="
echo "Enter your Git username:"
read -r GIT_USERNAME
echo "Enter your Git email:"
read -r GIT_EMAIL

git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global pull.rebase false

echo "Git configuration completed!"
echo "Username: $(git config --global user.name)"
echo "Email: $(git config --global user.email)"
EOF
chmod +x ~/setup-git.sh

# =============================================================================
# CREATE WELCOME MESSAGE
# =============================================================================
cat > /tmp/motd << 'EOF'
================================
DEVELOPMENT UBUNTU VM (DEV)
================================

Installed Software:
- Essential development tools
- Azure CLI for cloud management
- Docker for containerization
- Node.js LTS for web development
- Python3 with pip and venv
- Git and SSH tools
- System monitoring tools

Next Steps:
1. Run ~/setup-git.sh to configure Git
2. Log out and back in to refresh Docker group
3. Test installations:
   - docker --version
   - az --version
   - node --version
   - python3 --version

Auto-shutdown: Enabled at 19:00 UTC
================================
EOF

sudo mv /tmp/motd /etc/motd

# =============================================================================
# CLEANUP
# =============================================================================
log "Cleaning up..."
sudo apt-get autoremove -y
sudo apt-get autoclean

# =============================================================================
# FINAL STATUS
# =============================================================================
log "Installation completed successfully!"
log "Verifying installations..."

echo "Software versions:"
echo "- Azure CLI: $(az --version 2>/dev/null | head -1 || echo 'Not available')"
echo "- Docker: $(docker --version 2>/dev/null || echo 'Not available')"
echo "- Node.js: $(node --version 2>/dev/null || echo 'Not available')"
echo "- npm: $(npm --version 2>/dev/null || echo 'Not available')"
echo "- Python3: $(python3 --version 2>/dev/null || echo 'Not available')"
echo "- Git: $(git --version 2>/dev/null || echo 'Not available')"

log "Development environment setup complete!"
warning "Please log out and back in to refresh your shell environment."
warning "Run ~/setup-git.sh to configure Git with your credentials."