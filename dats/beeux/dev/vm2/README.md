# DATS-BEEUX-DEV-APPS VM - Infrastructure as Code

## Overview

This directory contains the Infrastructure as Code (IaC) templates for deploying **dats-beeux-dev-apps** VM (VM2) of the development environment. This VM is configured for application services and uses a **separate disk** and different **availability zone** for redundancy.

## 🚫 Important: Disk Sharing Limitation

**❌ Cannot share disks between VM1 and VM2**
- Azure doesn't allow a single managed disk to be attached to multiple VMs simultaneously
- Each VM requires its own dedicated disk for data integrity and consistency
- VM2 gets a fresh 30GB Premium SSD disk with new Ubuntu installation

## 📁 File Structure

```
vm2/
├── dats-beeux-dev-vm2-main.bicep           # Main deployment template
├── dats-beeux-dev-vm2-parameters.json      # Deployment parameters
├── deploy-vm2.ps1                          # PowerShell deployment script
├── modules/
│   ├── dats-beeux-dev-vm2-networking.bicep # Network configuration (reuses VM1)
│   └── dats-beeux-dev-vm2.bicep            # VM configuration
├── scripts/
│   └── dats-beeux-dev-vm2-software-installer.sh # Software installation
└── README.md                               # This file
```

## ⚙️ VM2 Configuration

