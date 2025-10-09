# Environment Setup Guide

This guide explains how to configure and manage multiple environments (development, staging, production) using this infrastructure codebase.

## Table of Contents

1. [Overview](#overview)
2. [Environment Structure](#environment-structure)
3. [Creating New Environments](#creating-new-environments)
4. [Configuration Management](#configuration-management)
5. [State Management](#state-management)
6. [Environment Promotion](#environment-promotion)
7. [Best Practices](#best-practices)

---

## Overview

### Current Setup

Currently, this project has:
- **Dev Environment**: Fully configured in `terraform/environments/dev/`

### Future Environments

Recommended structure for additional environments:
- **Staging**: Pre-production testing
- **Production**: Live environment

### Key Differences Between Environments

| Aspect | Development | Staging | Production |
|--------|-------------|---------|------------|
| **Purpose** | Development & testing | Pre-production validation | Live production |
| **VM Count** | 5 (1 master + 4 workers) | 5-7 (1-3 masters + 4 workers) | 7-15 (3-5 masters + 4-10 workers) |
| **VM Size** | Standard_D2s_v3 | Standard_D4s_v3 | Standard_D8s_v3 or larger |
| **High Availability** | Single master (no HA) | Multi-master setup | Multi-master + availability zones |
| **Storage** | Standard LRS | Standard ZRS | Premium ZRS |
| **Backups** | Weekly | Daily | Hourly + geo-redundant |
| **Access** | Open from laptop/WiFi | VPN only | VPN + jump server |
| **Cost** | ~$214/month | ~$500/month | ~$1,500+/month |

---

## Environment Structure

### Recommended Directory Layout

```
beeinfra/
├── terraform/
│   ├── modules/              # Shared modules (no changes needed)
│   │   ├── resource-group/
│   │   ├── networking/
│   │   ├── storage/
│   │   └── virtual-machine/
│   └── environments/         # Environment-specific configurations
│       ├── dev/              # Development (current)
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   ├── terraform.tfvars
│       │   ├── vm1-infr1-dev.tfvars
│       │   ├── vm2-secu1-dev.tfvars
│       │   ├── vm3-ntwk1-dev.tfvars
│       │   ├── vm4-appl1-dev.tfvars
│       │   └── vm5-data1-dev.tfvars
│       ├── staging/          # Staging (future)
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   ├── terraform.tfvars
│       │   └── vm*.tfvars (7 files)
│       └── prod/             # Production (future)
│           ├── main.tf
│           ├── variables.tf
│           ├── outputs.tf
│           ├── terraform.tfvars
│           └── vm*.tfvars (15 files)
├── scripts/                  # Scripts (shared across environments)
├── cloud-init/              # Cloud-init templates (shared)
└── docs/                    # Documentation
```

### Configuration Files Per Environment

Each environment needs:
1. **main.tf**: Orchestration file (calls modules)
2. **variables.tf**: Variable definitions
3. **outputs.tf**: Output definitions
4. **terraform.tfvars**: General configuration
5. **vm*.tfvars**: Per-VM configuration (one file per VM)

---

## Creating New Environments

### Step 1: Create Directory Structure

```bash
# Create staging environment
cd terraform/environments
mkdir -p staging
cd staging

# Copy from dev as template
cp ../dev/main.tf .
cp ../dev/variables.tf .
cp ../dev/outputs.tf .
cp ../dev/terraform.tfvars.example terraform.tfvars
cp ../dev/vm*.tfvars.example .
```

### Step 2: Update Configuration Files

**Update terraform.tfvars**:
```hcl
# terraform/environments/staging/terraform.tfvars

# Environment Configuration
environment = "staging"
location    = "Canada Central"  # Or different region

# Project Details
project_name = "dats-beeux"

# Resource Group
resource_group_name = "dats-beeux-staging-rg"

# Networking
vnet_name          = "dats-beeux-staging-vnet"
vnet_address_space = ["10.1.0.0/16"]  # Different from dev
subnet_name        = "dats-beeux-staging-subnet"
subnet_prefix      = "10.1.1.0/24"

# Network Security Group
nsg_name = "dats-beeux-staging-nsg"

# Storage Account
storage_account_name = "datsbeuxstagingstacct"  # Must be globally unique
file_share_name      = "dats-beeux-staging-shaf-afs"
file_share_quota_gb  = 200  # Larger than dev

# Kubernetes Configuration
k8s_version     = "1.30"
k8s_pod_cidr    = "192.168.0.0/16"
k8s_service_cidr = "10.96.0.0/12"

# Access Control (VPN only for staging)
allowed_source_ips = [
    "YOUR_VPN_IP/32",
    "OFFICE_IP/32"
]

# Azure Credentials
storage_access_key = "your_storage_access_key_here"  # DO NOT commit real value
github_pat         = "your_github_pat_here"          # DO NOT commit real value
```

**Update VM tfvars files**:
```bash
# Rename and update each VM file
mv vm1-infr1-dev.tfvars.example vm1-infr1-staging.tfvars

# Edit vm1-infr1-staging.tfvars
vm_name              = "vm1-infr1-staging"
vm_size              = "Standard_D4s_v3"  # Larger for staging
admin_username       = "beeuser"
private_ip_address   = "10.1.1.4"  # Match staging subnet
enable_public_ip     = true
os_disk_size_gb      = 50  # Larger disk
is_master_node       = true

# Repeat for other VMs (vm2-vm7)
```

### Step 3: Update main.tf References

```hcl
# terraform/environments/staging/main.tf

# Update VM module calls with correct tfvars files
module "vm1_infr1" {
  source = "../../modules/virtual-machine"
  
  # Load from staging-specific tfvars
  vm_name = var.vm1_name  # From vm1-infr1-staging.tfvars
  # ... other variables
}

# Add more VMs for staging (vm6, vm7 if needed)
module "vm6_appl2" {
  source = "../../modules/virtual-machine"
  # ... configuration
}
```

### Step 4: Initialize Environment

```bash
cd terraform/environments/staging

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review plan
terraform plan \
  -var-file="terraform.tfvars" \
  -var-file="vm1-infr1-staging.tfvars" \
  -var-file="vm2-secu1-staging.tfvars" \
  -var-file="vm3-ntwk1-staging.tfvars" \
  -var-file="vm4-appl1-staging.tfvars" \
  -var-file="vm5-data1-staging.tfvars" \
  -var-file="vm6-appl2-staging.tfvars" \
  -var-file="vm7-data2-staging.tfvars"
```

---

## Configuration Management

### Shared Configuration

**Modules** (in `terraform/modules/`) are shared across all environments:
- No changes needed when adding environments
- Updates to modules affect all environments
- Test module changes in dev first

### Environment-Specific Configuration

**Variables** differ per environment:

```hcl
# Development
vnet_address_space = ["10.0.0.0/16"]
vm_size           = "Standard_D2s_v3"
file_share_quota  = 100

# Staging
vnet_address_space = ["10.1.0.0/16"]
vm_size           = "Standard_D4s_v3"
file_share_quota  = 200

# Production
vnet_address_space = ["10.2.0.0/16"]
vm_size           = "Standard_D8s_v3"
file_share_quota  = 500
```

### Using Workspaces (Alternative Approach)

Instead of separate directories, you can use Terraform workspaces:

```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch between workspaces
terraform workspace select dev

# Use workspace name in configuration
locals {
  environment = terraform.workspace
  
  vm_size = {
    dev     = "Standard_D2s_v3"
    staging = "Standard_D4s_v3"
    prod    = "Standard_D8s_v3"
  }[terraform.workspace]
}
```

**Pros**:
- Single set of configuration files
- Easy to switch environments
- Less code duplication

**Cons**:
- More complex variable management
- Harder to customize per environment
- Shared state location

**Recommendation**: Use separate directories (current approach) for clarity and safety.

---

## State Management

### Local State (Development)

**Current setup** (dev environment):
```
terraform/environments/dev/
└── terraform.tfstate  # Local file
```

**Pros**:
- Simple setup
- No additional Azure resources needed
- Fast operations

**Cons**:
- No collaboration support
- No locking
- Easy to lose state

### Remote State (Staging/Production)

**Recommended for staging and production**:

**Step 1: Create Backend Resources**:
```bash
# Create resource group for state
az group create \
  --name terraform-state-rg \
  --location "Canada Central"

# Create storage account
az storage account create \
  --name tfstateaccount \
  --resource-group terraform-state-rg \
  --location "Canada Central" \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name tfstate \
  --account-name tfstateaccount
```

**Step 2: Configure Backend**:
```hcl
# terraform/environments/staging/main.tf

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "staging.terraform.tfstate"
  }
}
```

**Step 3: Initialize with Backend**:
```bash
terraform init -reconfigure
```

### State File Naming

```
tfstate/
├── dev.terraform.tfstate      # Development
├── staging.terraform.tfstate  # Staging
└── prod.terraform.tfstate     # Production
```

### State Backup Strategy

**Automated Backups**:
```bash
# Add to deployment script
backup_state() {
    local environment=$1
    local backup_dir="/backups/terraform-state"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    
    mkdir -p "$backup_dir"
    
    # Backup state file
    cp "terraform.tfstate" \
       "$backup_dir/${environment}.tfstate.${timestamp}"
    
    # Keep last 30 days
    find "$backup_dir" -name "*.tfstate.*" -mtime +30 -delete
}

# Usage
backup_state "staging"
```

---

## Environment Promotion

### Workflow

```
Dev → Staging → Production

1. Develop in dev
2. Test in dev
3. Promote to staging
4. Validate in staging
5. Promote to production
6. Monitor production
```

### Promoting Infrastructure Changes

**Step 1: Test in Dev**:
```bash
cd terraform/environments/dev
terraform plan
terraform apply
# Validate changes work correctly
```

**Step 2: Apply to Staging**:
```bash
cd terraform/environments/staging

# Update configuration files with same changes
# Review differences
terraform plan

# Apply changes
terraform apply

# Validate
./validate-deployment.sh
```

**Step 3: Apply to Production**:
```bash
cd terraform/environments/prod

# Update configuration files
# Review plan carefully
terraform plan -out=prod.tfplan

# Get approval from team

# Apply during maintenance window
terraform apply prod.tfplan

# Validate thoroughly
./validate-deployment.sh
```

### Configuration Drift Detection

**Check for Drift**:
```bash
# Run in each environment
terraform plan -detailed-exitcode

# Exit codes:
# 0 - No changes (no drift)
# 1 - Error
# 2 - Changes detected (drift found)
```

**Automated Drift Detection**:
```bash
#!/bin/bash
# check-drift.sh

ENVIRONMENTS=("dev" "staging" "prod")

for env in "${ENVIRONMENTS[@]}"; do
    echo "Checking drift in $env..."
    cd "terraform/environments/$env"
    
    terraform plan -detailed-exitcode -out="/dev/null"
    exit_code=$?
    
    if [[ $exit_code -eq 2 ]]; then
        echo "⚠️  Drift detected in $env"
        terraform show
    elif [[ $exit_code -eq 0 ]]; then
        echo "✓ No drift in $env"
    else
        echo "✗ Error checking $env"
    fi
done
```

---

## Best Practices

### 1. Environment Isolation

**Network Isolation**:
```hcl
# Different VNet ranges per environment
dev:     10.0.0.0/16
staging: 10.1.0.0/16
prod:    10.2.0.0/16
```

**Resource Naming**:
```
{project}-{component}-{environment}-{type}

dev:     dats-beeux-dev-rg
staging: dats-beeux-staging-rg
prod:    dats-beeux-prod-rg
```

### 2. Security Controls

**Access by Environment**:
```hcl
# Dev: Open access from laptop
allowed_ips = ["YOUR_LAPTOP_IP/32", "YOUR_WIFI_RANGE/24"]

# Staging: VPN only
allowed_ips = ["YOUR_VPN_IP/32"]

# Prod: VPN + jump server
allowed_ips = ["JUMP_SERVER_IP/32"]
```

**Credentials**:
- **Dev**: Can use less secure methods (local SSH keys)
- **Staging**: Use managed identities where possible
- **Prod**: Always use managed identities, never store credentials

### 3. Resource Sizing

**Right-size per Environment**:
```hcl
# variables.tf
variable "vm_size_map" {
  default = {
    dev     = "Standard_D2s_v3"   # 2 vCPU, 8GB RAM
    staging = "Standard_D4s_v3"   # 4 vCPU, 16GB RAM
    prod    = "Standard_D8s_v3"   # 8 vCPU, 32GB RAM
  }
}

vm_size = var.vm_size_map[var.environment]
```

### 4. Testing Strategy

**Test Thoroughly in Each Environment**:
```bash
# Dev: Unit tests, integration tests
cd dev
terraform apply
./run-tests.sh

# Staging: Full system tests, performance tests
cd staging
terraform apply
./run-system-tests.sh
./run-performance-tests.sh

# Prod: Smoke tests only
cd prod
terraform apply
./run-smoke-tests.sh
```

### 5. Change Management

**Always Follow Process**:
1. Document change in issue/ticket
2. Test in dev
3. Code review
4. Apply to staging
5. Validate staging
6. Schedule production change
7. Apply to production
8. Validate production
9. Monitor for issues

### 6. Rollback Plan

**Always Have Rollback Ready**:
```bash
# Before major changes
./scripts/deployment/backup-state.sh

# If issues occur
./scripts/deployment/rollback-deployment.sh
```

### 7. Documentation

**Document Environment Differences**:
```markdown
# Environment Comparison

| Resource | Dev | Staging | Prod |
|----------|-----|---------|------|
| VMs | 5 | 7 | 15 |
| VM Size | D2s_v3 | D4s_v3 | D8s_v3 |
| Storage | 100GB | 200GB | 500GB |
| Backups | Weekly | Daily | Hourly |
```

---

## Troubleshooting

### Issue: Terraform State Locked

**Problem**: Cannot run terraform commands

**Solution**:
```bash
# List locks
az storage blob list \
  --account-name tfstateaccount \
  --container-name tfstate

# Force unlock (use carefully)
terraform force-unlock <LOCK_ID>
```

### Issue: Resource Name Conflicts

**Problem**: Resource already exists in different environment

**Solution**:
```bash
# Import existing resource
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/existing-rg

# Or use different names
resource_group_name = "${var.project_name}-${var.environment}-rg"
```

### Issue: Different Module Versions

**Problem**: Environments using different module versions

**Solution**:
```hcl
# Pin module versions in main.tf
module "virtual_machine" {
  source = "../../modules/virtual-machine?ref=v1.0.0"
  # ...
}

# Or use git tags
module "virtual_machine" {
  source = "git::https://github.com/org/modules.git//virtual-machine?ref=v1.0.0"
  # ...
}
```

---

## Migration Strategies

### Migrating from Dev to Staging

**Option 1: Copy and Modify**:
```bash
# Copy entire dev environment
cp -r terraform/environments/dev terraform/environments/staging

# Update all references from 'dev' to 'staging'
cd terraform/environments/staging
find . -type f -exec sed -i 's/dev/staging/g' {} +
find . -type f -exec sed -i 's/10.0./10.1./g' {} +

# Initialize
terraform init
```

**Option 2: Start Fresh**:
```bash
# Create new environment from scratch
mkdir terraform/environments/staging
cd terraform/environments/staging

# Create main.tf using modules
# Configure variables
# Initialize
terraform init
```

### Importing Existing Resources

If you have existing Azure resources:

```bash
# Import resource group
terraform import azurerm_resource_group.main \
  /subscriptions/SUBSCRIPTION_ID/resourceGroups/existing-rg

# Import VM
terraform import azurerm_linux_virtual_machine.vm1 \
  /subscriptions/SUBSCRIPTION_ID/resourceGroups/RG_NAME/providers/Microsoft.Compute/virtualMachines/VM_NAME

# Verify import
terraform plan  # Should show no changes
```

---

## Related Documentation

- [Architecture](./architecture.md) - Infrastructure design
- [Deployment Guide](./deployment-guide.md) - Deployment process
- [Best Practices](./best-practices.md) - Standards and conventions
- [Troubleshooting](./troubleshooting.md) - Common issues

---

**Last Updated**: 2025-10-08  
**Version**: 1.0.0  
**Maintainer**: Infrastructure Team
