# DATS-BEEUX-DEV Infrastructure Provisioning Plan

**Project**: BeEux Word Learning Platform - Development Environment  
**Date**: October 8, 2025  
**Version**: 1.0  
**Author**: Infrastructure Architect (AI Assistant)

---

## 📋 Executive Summary

This document outlines the complete infrastructure provisioning plan for the BeEux Word Learning Platform development environment using **Terraform** and **Kubernetes**. The infrastructure consists of 5 Azure VMs forming a Kubernetes cluster (1 master, 4 workers) hosting 22 platform components.

### Key Decisions
- ✅ **Infrastructure as Code**: Terraform (over Bicep)
- ✅ **Orchestration**: Kubernetes 1.30 with Calico CNI
- ✅ **Deployment Strategy**: Cloud-init for VM bootstrap + K8s manifests for components
- ✅ **Component Deployment**: Via infra repository (https://github.com/prashantmdesai/infra)
- ✅ **Authentication**: New SSH keys (generated), GitHub PAT for private repo, Access keys for file share
- ✅ **VM Configuration**: Independent variable files per VM (future-proofed for different specs)

---

## 🎯 Infrastructure Overview

### Resource Summary

| Resource Type | Count | Details |
|--------------|-------|---------|
| Resource Group | 1 | dats-beeux-dev-rg |
| Virtual Network | 1 | 10.0.0.0/16 |
| Subnet | 1 | 10.0.1.0/24 |
| Network Security Group | 1 | 20+ rules (all ports accessible from laptop/WiFi) |
| Virtual Machines | 5 | 1 master (infr1-dev), 4 workers (secu1, apps1, apps2, data1) |
| Public IPs | 5 | One per VM |
| Network Interfaces | 5 | One per VM |
| Managed Disks | 5 | 20GB StandardSSD_LRS each |
| Storage Account | 1 | datsbeeuxdevstacct |
| File Share | 1 | 100GB quota |

**Total Resources**: ~30 Azure resources  
**Estimated Cost**: ~$173/month (~$2,076/year)

---

## 🏗️ VM Architecture

### VM Configuration Table

| VM | Name | Role | Private IP | Components | Specs (Current) | Config File |
|----|------|------|------------|------------|-----------------|-------------|
| VM1 | dats-beeux-infr1-dev | K8s Master | 10.0.1.4 | WIOR, WCID | Standard_B2s, 20GB SSD | `vm1-infr1-dev.tfvars` |
| VM2 | dats-beeux-secu1-dev | K8s Worker | 10.0.1.5 | KIAM, SCSM, SCCM | Standard_B2s, 20GB SSD | `vm2-secu1-dev.tfvars` |
| VM3 | dats-beeux-apps1-dev | K8s Worker | 10.0.1.6 | NGLB, WEUI, WAUI, WCAC, SWAG | Standard_B2s, 20GB SSD | `vm3-apps1-dev.tfvars` |
| VM4 | dats-beeux-apps2-dev | K8s Worker | 10.0.1.7 | SCGC, SCSD, WAPI, PFIX | Standard_B2s, 20GB SSD | `vm4-apps2-dev.tfvars` |
| VM5 | dats-beeux-data1-dev | K8s Worker | 10.0.1.8 | WDAT, WEDA, SCBQ | Standard_B2s, 20GB SSD | `vm5-data1-dev.tfvars` |

**Design Rationale**: Each VM has its own `.tfvars` file to allow independent configuration changes (CPU, RAM, disk size, etc.) in the future without affecting other VMs.

---

## 🔐 Security & Network Configuration

### Network Security Group Rules

All component ports are accessible from **BOTH** laptop (136.56.79.92/32) **AND** WiFi network (136.56.79.0/24):

| Priority | Port(s) | Component | Service | Purpose |
|----------|---------|-----------|---------|---------|
| 100-101 | 22 | SSH | System | Remote administration |
| 200 | 80, 443 | NGLB | NGINX | HTTP/HTTPS load balancer |
| 300 | 6443 | WIOR | Kubernetes | K8s API Server |
| 301 | 30000-32767 | WIOR | Kubernetes | NodePort service range |
| 400 | 8180, 8443 | KIAM | Keycloak | Identity management UI |
| 401 | 8200, 8201 | SCSM | Vault | Secrets management API |
| 402 | 8888, 8889 | SCCM | Config Server | Configuration management |
| 500 | 8080, 8761 | SCGC/SCSD | Gateway/Eureka | API Gateway, Service Discovery |
| 600 | 4200 | WEUI | Angular | End User Interface |
| 600 | 4201 | WAUI | Angular | Admin User Interface |
| 601 | 8081 | SWAG | Swagger | API Documentation UI |
| 700 | 8082-8099 | WAPI | Spring Boot | Backend REST APIs |
| 701 | 6379 | WCAC | Redis | Cache server |
| 702 | 8083 | SCBQ | Batch/Quartz | Job scheduler |
| 800 | 5432 | WDAT | PostgreSQL | Database server |
| 801 | 5672, 15672 | WEDA | RabbitMQ | Message queue + Management UI |
| 900 | 25, 587 | PFIX | Postfix | SMTP email |
| 1000 | 8080 | WCID | GitHub Actions | CI/CD webhook |
| 1001 | 445 | SHAF | Azure Files | File share access |
| 2000 | ALL | Inter-VM | Internal | VM-to-VM communication (10.0.1.0/24) |
| 4096 | ALL | Deny | Default | Deny all other inbound traffic |

### Accessible Services from Browser

Once deployed, these UIs will be accessible from any device on your laptop or WiFi:

- **Keycloak IAM**: `http://<vm-ip>:8180` or `https://<vm-ip>:8443`
- **Vault Secrets**: `http://<vm-ip>:8200`
- **End User Interface**: `http://<vm-ip>:4200`
- **Admin Interface**: `http://<vm-ip>:4201`
- **Swagger API Docs**: `http://<vm-ip>:8081`
- **RabbitMQ Management**: `http://<vm-ip>:15672`
- **Eureka Dashboard**: `http://<vm-ip>:8761`
- **Spring Cloud Gateway**: `http://<vm-ip>:8080`
- **Config Server**: `http://<vm-ip>:8888`

---

## 📂 Directory Structure

```
beeinfra/
├── .git/                                      # Git version control (preserved)
├── .github/                                   # GitHub configuration (preserved)
│   └── instructions/
│       ├── Platform_Register.md               # Component definitions (22 FLAs)
│       └── prompts.instructions.md            # AI coding guidelines
│
├── .gitignore                                 # Terraform/sensitive files exclusions
├── README.md                                  # Project overview and quick start
├── DATS-BEEUX-DEV-INFRA-PROVISIONING-PLAN.md # This document
├── script-execution.registry                  # Script execution tracking log
│
├── logs/                                      # Timestamped execution logs
│   ├── .gitkeep
│   └── *.log                                  # Individual script execution logs
│
├── terraform/
│   ├── modules/
│   │   ├── resource-group/
│   │   │   ├── main.tf                        # Resource group creation
│   │   │   ├── variables.tf                   # Input: org, platform, env, location
│   │   │   ├── outputs.tf                     # Export: rg_name, rg_id, rg_location
│   │   │   └── README.md                      # Module documentation
│   │   │
│   │   ├── networking/
│   │   │   ├── main.tf                        # VNet, Subnet, NSG
│   │   │   ├── nsg-rules.tf                   # All 20+ NSG rules (laptop + WiFi)
│   │   │   ├── variables.tf                   # Network configuration inputs
│   │   │   ├── outputs.tf                     # Export: vnet_id, subnet_id, nsg_id
│   │   │   └── README.md                      # Network module documentation
│   │   │
│   │   ├── storage/
│   │   │   ├── main.tf                        # Storage account + file share
│   │   │   ├── variables.tf                   # Storage configuration inputs
│   │   │   ├── outputs.tf                     # Export: account_name, share_name, key
│   │   │   └── README.md                      # Storage module documentation
│   │   │
│   │   └── virtual-machine/
│   │       ├── main.tf                        # VM, NIC, PIP, Disk
│   │       ├── ssh-keys.tf                    # SSH key generation
│   │       ├── variables.tf                   # VM configuration inputs
│   │       ├── outputs.tf                     # Export: vm_id, private_ip, public_ip
│   │       └── README.md                      # VM module documentation
│   │
│   ├── environments/
│   │   └── dev/
│   │       ├── backend.tf                     # Azure Storage backend for state
│   │       ├── main.tf                        # Orchestrate all modules
│   │       ├── variables.tf                   # Variable definitions
│   │       ├── outputs.tf                     # Aggregate outputs
│   │       ├── README.md                      # Deployment instructions
│   │       │
│   │       ├── terraform.tfvars               # Common dev environment values
│   │       ├── vm1-infr1-dev.tfvars          # VM1 specific configuration
│   │       ├── vm2-secu1-dev.tfvars          # VM2 specific configuration
│   │       ├── vm3-apps1-dev.tfvars          # VM3 specific configuration
│   │       ├── vm4-apps2-dev.tfvars          # VM4 specific configuration
│   │       └── vm5-data1-dev.tfvars          # VM5 specific configuration
│   │
│   ├── cloud-init/
│   │   ├── master-node.yaml                   # VM1 initialization (K8s master)
│   │   ├── worker-node.yaml                   # VM2-5 initialization (K8s workers)
│   │   ├── common-setup.yaml                  # Shared setup across all VMs
│   │   └── README.md                          # Cloud-init documentation
│   │
│   ├── scripts/
│   │   ├── common/
│   │   │   ├── env-config.sh                  # Environment variables (ORGNM/PLTNM/ENVNM)
│   │   │   ├── logging-standard.sh            # Logging standard (imported from root)
│   │   │   ├── script-tracker.sh              # Execution tracking
│   │   │   ├── validation-helpers.sh          # Reusable validation functions
│   │   │   └── error-handlers.sh              # Standardized error handling
│   │   │
│   │   ├── kubernetes/
│   │   │   ├── install-k8s-1.30.sh           # Install K8s 1.30 components
│   │   │   ├── init-master.sh                 # Initialize master (kubeadm init)
│   │   │   ├── join-worker.sh                 # Join worker to cluster
│   │   │   ├── install-calico.sh              # Install Calico CNI v3.27
│   │   │   ├── verify-cluster.sh              # Health checks
│   │   │   └── README.md                      # K8s setup documentation
│   │   │
│   │   ├── infrastructure/
│   │   │   ├── mount-azure-fileshare.sh       # Mount file share (idempotent)
│   │   │   ├── verify-mount.sh                # Verify file share accessibility
│   │   │   ├── clone-infra-repo.sh            # Clone infra repo to /home/beeuser/plt
│   │   │   ├── setup-github-auth.sh           # Configure GitHub PAT
│   │   │   └── README.md                      # Infrastructure setup docs
│   │   │
│   │   └── deployment/
│   │       ├── deploy-all.sh                  # Master deployment orchestrator
│   │       ├── validate-deployment.sh         # End-to-end validation
│   │       ├── rollback-deployment.sh         # Rollback on failure
│   │       └── README.md                      # Deployment procedures
│   │
│   └── docs/
│       ├── architecture.md                    # Infrastructure diagram
│       ├── deployment-guide.md                # Step-by-step deployment
│       ├── troubleshooting.md                 # Common issues and solutions
│       ├── port-mapping.md                    # Component port reference
│       ├── environment-setup.md               # Multi-environment guide
│       └── best-practices.md                  # Standards and conventions
```

---

## 🔧 Per-VM Configuration Strategy

### Design Philosophy

To support **future independent configuration changes** per VM (different CPU, RAM, disk sizes, etc.), each VM has its own `.tfvars` file:

```hcl
# terraform/environments/dev/vm1-infr1-dev.tfvars
vm_name          = "dats-beeux-infr1-dev"
vm_role          = "master"
vm_size          = "Standard_B2s"        # Can change to Standard_D4s_v3 later
vm_private_ip    = "10.0.1.4"
vm_disk_size_gb  = 20                    # Can change to 100GB later
vm_disk_sku      = "StandardSSD_LRS"     # Can change to Premium_LRS later
vm_zone          = "1"
vm_components    = ["WIOR", "WCID"]
vm_description   = "Kubernetes Master Node - Infrastructure Orchestration and CI/CD"
```

### Per-VM Variable Files

**VM1 - infr1-dev** (`vm1-infr1-dev.tfvars`):
```hcl
vm_name          = "dats-beeux-infr1-dev"
vm_role          = "master"
vm_size          = "Standard_B2s"
vm_private_ip    = "10.0.1.4"
vm_disk_size_gb  = 20
vm_disk_sku      = "StandardSSD_LRS"
vm_zone          = "1"
vm_components    = ["WIOR", "WCID"]
```

**VM2 - secu1-dev** (`vm2-secu1-dev.tfvars`):
```hcl
vm_name          = "dats-beeux-secu1-dev"
vm_role          = "worker"
vm_size          = "Standard_B2s"
vm_private_ip    = "10.0.1.5"
vm_disk_size_gb  = 20
vm_disk_sku      = "StandardSSD_LRS"
vm_zone          = "1"
vm_components    = ["KIAM", "SCSM", "SCCM"]
```

**VM3 - apps1-dev** (`vm3-apps1-dev.tfvars`):
```hcl
vm_name          = "dats-beeux-apps1-dev"
vm_role          = "worker"
vm_size          = "Standard_B2s"
vm_private_ip    = "10.0.1.6"
vm_disk_size_gb  = 20
vm_disk_sku      = "StandardSSD_LRS"
vm_zone          = "1"
vm_components    = ["NGLB", "WEUI", "WAUI", "WCAC", "SWAG"]
```

**VM4 - apps2-dev** (`vm4-apps2-dev.tfvars`):
```hcl
vm_name          = "dats-beeux-apps2-dev"
vm_role          = "worker"
vm_size          = "Standard_B2s"
vm_private_ip    = "10.0.1.7"
vm_disk_size_gb  = 20
vm_disk_sku      = "StandardSSD_LRS"
vm_zone          = "1"
vm_components    = ["SCGC", "SCSD", "WAPI", "PFIX"]
```

**VM5 - data1-dev** (`vm5-data1-dev.tfvars`):
```hcl
vm_name          = "dats-beeux-data1-dev"
vm_role          = "worker"
vm_size          = "Standard_B2s"
vm_private_ip    = "10.0.1.8"
vm_disk_size_gb  = 20
vm_disk_sku      = "StandardSSD_LRS"
vm_zone          = "1"
vm_components    = ["WDAT", "WEDA", "SCBQ"]
```

### Main Terraform Configuration Pattern

```hcl
# terraform/environments/dev/main.tf

# VM1 - Infrastructure Master
module "vm_infr1_dev" {
  source = "../../modules/virtual-machine"
  
  # Load VM-specific variables from vm1-infr1-dev.tfvars
  vm_name         = var.vm1_name
  vm_role         = var.vm1_role
  vm_size         = var.vm1_size
  vm_private_ip   = var.vm1_private_ip
  vm_disk_size_gb = var.vm1_disk_size_gb
  vm_disk_sku     = var.vm1_disk_sku
  # ... other VM1-specific variables
  
  # Common/shared variables
  resource_group_name = module.resource_group.rg_name
  location            = var.location
  subnet_id           = module.networking.subnet_id
  nsg_id              = module.networking.nsg_id
  cloud_init_data     = file("${path.module}/../../cloud-init/master-node.yaml")
}

# VM2 - Security Worker
module "vm_secu1_dev" {
  source = "../../modules/virtual-machine"
  
  # Load VM-specific variables from vm2-secu1-dev.tfvars
  vm_name         = var.vm2_name
  vm_role         = var.vm2_role
  vm_size         = var.vm2_size
  # ... other VM2-specific variables
  
  # Common/shared variables
  # ... (same pattern as VM1)
}

# VM3, VM4, VM5 follow same pattern...
```

### Future Configuration Change Example

**Scenario**: VM5 (data1-dev) needs more resources for PostgreSQL and RabbitMQ

**Before** (`vm5-data1-dev.tfvars`):
```hcl
vm_size          = "Standard_B2s"        # 2 vCPU, 4GB RAM
vm_disk_size_gb  = 20                    # 20GB disk
vm_disk_sku      = "StandardSSD_LRS"
```

**After** (`vm5-data1-dev.tfvars`):
```hcl
vm_size          = "Standard_D4s_v3"     # 4 vCPU, 16GB RAM
vm_disk_size_gb  = 100                   # 100GB disk
vm_disk_sku      = "Premium_LRS"         # Faster I/O
```

**Result**: Only VM5 changes, VM1-VM4 remain unaffected.

---

## 📝 Standards & Best Practices Applied

### Logging Standards
- **Source**: `scripts/logging-standard-bash.sh`
- **Central Registry**: `script-execution.registry` (tracks all script executions)
- **Individual Logs**: `logs/{script-name}-{timestamp}.log`
- **Metadata**: User, working directory, exit code, duration, ORGNM/PLTNM/ENVNM
- **Format**: Pipe-delimited log entries for easy parsing

### Idempotency Patterns
- **Source**: `scripts/mount-azure-file-shares.sh`
- **Check-Before-Action**: Verify existing state before making changes
- **Skip-If-Complete**: Don't repeat successful operations
- **Validation**: Post-operation verification

### Error Handling
- **Source**: `scripts/rename-vms.sh`
- **Strict Mode**: `set -euo pipefail` in all bash scripts
- **Validation Functions**: Pre-flight checks for prerequisites
- **Exit Traps**: Automatic cleanup and tracking on script exit
- **Rollback Capability**: Undo operations on failure

### Naming Conventions
- **Resources**: `{org}-{platform}-{component}-{env}` (e.g., `dats-beeux-infr1-dev`)
- **Scripts**: `{component}-{subcomponent}-{purpose}-{function}-{detail}.sh`
- **Environment Variables**: ORGNM, PLTNM, ENVNM for multi-environment support

### Multi-Environment Design
- **Environments**: dev, sit, uat, prd
- **Separation**: Each environment has own `terraform/environments/{env}/` directory
- **Reusability**: Same modules, different variable values
- **State Isolation**: Separate Terraform state per environment

---

## 🚀 Deployment Workflow

### Phase 0: Repository Cleanup
```bash
# Remove all existing files EXCEPT .git/ and .github/
cd /mnt/c/dev/beeinfra
rm -rf scripts/ dats/ logs/ *.md script-execution.registry
# Verify only .git/ and .github/ remain
ls -la
```

### Phase 1-5: Infrastructure Creation
1. **Foundation**: Create base structure, .gitignore, README, common scripts
2. **Modules**: Create resource-group, networking, storage, virtual-machine modules
3. **Environment**: Create dev environment configuration with per-VM .tfvars files
4. **Cloud-Init**: Create master and worker node templates
5. **Scripts**: Create K8s, infrastructure, and deployment scripts

### Phase 6: Deployment Execution
```bash
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Generate execution plan
terraform plan \
  -var-file="terraform.tfvars" \
  -var-file="vm1-infr1-dev.tfvars" \
  -var-file="vm2-secu1-dev.tfvars" \
  -var-file="vm3-apps1-dev.tfvars" \
  -var-file="vm4-apps2-dev.tfvars" \
  -var-file="vm5-data1-dev.tfvars" \
  -out=tfplan

# Review plan (expect ~30 resources)

# Apply infrastructure
terraform apply tfplan
```

### Phase 7: Validation
```bash
# Run validation script
../../../scripts/deployment/validate-deployment.sh

# Expected validations:
# ✅ All 5 VMs running
# ✅ K8s cluster initialized (kubectl get nodes shows 5 nodes)
# ✅ Infra repo cloned to /home/beeuser/plt on VM1
# ✅ File share mounted on all VMs
# ✅ SSH access working from laptop and WiFi
# ✅ All component ports accessible from laptop and WiFi
```

---

## 🎯 Component Deployment Strategy

### Kubernetes-Native Deployment

Components are deployed via Kubernetes manifests/Helm charts from the infra repository:

```bash
# On VM1 (master node)
ssh beeuser@<vm1-public-ip>

# Navigate to cloned infra repo
cd /home/beeuser/plt

# Deploy components using kubectl
kubectl apply -k manifests/dev/

# Or using Helm
helm install word-platform ./charts/word-platform --namespace=word-dev --create-namespace
```

### Component Deployment Order (Recommended)

1. **Infrastructure** (VM1):
   - WIOR: Kubernetes cluster (already deployed)
   - WCID: GitHub Actions Runner

2. **Security** (VM2):
   - SCCM: Spring Cloud Config Server (first - needed by others)
   - SCSM: HashiCorp Vault
   - KIAM: Keycloak

3. **Data Layer** (VM5):
   - WDAT: PostgreSQL
   - WEDA: RabbitMQ
   - SCBQ: Spring Batch + Quartz

4. **Gateway & Discovery** (VM4):
   - SCSD: Eureka Service Discovery
   - SCGC: Spring Cloud Gateway

5. **Backend APIs** (VM4):
   - WAPI: Word APIs (Spring Boot services)

6. **Frontend & Proxy** (VM3):
   - NGLB: NGINX Load Balancer
   - WEUI: End User Interface
   - WAUI: Admin User Interface
   - WCAC: Redis Cache
   - SWAG: Swagger Documentation

7. **Email** (VM4):
   - PFIX: Postfix SMTP

---

## 📊 Cost Breakdown

### Monthly Cost Estimate

| Resource | Quantity | Unit Cost | Monthly Cost |
|----------|----------|-----------|--------------|
| Standard_B2s VMs | 5 | ~$30/month | ~$150 |
| 20GB StandardSSD_LRS | 5 | ~$1.60/month | ~$8 |
| Public IPs (Static) | 5 | ~$3.65/month | ~$18.25 |
| Storage Account (LRS) | 1 | ~$0.50/month | ~$0.50 |
| File Share (100GB) | 1 | ~$5/month | ~$5 |
| Bandwidth (estimate) | - | Variable | ~$5 |
| **TOTAL** | - | - | **~$186.75/month** |

**Annual Cost**: ~$2,241/year

### Cost Optimization Opportunities

1. **Reserved Instances**: Save 30-50% with 1-year or 3-year commitments
2. **Dev/Test Subscription**: Save ~20% on VM costs
3. **Auto-shutdown**: Schedule VMs to stop during non-working hours (save ~60% if 8hrs/day)
4. **Spot Instances**: Save 60-90% for non-critical workloads (not recommended for K8s master)

---

## ⚠️ Risk Assessment & Mitigation

### Risks Identified

1. **Single Point of Failure**: Only 1 K8s master node
   - **Mitigation**: Acceptable for dev environment; implement 3-master HA for production

2. **Data Loss**: No backup strategy defined
   - **Mitigation**: Implement Azure Backup for VMs and PostgreSQL automated backups

3. **Security**: All ports exposed to laptop/WiFi
   - **Mitigation**: Acceptable for dev; implement VPN/Bastion for production

4. **Cost Overrun**: Resources running 24/7
   - **Mitigation**: Implement auto-shutdown schedule

5. **State File Loss**: Terraform state in Azure Storage
   - **Mitigation**: Enable versioning and soft delete on storage account

---

## 📋 Pre-Deployment Checklist

- [ ] Azure CLI installed and logged in (`az login`)
- [ ] Terraform >= 1.5.0 installed (`terraform version`)
- [ ] GitHub PAT validated and has repo access
- [ ] Laptop IP confirmed: 136.56.79.92
- [ ] WiFi CIDR confirmed: 136.56.79.0/24
- [ ] Storage account name available: datsbeeuxdevstacct
- [ ] Subscription permissions: Owner or Contributor + User Access Administrator
- [ ] Resource providers registered: Microsoft.Compute, Microsoft.Network, Microsoft.Storage
- [ ] Repository cleaned (only .git/ and .github/ remain)

---

## 📚 Documentation Deliverables

1. **architecture.md**: Infrastructure diagram showing all components
2. **deployment-guide.md**: Step-by-step deployment with screenshots
3. **troubleshooting.md**: Common issues and solutions per component
4. **port-mapping.md**: Complete port reference with access instructions
5. **environment-setup.md**: Guide for creating sit/uat/prd environments
6. **best-practices.md**: Standards and conventions used

---

## 🔄 Post-Deployment Tasks

1. **Configure DNS**: Update private DNS or /etc/hosts for hostname resolution
2. **SSL Certificates**: Install Let's Encrypt certificates for HTTPS
3. **Monitoring**: Set up Azure Monitor and Application Insights
4. **Backup**: Configure Azure Backup for VMs
5. **Alerts**: Create alert rules for critical metrics (CPU, memory, disk)
6. **Documentation**: Update with actual IP addresses and access URLs
7. **Runbook**: Create operational runbook for common tasks

---

## 📞 Support & Troubleshooting

### Log Locations
- **Terraform Logs**: `terraform/environments/dev/terraform.log`
- **Script Logs**: `logs/{script-name}-{timestamp}.log`
- **Execution Registry**: `script-execution.registry`
- **Cloud-Init Logs**: `/var/log/cloud-init-output.log` on VMs

### Common Issues

**Issue**: Terraform state locked  
**Solution**: `terraform force-unlock <lock-id>`

**Issue**: VM deployment failed  
**Solution**: Check `logs/` for script errors, review cloud-init logs on VM

**Issue**: K8s cluster not initializing  
**Solution**: SSH to master, check `/var/log/cloud-init-output.log`, verify file share mount

**Issue**: Cannot access component UI  
**Solution**: Verify NSG rules, check VM public IP, verify component pod running

---

## 🎓 Learning Resources

- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Calico CNI**: https://docs.tigera.io/calico/latest/about
- **Azure Best Practices**: https://learn.microsoft.com/en-us/azure/architecture/
- **Cloud-Init**: https://cloudinit.readthedocs.io/

---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-08 | Infrastructure Architect (AI) | Initial comprehensive plan |

---

## ✅ Sign-Off

**Infrastructure Architect**: AI Assistant  
**Reviewed By**: [Pending User Approval]  
**Approved By**: [Pending User Approval]  
**Date**: October 8, 2025

---

**End of Document**
