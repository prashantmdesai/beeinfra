# Ubuntu VM Infrastructure - Development Environment

This directory contains the infrastructure code and management scripts for Ubuntu development VMs in the `dev` environment. The structure is designed to scale up to 40 VMs with organized management and deployment capabilities.

## 📁 Directory Structure

```
environments/dev/
├── vms/                           # Individual VM configurations
│   ├── ubuntu-dev-01/            # First VM (template/example)
│   │   ├── bicep/                # Bicep infrastructure code
│   │   │   ├── main.bicep        # Main VM template
│   │   │   └── parameters.json   # VM-specific parameters
│   │   └── scripts/              # VM-specific management scripts
│   │       ├── deploy.sh         # Deploy this specific VM
│   │       ├── manage.sh         # Start/stop/restart/connect
│   │       └── cleanup.sh        # Delete VM and resources
│   ├── ubuntu-dev-02/            # Second VM (created when needed)
│   ├── ubuntu-dev-03/            # Third VM (created when needed)
│   └── ...                       # Up to ubuntu-dev-40
└── scripts/                      # Environment-level management
    ├── deployment/               # Deployment automation
    │   └── provision-vms.sh      # Create and deploy multiple VMs
    ├── management/               # VM management utilities
    │   └── vm-manager.sh         # Bulk start/stop/list operations
    └── shared/                   # Shared utilities and functions
        └── utils.sh              # Common functions and variables
```

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI**: Install and login
   ```bash
   az login
   ```

2. **WSL/Linux Environment**: All scripts are designed for bash/WSL

3. **SSH Key** (recommended): Generate if you don't have one
   ```bash
   ssh-keygen -t rsa -b 4096
   ```

### Deploy Your First VM

```bash
# Navigate to the dev environment
cd environments/dev

# Deploy ubuntu-dev-01 (first VM)
./vms/ubuntu-dev-01/scripts/deploy.sh

# Or use the provisioning script
./scripts/deployment/provision-vms.sh deploy ubuntu-dev-01
```

## 💰 Cost Information

**Per VM Cost Breakdown:**
- **VM (Standard_B2s)**: $30.37/month ($0.0416/hour)
- **Premium SSD (30GB)**: $6.14/month ($0.00845/hour)  
- **Static Public IP**: $3.65/month ($0.005/hour)
- **Network**: ~$0.00/month
- **Total per VM**: **$40.16/month** (~$0.056/hour)

**Scale Estimates:**
- 5 VMs: ~$200.80/month
- 10 VMs: ~$401.60/month
- 40 VMs: ~$1,606.40/month

## 🖥️ VM Specifications

Each VM is configured with:
- **Size**: Standard_B2s (2 vCPU, 4GB RAM)
- **OS**: Ubuntu 24.04 LTS
- **Storage**: 30GB Premium SSD
- **Network**: Static Public IP, full internet access
- **Ports**: SSH (22), HTTP (80), HTTPS (443), MySQL (3306), PostgreSQL (5432)
- **Security**: Network Security Group with managed rules
- **Identity**: System-assigned managed identity

## 📋 Management Commands

### Individual VM Management

```bash
# Deploy a specific VM
./vms/ubuntu-dev-01/scripts/deploy.sh

# Check VM status and info
./vms/ubuntu-dev-01/scripts/manage.sh info

# Start VM
./vms/ubuntu-dev-01/scripts/manage.sh start

# Connect via SSH
./vms/ubuntu-dev-01/scripts/manage.sh connect

# Stop VM (saves cost)
./vms/ubuntu-dev-01/scripts/manage.sh stop

# Delete VM completely
./vms/ubuntu-dev-01/scripts/cleanup.sh
```

### Bulk VM Management

```bash
# List all VMs and their status
./scripts/management/vm-manager.sh list

# Start all deployed VMs
./scripts/management/vm-manager.sh start-all

# Stop all running VMs
./scripts/management/vm-manager.sh stop-all

# Restart all running VMs
./scripts/management/vm-manager.sh restart-all

# Manage specific VM through bulk manager
./scripts/management/vm-manager.sh start ubuntu-dev-05
./scripts/management/vm-manager.sh info ubuntu-dev-02
```

### VM Provisioning (Creating New VMs)

```bash
# Create configuration for a new VM
./scripts/deployment/provision-vms.sh create ubuntu-dev-05

# Deploy a single VM
./scripts/deployment/provision-vms.sh deploy ubuntu-dev-05

# Bulk deploy multiple VMs (e.g., VMs 02-05)
./scripts/deployment/provision-vms.sh bulk 2 5

# Bulk deploy VMs 10-15
./scripts/deployment/provision-vms.sh bulk 10 15
```

## 🔧 VM Naming Convention

All VMs follow this naming pattern:
- **Format**: `ubuntu-dev-XX` (where XX is 01-40)
- **Examples**: `ubuntu-dev-01`, `ubuntu-dev-05`, `ubuntu-dev-23`
- **Azure Resource Names**: `beeinfra-dev-ubuntu-dev-XX`