### Hardware Specifications
- **VM Size**: Standard_B2ms
- **vCPUs**: 2
- **RAM**: 8GB
- **OS Disk**: 30GB Premium SSD (NEW - not shared)
- **Availability Zone**: 3 (different from VM1's zone 2)

### Software Stack (Fresh Installation)
- **OS**: Ubuntu 22.04 LTS
- **Docker & Docker Compose**: Latest
- **Node.js**: 20.x
- **Python**: 3.x with pip
- **Go**: 1.21.4
- **Kubernetes Tools**: kubectl, minikube, helm
- **HashiCorp Vault**: Latest
- **Database Clients**: PostgreSQL, Redis
- **Development Tools**: git, vim, htop, etc.

### Network Configuration
- **Resource Group**: rg-dev-eastus (shared with VM1)
- **VNet**: vnet-dev-eastus (shared with VM1)
- **Subnet**: subnet-dev-default (shared with VM1)
- **NSG**: nsg-dev-ubuntu-vm (shared with VM1)
- **Public IP**: New static IP (separate from VM1)
- **Private IP**: Dynamic assignment

## 💰 Cost Analysis

### VM2 Monthly Cost
```
VM Compute (Standard_B2ms):  $59.67/month
Storage (30GB Premium SSD):  $6.14/month
Public IP (Static):          $3.65/month
--------------------------------
Total VM2:                   $69.46/month
```

### Combined VM1 + VM2 Cost
```
VM1 Total:                   $69.46/month
VM2 Total:                   $69.46/month
--------------------------------
Combined Total:              $138.92/month
```

### Cost Comparison
| Component | VM1 | VM2 | Combined |
|-----------|-----|-----|----------|
| VM Compute | $59.67 | $59.67 | $119.34 |
| Storage | $6.14 | $6.14 | $12.28 |
| Public IP | $3.65 | $3.65 | $7.30 |
| **Total** | **$69.46** | **$69.46** | **$138.92** |

**Note**: Costs shown for 24/7 operation. Actual costs depend on usage patterns.

## 🚀 Deployment Instructions

### Prerequisites
1. Azure CLI or PowerShell Az module installed
2. Azure subscription access
3. SSH key pair (optional but recommended)

### Option 1: PowerShell Deployment (Recommended)

```powershell
# Navigate to VM2 directory
cd c:\dev\beeinfra\dats\beeux\dev\vm2

# Run What-If analysis first
.\deploy-vm2.ps1 -AdminPassword "YourSecurePassword123!" -WhatIf

# Deploy VM2
.\deploy-vm2.ps1 -AdminPassword "YourSecurePassword123!"

# With SSH key (recommended)
.\deploy-vm2.ps1 -AdminPassword "YourSecurePassword123!" -SshPublicKey "ssh-rsa AAAAB3NzaC1yc2E..."
```

### Option 2: Azure CLI Deployment

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "f82e8e5e-cf53-4ef7-b717-dacc295d4ee4"

# Deploy VM2
az deployment sub create \
  --location eastus \
  --template-file dats-beeux-dev-vm2-main.bicep \
  --parameters adminPassword="YourSecurePassword123!" \
  --name "dats-beeux-dev-vm2-$(date +%Y%m%d-%H%M%S)"
```

## 🔑 Access Configuration

### SSH Access
After deployment, you can access VM2 via SSH:

```bash
# Using password authentication
ssh beeuser@<VM2_PUBLIC_IP>

# Using SSH key (if configured)
ssh -i ~/.ssh/your_private_key beeuser@<VM2_PUBLIC_IP>
```

### Service Access
VM2 will have the same port configuration as VM1:
- **All development services** exposed on standard ports
- **WiFi network access** (192.168.86.0/24) configured
- **Same NSG rules** as VM1

## 📈 Disk Expansion Capability

✅ **Both VM1 and VM2 disks can be expanded in the future:**

```bash
# Expand disk to 60GB (example)
az disk update \
  --resource-group rg-dev-eastus \
  --name dats-beeux-dev-vm2-osdisk \
  --size-gb 60

# Then resize filesystem on the VM
sudo resize2fs /dev/sda1
```

**Disk expansion benefits:**
- ✅ Can increase size online (no downtime)
- ✅ Both OS and data disks supported
- ❌ Cannot decrease size (Azure limitation)
- ✅ No impact on other VM's disk

## 🔄 High Availability Setup

With both VM1 and VM2:
- **VM1**: Availability Zone 2
- **VM2**: Availability Zone 3
- **Redundancy**: Services can run on both VMs
- **Load balancing**: Can distribute workload
- **Failover**: One VM can handle load if other is down

## 📋 Post-Deployment Checklist

### Immediate (0-10 minutes)
- [ ] VM deployment successful
- [ ] SSH connection working
- [ ] Software installation script running

### Short-term (10-30 minutes)
- [ ] Software installation completed
- [ ] Docker service running
- [ ] All development tools installed
- [ ] Review installation summary

### Configuration (30-60 minutes)
- [ ] Clone development repositories
- [ ] Configure development environment
- [ ] Test all development tools
- [ ] Set up additional services as needed

## 🛠️ Differences from VM1

| Aspect | VM1 | VM2 |
|--------|-----|-----|
| **Disk** | Existing disk (reused) | New disk (fresh install) |
| **Availability Zone** | Zone 2 | Zone 3 |
| **Software** | Preserved from previous | Fresh installation |
| **Data** | Existing development data | Clean slate |
| **IP Address** | 172.191.147.143 | New IP assigned |
| **Installation** | Skip software install | Full software install |

## 🔧 Maintenance Operations

### Start/Stop VMs
```bash
# Stop VM2 (saves compute costs)
az vm stop --resource-group rg-dev-eastus --name dats-beeux-dev-vm2

# Start VM2
az vm start --resource-group rg-dev-eastus --name dats-beeux-dev-vm2

# Check status
az vm get-instance-view --resource-group rg-dev-eastus --name dats-beeux-dev-vm2
```

### Monitor Costs
```bash
# Get current month costs for resource group
az consumption usage list \
  --start-date $(date -d "1 month ago" +%Y-%m-01) \
  --end-date $(date +%Y-%m-%d)
```

## 🚨 Important Notes

1. **No Shared Storage**: VM1 and VM2 cannot share the same disk
2. **Network Sharing**: Both VMs share the same VNet and NSG rules
3. **Cost Doubling**: Running both VMs doubles the infrastructure cost
4. **Zone Redundancy**: VMs in different zones provide high availability
5. **Fresh Installation**: VM2 gets completely fresh software installation

## 📞 Support & Troubleshooting

### Common Issues
- **SSH not working**: Check NSG rules and public IP
- **Software installation failed**: Check `/var/log/vm2-software-install.log`
- **High costs**: Consider auto-shutdown schedules
- **Network connectivity**: Verify NSG and UFW firewall rules

### Log Files
- **Deployment**: Azure portal deployment history
- **Software Installation**: `/var/log/vm2-software-install.log`
- **Installation Summary**: `/home/beeuser/vm2-installation-summary.txt`

---

**Need Help?** Review the deployment logs in Azure portal or check the software installation logs on the VM itself.