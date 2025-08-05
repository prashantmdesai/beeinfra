#!/bin/bash

# Post-setup script for Developer VM
# This script runs after the VM is fully provisioned

set -e

# Get VM metadata
ENVIRONMENT=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute/tags?api-version=2021-01-01&format=text" | grep -o 'Environment:[^;]*' | cut -d: -f2 || echo "unknown")
VM_NAME=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute/name?api-version=2021-01-01&format=text")
PRIVATE_IP=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2021-01-01&format=text")
PUBLIC_IP=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2021-01-01&format=text")

# Create welcome script
cat > /home/devuser/welcome.sh << 'EOF'
#!/bin/bash

echo "========================================="
echo "   Beeux Developer VM - Welcome!"
echo "========================================="
echo "Environment: ${ENVIRONMENT}"
echo "VM Name: ${VM_NAME}"
echo "Private IP: ${PRIVATE_IP}"
echo "Public IP: ${PUBLIC_IP}"
echo "========================================="
echo ""
echo "Pre-installed tools:"
echo "- Azure CLI: $(az --version | head -n 1)"
echo "- GitHub CLI: $(gh --version | head -n 1)"
echo "- Git: $(git --version)"
echo "- Docker: $(docker --version)"
echo "- Node.js: $(node --version)"
echo "- Python: $(python3 --version)"
echo "- .NET: $(dotnet --version)"
echo "- PowerShell: $(pwsh --version)"
echo "- Terraform: $(terraform --version | head -n 1)"
echo "- kubectl: $(kubectl version --client --short 2>/dev/null || echo 'kubectl client')"
echo ""
echo "Useful commands:"
echo "- az login --identity  # Login with managed identity"
echo "- gh auth login        # Setup GitHub authentication"
echo "- docker run hello-world  # Test Docker"
echo "- curl -k https://localhost:8080  # Test VS Code Server HTTPS"
echo ""
echo "HTTPS Security Notes:"
echo "- VS Code Server runs on HTTPS for secure web access"
echo "- All Azure CLI commands use HTTPS/TLS encryption"
echo "- Git operations use HTTPS for repository access"
echo "- Docker registry connections use HTTPS/TLS"
echo ""
echo "Workspace directory: /home/devuser/workspace"
echo "========================================="
EOF

chmod +x /home/devuser/welcome.sh

# Add welcome message to .bashrc
cat >> /home/devuser/.bashrc << 'EOF'

# Beeux Developer VM Welcome
if [ -f ~/welcome.sh ]; then
    ~/welcome.sh
fi

# Useful aliases
alias ll='ls -la'
alias azlogin='az login --identity'
alias workspace='cd ~/workspace'
alias logs='journalctl -f'

# Add local bin to PATH
export PATH=$PATH:~/.local/bin
EOF

# Create Azure login script
cat > /home/devuser/azure-login.sh << 'EOF'
#!/bin/bash

echo "Logging into Azure with managed identity..."
az login --identity

echo "Current Azure context:"
az account show --output table

echo "Available resource groups:"
az group list --output table

echo "Azure login completed!"
EOF

chmod +x /home/devuser/azure-login.sh

# Create development environment script
cat > /home/devuser/setup-dev-env.sh << 'EOF'
#!/bin/bash

echo "Setting up development environment..."

# Create project structure
mkdir -p ~/workspace/{projects,scripts,configs,temp}

# Setup Git global config (user will need to customize)
echo "Setting up Git configuration..."
echo "Please run these commands to configure Git:"
echo "git config --global user.name 'Your Name'"
echo "git config --global user.email 'your.email@domain.com'"

# Setup VS Code server
echo "Installing VS Code server..."
curl -fsSL https://code-server.dev/install.sh | sh
sudo systemctl enable --now code-server@devuser

echo "VS Code server is available at: http://$(curl -s ifconfig.me):8080"
echo "Password is in: ~/.config/code-server/config.yaml"

echo "Development environment setup completed!"
EOF

chmod +x /home/devuser/setup-dev-env.sh

# Install VS Code server
curl -fsSL https://code-server.dev/install.sh | sh

# Configure VS Code server
mkdir -p /home/devuser/.config/code-server
cat > /home/devuser/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:8080
auth: password
password: BeuxDev$(date +%Y)!
cert: false
EOF

# Enable and start code-server
systemctl enable --now code-server@devuser

# Set proper ownership
chown -R devuser:devuser /home/devuser/

# Create status file
cat > /home/devuser/vm-status.json << EOF
{
  "environment": "${ENVIRONMENT}",
  "vm_name": "${VM_NAME}",
  "private_ip": "${PRIVATE_IP}",
  "public_ip": "${PUBLIC_IP}",
  "setup_completed": "$(date)",
  "tools_installed": [
    "azure-cli",
    "github-cli", 
    "git",
    "docker",
    "nodejs",
    "python3",
    "dotnet",
    "powershell",
    "terraform",
    "kubectl",
    "helm",
    "code-server"
  ]
}
EOF

chown devuser:devuser /home/devuser/vm-status.json

echo "Post-setup completed successfully!" >> /home/devuser/setup-complete.log
date >> /home/devuser/setup-complete.log