## 🏗️ Creating Additional VMs

### Method 1: Using Provisioning Script (Recommended)
```bash
# Create configuration and deploy
./scripts/deployment/provision-vms.sh create ubuntu-dev-05
./scripts/deployment/provision-vms.sh deploy ubuntu-dev-05
```

### Method 2: Manual Directory Creation
```bash
# Copy the template
cp -r vms/ubuntu-dev-01 vms/ubuntu-dev-05

# Update VM name in parameters file
sed -i 's/ubuntu-dev-01/ubuntu-dev-05/g' vms/ubuntu-dev-05/bicep/parameters.json

# Update VM name in scripts
sed -i 's/ubuntu-dev-01/ubuntu-dev-05/g' vms/ubuntu-dev-05/scripts/*.sh

# Deploy
./vms/ubuntu-dev-05/scripts/deploy.sh
```

## 🔐 Security Features

- **Network Security Groups**: Configured with specific port access
- **SSH Key Authentication**: Preferred over password auth
- **System-assigned Managed Identity**: For Azure resource access
- **HTTPS-ready**: Ports 443 and 80 pre-configured
- **Database Access**: MySQL and PostgreSQL ports available

## 🛠️ Customization

### Changing VM Specifications

Edit `vms/ubuntu-dev-XX/bicep/parameters.json`:
```json
{
  "vmSize": {"value": "Standard_B4ms"},           // Larger VM
  "osDiskSizeGB": {"value": 64},                  // Bigger disk
  "ubuntuOSVersion": {"value": "22.04-LTS"},      // Different Ubuntu
  "osDiskType": {"value": "StandardSSD_LRS"}      // Different disk type
}
```

### Adding Custom Ports

Edit `vms/ubuntu-dev-XX/bicep/main.bicep` and add to `securityRules` array:
```bicep
{
  name: 'CustomApp'
  properties: {
    priority: 1006
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '8080'
  }
}
```

## 🔄 Backup and Recovery

### VM State Management
```bash
# Stop VM to save costs when not in use
./vms/ubuntu-dev-01/scripts/manage.sh stop

# Start when needed
./vms/ubuntu-dev-01/scripts/manage.sh start
```

### Complete VM Recreation
```bash
# Delete everything
./vms/ubuntu-dev-01/scripts/cleanup.sh

# Recreate from scratch
./vms/ubuntu-dev-01/scripts/deploy.sh
```

## 🐛 Troubleshooting

### Common Issues

1. **Azure CLI not logged in**
   ```bash
   az login
   ```

2. **Resource group doesn't exist**
   ```bash
   az group create --name beeinfra-dev-rg --location eastus
   ```

3. **SSH connection refused**
   ```bash
   # Check VM status
   ./vms/ubuntu-dev-01/scripts/manage.sh info
   
   # Ensure VM is running
   ./vms/ubuntu-dev-01/scripts/manage.sh start
   ```

4. **Deployment failed**
   ```bash
   # Check Azure resource status
   az deployment group list --resource-group beeinfra-dev-rg
   
   # Delete and retry
   ./vms/ubuntu-dev-01/scripts/cleanup.sh
   ./vms/ubuntu-dev-01/scripts/deploy.sh
   ```

### Getting Help

```bash
# Script help
./scripts/management/vm-manager.sh help
./scripts/deployment/provision-vms.sh help
./vms/ubuntu-dev-01/scripts/manage.sh help

# VM information
./vms/ubuntu-dev-01/scripts/manage.sh info
```

## 🚀 Scaling to 40 VMs

The infrastructure supports up to 40 VMs (ubuntu-dev-01 to ubuntu-dev-40):

```bash
# Deploy first 10 VMs
./scripts/deployment/provision-vms.sh bulk 1 10

# Deploy next batch
./scripts/deployment/provision-vms.sh bulk 11 20

# Deploy remaining VMs
./scripts/deployment/provision-vms.sh bulk 21 40
```

**Cost at Scale:**
- 40 VMs: ~$1,606.40/month when all running
- Use start/stop functionality to manage costs
- Only pay for running VMs (compute charges stop when stopped)

## 📊 Monitoring

### Check All VM Status
```bash
./scripts/management/vm-manager.sh list
```

### Individual VM Monitoring
```bash
# Get detailed VM info
./vms/ubuntu-dev-01/scripts/manage.sh info

# Monitor via Azure CLI
az vm list --resource-group beeinfra-dev-rg --show-details --output table
```

## 🔗 Related Files

- **Main Template**: `vms/ubuntu-dev-01/bicep/main.bicep`
- **Shared Utilities**: `scripts/shared/utils.sh`
- **Environment Config**: See variables in utils.sh
- **Infrastructure Instructions**: `/.github/instructions/infrasetup.instructions.md`

---

**Note**: This infrastructure is designed for development use. For production environments, consider additional security hardening, backup strategies, and monitoring solutions.
