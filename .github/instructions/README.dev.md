# Development Environment Infrastructure Documentation

**Project**: BeeInfra - Azure Infrastructure Setup  
**Environment**: Development (IT)  
**Date**: September 2025  
**Version**: 1.0

---

## 🎯 Overview

This document provides comprehensive documentation for the BeeInfra development environment infrastructure. The setup is designed to support a typical web application architecture with Angular frontend, REST APIs, and PostgreSQL database, all deployed to Azure using Infrastructure as Code (Terraform/Bicep) with cost-optimization and scalability in mind.

## 📋 Table of Contents

- [Environment Overview](#-environment-overview)
- [Architecture](#-architecture)
- [Directory Structure](#-directory-structure)
- [VM Infrastructure](#-vm-infrastructure)
- [Cost Management](#-cost-management)
- [Quick Start Guide](#-quick-start-guide)
- [Management Commands](#-management-commands)
- [Security Features](#-security-features)
- [Scaling Operations](#-scaling-operations)
- [Budget Monitoring](#-budget-monitoring)
- [Troubleshooting](#-troubleshooting)
- [Best Practices](#-best-practices)

---

## 🌟 Environment Overview

### Environment Characteristics
- **Name**: Development (dev) / IT Environment
- **Purpose**: Development and testing for Angular web app + REST APIs + PostgreSQL
- **Cost Strategy**: Free tier and lowest-cost options where possible
- **Budget Limits**: $10 monthly (with alerts)
- **VM Capacity**: Up to 40 Ubuntu development VMs
- **Auto-shutdown**: After 1 hour of inactivity

### Key Principles
1. **Cost-First Approach**: Free tier resources when available, lowest paid tier otherwise
2. **Scalable Architecture**: Support 1-40 VMs with consistent management
3. **Security by Design**: Proper NSG rules, managed identities, HTTPS-ready
4. **Developer Friendly**: WSL-compatible scripts, SSH access, full dev tooling
5. **Environment Isolation**: Clear identification and resource tagging

---

## 🏗️ Architecture

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Subscription                           │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              beeinfra-dev-rg (Resource Group)              │ │
│  │                                                             │ │
│  │  ┌─────────────────┐  ┌─────────────────┐                  │ │
│  │  │   Virtual       │  │    Network      │                  │ │
│  │  │   Network       │  │   Security      │                  │ │
│  │  │   (Shared)      │  │    Groups       │                  │ │
│  │  └─────────────────┘  └─────────────────┘                  │ │
│  │                                                             │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │ │
│  │  │ ubuntu-dev-01   │  │ ubuntu-dev-02   │  │     ...      │ │ │
│  │  │ ─────────────── │  │ ─────────────── │  │ up to VM-40  │ │ │
│  │  │ • Standard_B2s  │  │ • Standard_B2s  │  │              │ │ │
│  │  │ • Ubuntu 24.04  │  │ • Ubuntu 24.04  │  │              │ │ │
│  │  │ • 30GB Premium  │  │ • 30GB Premium  │  │              │ │ │
│  │  │ • Static IP     │  │ • Static IP     │  │              │ │ │
│  │  │ • SSH/HTTP/DB   │  │ • SSH/HTTP/DB   │  │              │ │ │
│  │  └─────────────────┘  └─────────────────┘  └──────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Budget & Alerts                              │
│  • Estimated Cost Alert: > $10/month                           │
│  • Actual Cost Alert: > $10/month                              │
│  • Email: prashantmdesai@yahoo.com, prashantmdesai@hotmail.com │
│  • SMS: +1 224 656 4855                                        │
│  • Auto-shutdown: After 1 hour inactivity                      │
└─────────────────────────────────────────────────────────────────┘
```

### Network Architecture
- **Virtual Network**: `beeinfra-dev-vnet` (10.0.0.0/16)
- **Subnet**: `beeinfra-dev-subnet` (10.0.1.0/24)
- **Public IPs**: Static per VM for direct access
- **NSG Rules**: SSH (22), HTTP (80), HTTPS (443), MySQL (3306), PostgreSQL (5432)

---

## 📁 Directory Structure

### Project Organization
```
beeinfra/
├── .github/
│   └── instructions/
│       ├── infrasetup.instructions.md    # Master infrastructure setup rules
│       ├── README.dev.md                 # This documentation file
│       ├── local-env-instructions.md     # Local development setup
│       └── initial-project-setup.instructions.md
│
└── environments/
    └── dev/                              # Development environment
        ├── README.md                     # Dev environment quick guide
        ├── vms/                          # Individual VM configurations
        │   ├── ubuntu-dev-01/            # Template VM (first instance)
        │   │   ├── bicep/
        │   │   │   ├── main.bicep        # Infrastructure template
        │   │   │   └── parameters.json   # VM-specific parameters
        │   │   └── scripts/
        │   │       ├── deploy.sh         # Deploy this specific VM
        │   │       ├── manage.sh         # VM lifecycle management
        │   │       └── cleanup.sh        # Safe VM deletion
        │   ├── ubuntu-dev-02/            # Second VM (created as needed)
        │   ├── ubuntu-dev-03/            # Third VM (created as needed)
        │   └── ...                       # Up to ubuntu-dev-40
        └── scripts/                      # Environment-level management
            ├── deployment/
            │   └── provision-vms.sh      # Create and deploy multiple VMs
            ├── management/
            │   └── vm-manager.sh         # Bulk operations (start/stop/list)
            └── shared/
                └── utils.sh              # Common functions and utilities
```

### File Purpose & Relationships
- **Template Pattern**: `ubuntu-dev-01` serves as the template for all other VMs
- **Configuration Inheritance**: All VMs inherit base config with customizable parameters
- **Script Hierarchy**: Individual VM scripts → Environment scripts → Shared utilities
- **Documentation Flow**: Master instructions → Environment docs → Quick reference

---

## 🖥️ VM Infrastructure

### Standard VM Configuration
Each development VM is configured with:

**Hardware Specifications:**
- **VM Size**: Standard_B2s (2 vCPU, 4GB RAM)
- **Storage**: 30GB Premium SSD (Premium_LRS)
- **Network**: Static Public IP + Private IP

**Software Stack:**
- **Operating System**: Ubuntu 24.04 LTS (latest)
- **Authentication**: SSH key + password fallback
- **Identity**: System-assigned managed identity
- **User Account**: `beeuser` (customizable)

**Network Security:**
- **SSH Access**: Port 22 (worldwide access)
- **Web Traffic**: Ports 80 (HTTP) and 443 (HTTPS)
- **Database Access**: Ports 3306 (MySQL) and 5432 (PostgreSQL)
- **Security Group**: VM-specific NSG with managed rules

**Azure Integration:**
- **Resource Naming**: `beeinfra-dev-ubuntu-dev-XX` pattern
- **Tagging Strategy**: Environment, Owner, Cost Center, Purpose
- **Monitoring**: Boot diagnostics disabled (cost optimization)
- **Resource Group**: `beeinfra-dev-rg`

### VM Naming Convention
- **Pattern**: `ubuntu-dev-XX` where XX is 01-40
- **Examples**: `ubuntu-dev-01`, `ubuntu-dev-05`, `ubuntu-dev-23`
- **Azure Names**: `beeinfra-dev-ubuntu-dev-01`, etc.
- **Resource Names**: Follow consistent `beeinfra-dev-*` prefix

### Supported VM Configurations
```json
{
  "vmSizes": [
    "Standard_B1s",     // 1 vCPU, 1GB RAM - $7.59/month
    "Standard_B1ms",    // 1 vCPU, 2GB RAM - $15.18/month  
    "Standard_B2s",     // 2 vCPU, 4GB RAM - $30.37/month (default)
    "Standard_B2ms",    // 2 vCPU, 8GB RAM - $60.74/month
    "Standard_D2s_v5",  // 2 vCPU, 8GB RAM - $70.08/month
    "Standard_F2s_v2"   // 2 vCPU, 4GB RAM - $83.95/month
  ],
  "osDiskTypes": [
    "Standard_LRS",     // HDD - cheapest
    "StandardSSD_LRS",  // Standard SSD
    "Premium_LRS"       // Premium SSD - fastest (default)
  ],
  "ubuntuVersions": [
    "18.04-LTS",        // Supported until 2028
    "20.04-LTS",        // Supported until 2030
    "22.04-LTS",        // Supported until 2032
    "24.04-LTS"         // Latest, supported until 2034 (default)
  ]
}
```

---

## 💰 Cost Management

### Cost Breakdown (Per VM)
```
Standard_B2s VM:          $30.37/month  ($0.0416/hour)
Premium SSD (30GB):       $6.14/month   ($0.00845/hour)
Static Public IP:         $3.65/month   ($0.005/hour)
Network Security Group:   $0.00/month
Virtual Network:          $0.00/month   (shared)
────────────────────────────────────────────────────
TOTAL PER VM:             $40.16/month  ($0.056/hour)
```

### Scale Cost Projections
| VMs | Monthly Cost | Daily Cost | Hourly Cost |
|-----|-------------|------------|-------------|
| 1   | $40.16      | $1.34      | $0.056      |
| 5   | $200.80     | $6.69      | $0.28       |
| 10  | $401.60     | $13.39     | $0.56       |
| 20  | $803.20     | $26.77     | $1.12       |
| 40  | $1,606.40   | $53.55     | $2.23       |

### Budget Alerts Configuration
**Dev Environment Limits ($10 monthly):**
- ⚠️ **Estimated Cost Alert**: Triggers at $10 projected monthly spend
- 🚨 **Actual Cost Alert**: Triggers at $10 actual monthly spend
- 📧 **Email Recipients**: prashantmdesai@yahoo.com, prashantmdesai@hotmail.com
- 📱 **SMS Alerts**: +1 224 656 4855
- ⏰ **Auto-shutdown**: All VMs stopped after 1 hour of inactivity

### Cost Optimization Strategies
1. **Auto-Stop**: VMs automatically deallocate when unused
2. **On-Demand**: Only pay for running VMs (compute charges stop when stopped)
3. **Free Tier**: Use Azure free tier resources where possible
4. **Shared Resources**: VNet and NSG shared across all VMs
5. **Right-sizing**: B2s chosen for optimal price/performance for dev work

---

## 🚀 Quick Start Guide

### Prerequisites Setup
```bash
# 1. Install Azure CLI (if not installed)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 2. Login to Azure
az login

# 3. Verify subscription
az account show

# 4. Generate SSH key (if needed)
ssh-keygen -t rsa -b 4096 -C "your.email@domain.com"

# 5. Navigate to dev environment
cd /mnt/c/dev/beeinfra/environments/dev
```

### Deploy Your First VM (ubuntu-dev-01)
```bash
# Method 1: Direct deployment
./vms/ubuntu-dev-01/scripts/deploy.sh

# Method 2: Using provisioning script
./scripts/deployment/provision-vms.sh deploy ubuntu-dev-01
```

### Create and Deploy Additional VMs
```bash
# Create configuration for a new VM
./scripts/deployment/provision-vms.sh create ubuntu-dev-05

# Deploy the new VM
./scripts/deployment/provision-vms.sh deploy ubuntu-dev-05

# Or create and deploy in one command
./scripts/deployment/provision-vms.sh create ubuntu-dev-05 && \
./scripts/deployment/provision-vms.sh deploy ubuntu-dev-05
```

### Bulk Operations
```bash
# Deploy multiple VMs at once (e.g., VMs 02-05)
./scripts/deployment/provision-vms.sh bulk 2 5

# Deploy a larger batch (e.g., VMs 10-20)
./scripts/deployment/provision-vms.sh bulk 10 20
```

---

## 🎮 Management Commands

### Individual VM Management

**Deployment Commands:**
```bash
# Deploy specific VM
./vms/ubuntu-dev-01/scripts/deploy.sh

# Deploy with custom parameters
SSH_KEY="$(cat ~/.ssh/id_rsa.pub)" ./vms/ubuntu-dev-01/scripts/deploy.sh
```

**Lifecycle Management:**
```bash
# Get VM information and status
./vms/ubuntu-dev-01/scripts/manage.sh info

# Start VM (with cost confirmation)
./vms/ubuntu-dev-01/scripts/manage.sh start

# Stop VM (deallocate to save costs)
./vms/ubuntu-dev-01/scripts/manage.sh stop

# Restart running VM
./vms/ubuntu-dev-01/scripts/manage.sh restart

# Connect via SSH
./vms/ubuntu-dev-01/scripts/manage.sh connect
```

**Cleanup Commands:**
```bash
# Safely delete VM and all resources (with triple confirmation)
./vms/ubuntu-dev-01/scripts/cleanup.sh
```

### Bulk VM Management

**Status and Information:**
```bash
# List all VMs with status and cost info
./scripts/management/vm-manager.sh list

# Show cost breakdown for all deployed VMs
./scripts/management/vm-manager.sh list
```

**Bulk Operations:**
```bash
# Start all deployed VMs (with cost confirmation)
./scripts/management/vm-manager.sh start-all

# Stop all running VMs (immediate cost savings)
./scripts/management/vm-manager.sh stop-all

# Restart all running VMs
./scripts/management/vm-manager.sh restart-all
```

**Individual VM Operations via Bulk Manager:**
```bash
# Manage specific VMs through bulk interface
./scripts/management/vm-manager.sh start ubuntu-dev-05
./scripts/management/vm-manager.sh stop ubuntu-dev-03
./scripts/management/vm-manager.sh info ubuntu-dev-10
./scripts/management/vm-manager.sh restart ubuntu-dev-01
```

### VM Creation and Provisioning

**Single VM Creation:**
```bash
# Create VM configuration only
./scripts/deployment/provision-vms.sh create ubuntu-dev-08

# Deploy existing configuration
./scripts/deployment/provision-vms.sh deploy ubuntu-dev-08
```

**Bulk VM Provisioning:**
```bash
# Create and deploy VM range
./scripts/deployment/provision-vms.sh bulk 15 20

# Large scale deployment
./scripts/deployment/provision-vms.sh bulk 1 40  # All 40 VMs
```

---

## 🔐 Security Features

### Network Security
- **Network Security Groups (NSG)**: Each VM has dedicated NSG
- **Port Management**: Only required ports opened (SSH, HTTP, HTTPS, DB)
- **IP Restrictions**: Can be customized per environment needs
- **HTTPS-Ready**: Port 443 pre-configured for secure web traffic

### Authentication & Authorization
- **SSH Key Authentication**: Preferred method with password fallback
- **System-Assigned Managed Identity**: Each VM gets Azure AD identity
- **Azure RBAC**: Proper role assignments for resource access
- **Key Management**: SSH keys managed locally, secrets in Azure Key Vault

### Security Groups Configuration
```json
{
  "securityRules": [
    {"name": "SSH", "port": 22, "priority": 1001},
    {"name": "HTTP", "port": 80, "priority": 1002},
    {"name": "HTTPS", "port": 443, "priority": 1003},
    {"name": "MySQL", "port": 3306, "priority": 1004},
    {"name": "PostgreSQL", "port": 5432, "priority": 1005}
  ]
}
```

### Data Protection
- **Managed Disks**: Built-in encryption at rest
- **Network Isolation**: Private subnet with controlled access
- **Resource Tagging**: Clear ownership and purpose identification
- **Audit Logging**: Azure activity logs for all resource changes

---

## 📈 Scaling Operations

### Horizontal Scaling (Adding VMs)

**Small Scale (1-5 VMs):**
```bash
# Add single VMs as needed
./scripts/deployment/provision-vms.sh create ubuntu-dev-02
./scripts/deployment/provision-vms.sh deploy ubuntu-dev-02
```

**Medium Scale (5-20 VMs):**
```bash
# Deploy batches to avoid resource conflicts
./scripts/deployment/provision-vms.sh bulk 5 10
sleep 300  # 5 minute pause
./scripts/deployment/provision-vms.sh bulk 11 15
```

**Large Scale (20-40 VMs):**
```bash
# Deploy in stages with monitoring
for start in 01 11 21 31; do
  end=$((start + 9))
  echo "Deploying VMs $start to $end"
  ./scripts/deployment/provision-vms.sh bulk $start $end
  echo "Waiting 10 minutes before next batch..."
  sleep 600
done
```

### Vertical Scaling (VM Sizing)
To change VM sizes, edit `parameters.json`:
```json
{
  "vmSize": {"value": "Standard_B4ms"},    // 4 vCPU, 16GB RAM
  "osDiskSizeGB": {"value": 64}            // Larger disk
}
```

### Auto-Scaling Considerations
- **Manual Scaling**: Current setup requires manual VM management
- **Cost Control**: Each scale operation shows cost impact
- **Resource Limits**: Monitor Azure subscription quotas
- **Network Planning**: Subnet can support up to ~250 VMs

---

## 📊 Budget Monitoring

### Automated Alerts System

**Alert Configuration:**
```yaml
Dev Environment Budget: $10/month
Alert Thresholds:
  - Estimated Cost: $10 (100% of budget)
  - Actual Cost: $10 (100% of budget)
  
Notification Channels:
  - Email: 
    - prashantmdesai@yahoo.com
    - prashantmdesai@hotmail.com
  - SMS: +1 224 656 4855

Auto-Actions:
  - Shutdown unused VMs after 1 hour
  - Daily cost reports
  - Weekly usage summaries
```

### Cost Monitoring Commands
```bash
# Check current costs
az consumption usage list --top 5

# Monitor resource group costs
az consumption usage list --start-date 2025-09-01 --end-date 2025-09-30

# Get budget information
az consumption budget list --resource-group beeinfra-dev-rg
```

### Manual Cost Control
```bash
# Stop all VMs to minimize costs
./scripts/management/vm-manager.sh stop-all

# Check which VMs are running (costing money)
./scripts/management/vm-manager.sh list

# Start only needed VMs
./scripts/management/vm-manager.sh start ubuntu-dev-01
```

### Cost Optimization Checklist
- ✅ **Stop unused VMs**: Use `stop` commands regularly
- ✅ **Monitor daily**: Check VM status daily
- ✅ **Right-size**: Use appropriate VM sizes for workload
- ✅ **Delete unused**: Remove test VMs promptly
- ✅ **Schedule operations**: Plan dev work to minimize runtime
- ✅ **Use alerts**: Respond promptly to budget notifications

---

## 🔧 Troubleshooting

### Common Issues & Solutions

**1. Azure CLI Authentication Issues**
```bash
# Problem: "Please run 'az login' to setup account"
# Solution:
az login
az account set --subscription "your-subscription-id"
```

**2. SSH Connection Failures**
```bash
# Problem: Connection timeout or refused
# Diagnosis:
./vms/ubuntu-dev-01/scripts/manage.sh info

# Solutions:
# If VM is stopped:
./vms/ubuntu-dev-01/scripts/manage.sh start

# If NSG issue:
az network nsg rule list --resource-group beeinfra-dev-rg --nsg-name beeinfra-dev-ubuntu-dev-01-nsg
```

**3. Deployment Failures**
```bash
# Problem: Bicep deployment fails
# Diagnosis:
az deployment group list --resource-group beeinfra-dev-rg --query '[0].properties.error'

# Solutions:
# Check resource limits:
az vm list-usage --location eastus

# Clean up failed deployment:
./vms/ubuntu-dev-01/scripts/cleanup.sh
```

**4. Cost Limit Exceeded**
```bash
# Problem: Budget alert triggered
# Immediate action:
./scripts/management/vm-manager.sh stop-all

# Analysis:
./scripts/management/vm-manager.sh list
az consumption usage list --top 10
```

**5. Resource Group Issues**
```bash
# Problem: Resource group doesn't exist
# Solution:
az group create --name beeinfra-dev-rg --location eastus --tags Environment=dev
```

**6. Permission Denied on Scripts**
```bash
# Problem: bash: permission denied
# Solution:
chmod +x environments/dev/vms/ubuntu-dev-01/scripts/*.sh
chmod +x environments/dev/scripts/*/*.sh
```

### Diagnostic Commands
```bash
# Check all VMs in resource group
az vm list --resource-group beeinfra-dev-rg --output table

# Check deployment history
az deployment group list --resource-group beeinfra-dev-rg --output table

# Check current costs
az consumption usage list --resource-group beeinfra-dev-rg

# Test network connectivity
nmap -p 22,80,443 <vm-public-ip>
```

### Log Locations
- **Script Logs**: `/tmp/beeinfra-vm-actions.log`
- **Azure Activity**: Azure Portal > Activity Log
- **VM Boot**: Azure Portal > VM > Boot diagnostics (if enabled)
- **Deployment**: Azure Portal > Resource Group > Deployments

---

## 📚 Best Practices

### Development Workflow
1. **Start Small**: Begin with 1-2 VMs, scale as needed
2. **Use Templates**: Always base new VMs on `ubuntu-dev-01` template
3. **Tag Everything**: Proper tagging for cost tracking and management
4. **Monitor Costs**: Daily cost checks, respond to alerts promptly
5. **Clean Up**: Remove unused VMs and resources regularly

### Script Usage
```bash
# Always check status before operations
./scripts/management/vm-manager.sh list

# Confirm costs before bulk operations  
./scripts/deployment/provision-vms.sh bulk 5 10  # Shows cost estimate

# Use meaningful VM numbers
# Good: ubuntu-dev-01, ubuntu-dev-02 (sequential)
# Avoid: random numbers without pattern
```

### Security Best Practices
1. **SSH Keys**: Always use SSH keys over passwords
2. **Regular Updates**: Keep VMs updated with latest security patches
3. **Least Privilege**: Only open required ports in NSG
4. **Monitor Access**: Review SSH access logs regularly
5. **Resource Isolation**: Use separate resource groups for different projects

### Cost Management
1. **Stop When Not Used**: Always stop VMs when not actively developing
2. **Monitor Daily**: Check running VMs and costs daily
3. **Right-Size**: Use appropriate VM sizes for your workload
4. **Schedule Work**: Plan development work to minimize VM runtime
5. **Set Budgets**: Use Azure budgets with alerts

### Maintenance Schedule
```yaml
Daily:
  - Check running VMs: ./scripts/management/vm-manager.sh list
  - Stop unused VMs: ./scripts/management/vm-manager.sh stop <vm-name>
  
Weekly:
  - Review cost reports
  - Update VM security patches
  - Clean up unused resources
  
Monthly:
  - Review and optimize VM sizes
  - Update infrastructure templates
  - Audit security configurations
```

---

## 📞 Support & Contact

### Documentation Hierarchy
1. **This File**: Comprehensive dev environment documentation
2. **environments/dev/README.md**: Quick reference and commands
3. **infrasetup.instructions.md**: Master infrastructure rules and requirements
4. **Script Help**: All scripts have `--help` or `help` commands

### Getting Help
```bash
# Script-specific help
./scripts/management/vm-manager.sh help
./scripts/deployment/provision-vms.sh help
./vms/ubuntu-dev-01/scripts/manage.sh help

# Azure CLI help
az vm --help
az group --help
```

### Emergency Procedures

**Budget Exceeded:**
1. Immediately stop all VMs: `./scripts/management/vm-manager.sh stop-all`
2. Review costs: `az consumption usage list`
3. Clean up unused resources
4. Adjust development schedule

**Security Incident:**
1. Immediately stop affected VMs
2. Review Azure activity logs
3. Check NSG configurations
4. Rotate SSH keys if needed

**Infrastructure Issues:**
1. Check Azure service health
2. Review deployment logs
3. Use cleanup/redeploy cycle
4. Escalate to Azure support if needed

---

## 📅 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Sept 2025 | Initial dev environment setup with scalable VM infrastructure |

---

**Last Updated**: September 9, 2025  
**Next Review**: October 2025  
**Maintained By**: Development Team

---

*This documentation is part of the BeeInfra project infrastructure setup. For updates and changes, please maintain version history and update all related documentation files.*
