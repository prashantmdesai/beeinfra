# DATS-BEEUX-DEV VM1 - Infrastructure as Code

This directory contains Bicep templates and scripts to deploy the `dats-beeux-dev` virtual machine with **disk reuse** from the existing `dev-scsm-vault` VM.

## 🎯 Overview

The `dats-beeux-dev` VM is created by reusing the existing disk from `dev-scsm-vault`, preserving all data, configurations, and installed software while upgrading the VM to Standard_B2ms (8GB RAM).

## 📁 Directory Structure

```
dats/beeux/dev/vm1/
├── dats-beeux-dev-vm1-main.bicep           # Main deployment template
├── dats-beeux-dev-vm1-parameters.json      # Deployment parameters
├── modules/
│   ├── dats-beeux-dev-networking.bicep     # Network infrastructure
│   └── dats-beeux-dev-vm.bicep             # VM configuration
├── scripts/
│   ├── deploy-with-disk-reuse.ps1          # PowerShell deployment script
│   └── deploy-with-disk-reuse.sh           # Bash deployment script
└── README.md                               # This file
```

## 🔧 Key Features

### VM Configuration
- **VM Size**: Standard_B2ms (2 vCPU, 8GB RAM) - **upgraded from B2s**
- **OS**: Ubuntu 24.04 LTS (existing disk)
- **Zone**: Zone 1 (updated from Zone 2)
- **Identity**: SystemAssigned managed identity
- **Security**: TrustedLaunch with SecureBoot and vTPM

### Disk Reuse Strategy
- **Source Disk**: `/subscriptions/f82e8e5e-cf53-4ef7-b717-dacc295d4ee4/resourceGroups/beeinfra-dev-rg/providers/Microsoft.Compute/disks/dev-scsm-vault_OsDisk_1_b230a675a9f34aaaa7f750e7d041b061`
- **Size**: 30GB Premium_LRS
- **Reuse Method**: Attach existing disk (preserves all data)
- **Benefits**: 
  - ✅ All software and configurations preserved
  - ✅ All data intact
  - ✅ SSH keys work immediately
  - ✅ No reinstallation needed

### Network Configuration
- **VNet**: 10.0.0.0/16
- **Subnet**: 10.0.1.0/24
- **Public IP**: Static with DNS name
- **NSG Rules** (matching existing VM):
  - SSH (22) from specific IPs: 136.56.79.92, 172.17.64.1, 192.168.86.28
  - HTTP (80) from anywhere
  - HTTPS (443) from anywhere
  - Port 8200 from specific IPs
  - Ports 8888-8889 from specific IPs

### Extensions & Features
- **AADSSHLoginForLinux**: Azure AD authentication
- **Auto-shutdown**: 05:00 UTC daily with email notifications
- **Boot Diagnostics**: Enabled
- **Monitoring**: Basic monitoring enabled

## 🚀 Deployment Process

### Prerequisites

1. **Azure CLI** installed and authenticated
2. **Access to both subscriptions**:
   - Source: `f82e8e5e-cf53-4ef7-b717-dacc295d4ee4` (where dev-scsm-vault exists)
   - Target: `d1f25f66-8914-4652-bcc4-8c6e0e0f1216` (where dats-beeux-dev will be created)
3. **Permissions** to manage VMs and disks in both subscriptions

### Option 1: Automated Deployment (Recommended)

Use the provided PowerShell script:

```powershell
# Navigate to the VM directory
cd C:\dev\beeinfra\dats\beeux\dev\vm1

# Run deployment script (with confirmation prompts)
.\scripts\deploy-with-disk-reuse.ps1

# Or run in what-if mode to see what would happen
.\scripts\deploy-with-disk-reuse.ps1 -WhatIf
```

Use the bash script (Linux/WSL):

```bash
# Navigate to the VM directory
cd /c/dev/beeinfra/dats/beeux/dev/vm1

# Make script executable and run
chmod +x scripts/deploy-with-disk-reuse.sh
./scripts/deploy-with-disk-reuse.sh
```

### Option 2: Manual Step-by-Step Deployment

1. **Stop the existing VM**:
   ```bash
   az account set --subscription f82e8e5e-cf53-4ef7-b717-dacc295d4ee4
   az vm stop --resource-group beeinfra-dev-rg --name dev-scsm-vault
   ```

2. **Delete the existing VM** (disk will remain due to `deleteOption: Detach`):
   ```bash
   az vm delete --resource-group beeinfra-dev-rg --name dev-scsm-vault --yes
   ```

3. **Switch to target subscription**:
   ```bash
   az account set --subscription d1f25f66-8914-4652-bcc4-8c6e0e0f1216
   ```

4. **Deploy the new VM**:
   ```bash
   az deployment sub create \
     --template-file dats-beeux-dev-vm1-main.bicep \
     --parameters dats-beeux-dev-vm1-parameters.json \
     --location centralus \
     --name "dats-beeux-dev-$(date +%Y%m%d-%H%M%S)"
   ```

## 🔍 Template Validation

Validate templates before deployment:

```bash
# Validate main template
az deployment sub validate \
  --template-file dats-beeux-dev-vm1-main.bicep \
  --parameters dats-beeux-dev-vm1-parameters.json \
  --location centralus

# Test what-if deployment
az deployment sub what-if \
  --template-file dats-beeux-dev-vm1-main.bicep \
  --parameters dats-beeux-dev-vm1-parameters.json \
  --location centralus
```

## 📋 Configuration Details

### Parameters (dats-beeux-dev-vm1-parameters.json)

| Parameter | Value | Description |
|-----------|-------|-------------|
| `location` | `centralus` | Deployment region |
| `vmName` | `dats-beeux-dev` | New VM name |
| `adminUsername` | `beeuser` | Admin username |
| `vmSize` | `Standard_B2ms` | **Upgraded** VM size (8GB RAM) |
| `availabilityZone` | `2` | Zone placement (matches source) |
| `existingOsDiskId` | `[full-disk-resource-id]` | Source disk to reuse |
| `sshPublicKey` | `[existing-key]` | **Same SSH key** as original |

### Resource Names

| Resource Type | Name | Description |
|---------------|------|-------------|
| Resource Group | `rg-dev-centralus` | Target resource group |
| Virtual Machine | `dats-beeux-dev` | New VM instance |
| Public IP | `pip-dats-beeux-dev` | Static public IP |
| Network Interface | `nic-dats-beeux-dev` | VM network interface |
| Virtual Network | `vnet-dev-eastus` | Virtual network |
| Subnet | `snet-ubuntu-vm` | VM subnet |
| NSG | `nsg-dev-ubuntu-vm` | Network security group |

## 🔐 Security Configuration

### Network Security Group Rules

| Priority | Name | Port | Protocol | Source | Direction |
|----------|------|------|----------|---------|-----------|
| 1000 | SSH | 22 | TCP | Specific IPs | Inbound |
| 1010 | HTTP | 80 | TCP | Any | Inbound |
| 1020 | HTTPS | 443 | TCP | Any | Inbound |
| 1030 | Port8200 | 8200 | TCP | Specific IPs | Inbound |
| 1040 | Port8888-8889 | 8888-8889 | TCP | Specific IPs | Inbound |

### SSH Access

- **Authentication**: SSH key-only (password authentication disabled)
- **Azure AD Integration**: AADSSHLoginForLinux extension enabled
- **Existing Keys**: All existing SSH keys preserved with disk reuse

## 💰 Cost Estimation

| Component | Monthly Cost (24/7) |
|-----------|---------------------|
| VM Compute (Standard_B2ms) | ~$59.47 |
| Storage (30GB Premium SSD) | ~$6.14 |
| Public IP (Static) | ~$3.65 |
| **Total** | **~$69.26** |

*Note: Costs shown for 24/7 operation. Actual costs depend on usage and auto-shutdown configuration.*

## 🔄 Post-Deployment

### Immediate Steps

1. **Test SSH connectivity**:
   ```bash
   ssh beeuser@[public-ip]
   ```

2. **Verify disk and data**:
   ```bash
   df -h
   ls -la /home/beeuser
   # All data should be preserved
   ```

3. **Check VM specifications**:
   ```bash
   # Verify RAM upgrade
   free -h
   # Should show ~8GB total memory
   
   # Verify CPU
   nproc
   # Should show 2 cores
   ```

### Verification Checklist

- [ ] SSH access works with existing keys
- [ ] All data and configurations preserved
- [ ] VM shows Standard_B2ms specifications (8GB RAM)
- [ ] Network connectivity functional
- [ ] Auto-shutdown schedule active
- [ ] All required software still installed

## 🛠️ Troubleshooting

### Common Issues

1. **Template validation errors**:
   - Check parameter file syntax
   - Verify disk resource ID is correct
   - Ensure subscriptions are accessible

2. **Deployment failures**:
   - Verify source VM is deleted
   - Check disk is in "Unattached" state
   - Confirm permissions in target subscription

3. **SSH connectivity issues**:
   - Verify NSG rules are applied
   - Check public IP assignment
   - Confirm SSH key is correct

### Useful Commands

```bash
# Check disk status
az disk show --resource-group beeinfra-dev-rg --name dev-scsm-vault_OsDisk_1_b230a675a9f34aaaa7f750e7d041b061

# Check deployment status
az deployment sub show --name [deployment-name]

# View VM details
az vm show --resource-group rg-dev-eastus --name dats-beeux-dev
```

## 📞 Support

For issues or questions:

1. Check template validation first
2. Review Azure Activity Log for deployment errors
3. Verify all prerequisites are met
4. Check NSG rules and connectivity

## 🏷️ Tags

All resources are tagged with:
- `Environment`: `dev`
- `Project`: `dats-beeux-dev`
- `Owner`: `prashant@devu.com`
- `azd-env-name`: `dats-beeux-dev`

---

**⚠️ Important Notes:**

- **Disk Reuse**: This process permanently moves the disk from dev-scsm-vault to dats-beeux-dev
- **No Data Loss**: All existing data, configurations, and software are preserved
- **SSH Keys**: Existing SSH keys continue to work without changes
- **Memory Upgrade**: VM gets upgraded from 4GB to 8GB RAM while preserving all data
- **Cross-Subscription**: Deployment creates resources in a different subscription than the source disk