# Dev Environment - Development Infrastructure

Terraform configuration for deploying the BeEux Word Learning Platform development environment on Azure.

## 📋 Overview

This environment deploys:
- **1 Master Node** (VM1): Kubernetes control plane + WIOR, WCID
- **4 Worker Nodes** (VM2-5): Kubernetes workers with various components
- **Networking**: VNet, Subnet, NSG with 32 rules
- **Storage**: Azure Files share (100GB) for shared data
- **Total Cost**: ~$187/month

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Azure Resource Group: dats-beeux-dev-rg (centralus, zone 1)   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  VNet: 10.0.0.0/16                                              │
│  ├── Subnet: 10.0.1.0/24                                        │
│  └── NSG: 32 rules (laptop + WiFi access)                      │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ VM1 (Master)     - 10.0.1.4 - WIOR, WCID               │  │
│  │ VM2 (Worker)     - 10.0.1.5 - KIAM, SCSM, SCCM         │  │
│  │ VM3 (Worker)     - 10.0.1.6 - NGLB, WEUI, WAUI, etc.   │  │
│  │ VM4 (Worker)     - 10.0.1.7 - SCGC, SCSD, WAPI, PFIX   │  │
│  │ VM5 (Worker)     - 10.0.1.8 - WDAT, WEDA, SCBQ         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Storage: datsbeeuxdevstacct                                    │
│  └── File Share: dats-beeux-dev-shaf-afs (100GB)               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** installed and authenticated:
   ```bash
   az login
   az account set --subscription "<your-subscription-id>"
   ```

2. **Terraform** >= 1.5.0:
   ```bash
   terraform version
   ```

3. **Configure variables**:
   ```bash
   # Copy example files
   cp terraform.tfvars.example terraform.tfvars
   cp vm1-infr1-dev.tfvars.example vm1-infr1-dev.tfvars
   cp vm2-secu1-dev.tfvars.example vm2-secu1-dev.tfvars
   cp vm3-apps1-dev.tfvars.example vm3-apps1-dev.tfvars
   cp vm4-apps2-dev.tfvars.example vm4-apps2-dev.tfvars
   cp vm5-data1-dev.tfvars.example vm5-data1-dev.tfvars
   
   # Edit terraform.tfvars with your actual values
   # IMPORTANT: Update github_pat with your actual token
   vim terraform.tfvars
   ```

### Deployment

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment with all 6 tfvars files
terraform plan \
  -var-file=terraform.tfvars \
  -var-file=vm1-infr1-dev.tfvars \
  -var-file=vm2-secu1-dev.tfvars \
  -var-file=vm3-apps1-dev.tfvars \
  -var-file=vm4-apps2-dev.tfvars \
  -var-file=vm5-data1-dev.tfvars \
  -out=tfplan

# Review plan (should show ~30 resources)
# Expected: 1 RG, 1 VNet, 1 Subnet, 1 NSG, 32 NSG rules,
#           1 Storage Account, 1 File Share, 4 directories,
#           5 VMs, 5 NICs, 5 PIPs, 5 Disks, 5 SSH keys

# Apply the plan
terraform apply tfplan
```

### Expected Output

After successful deployment:
```
Apply complete! Resources: 30 added, 0 changed, 0 destroyed.

Outputs:

resource_group_name = "dats-beeux-dev-rg"
vm1_public_ip = "x.x.x.x"
vm1_ssh_connection = "ssh beeuser@x.x.x.x"
vm1_ssh_private_key_path = "./ssh-keys/dats-beeux-infr1-dev-id_rsa"
...
```

## 📦 Per-VM Configuration Files

Each VM has its own tfvars file for independent management:

| File | VM | Role | Components | IP |
|------|-----|------|------------|-----|
| `vm1-infr1-dev.tfvars` | dats-beeux-infr1-dev | Master | WIOR, WCID | 10.0.1.4 |
| `vm2-secu1-dev.tfvars` | dats-beeux-secu1-dev | Worker | KIAM, SCSM, SCCM | 10.0.1.5 |
| `vm3-apps1-dev.tfvars` | dats-beeux-apps1-dev | Worker | NGLB, WEUI, WAUI, WCAC, SWAG | 10.0.1.6 |
| `vm4-apps2-dev.tfvars` | dats-beeux-apps2-dev | Worker | SCGC, SCSD, WAPI, PFIX | 10.0.1.7 |
| `vm5-data1-dev.tfvars` | dats-beeux-data1-dev | Worker | WDAT, WEDA, SCBQ | 10.0.1.8 |

### Modifying a Single VM

To change VM5 disk size from 20GB to 30GB:

```bash
# Edit vm5-data1-dev.tfvars
vim vm5-data1-dev.tfvars
# Change: vm5_disk_size_gb = 30

# Plan changes (only VM5 will be affected)
terraform plan \
  -var-file=terraform.tfvars \
  -var-file=vm1-infr1-dev.tfvars \
  -var-file=vm2-secu1-dev.tfvars \
  -var-file=vm3-apps1-dev.tfvars \
  -var-file=vm4-apps2-dev.tfvars \
  -var-file=vm5-data1-dev.tfvars

# Apply (VM will be recreated with new disk)
terraform apply -auto-approve \
  -var-file=terraform.tfvars \
  -var-file=vm1-infr1-dev.tfvars \
  -var-file=vm2-secu1-dev.tfvars \
  -var-file=vm3-apps1-dev.tfvars \
  -var-file=vm4-apps2-dev.tfvars \
  -var-file=vm5-data1-dev.tfvars
```

## 🔑 SSH Access

### Connect to VMs

```bash
# Get SSH connection string
terraform output vm1_ssh_connection

# Connect using auto-generated key
ssh -i $(terraform output -raw vm1_ssh_private_key_path) beeuser@$(terraform output -raw vm1_public_ip)

# Or simply (key is in ssh-keys/ directory)
ssh -i ./ssh-keys/dats-beeux-infr1-dev-id_rsa beeuser@<vm1_public_ip>
```

### SSH Key Management

- **Auto-generated keys**: Stored in `./ssh-keys/`
- **All VMs**: Use the same SSH key (from VM1)
- **Security**: Add `ssh-keys/` to `.gitignore` (already done)

## 📊 View Outputs

```bash
# All outputs
terraform output

# Specific output
terraform output vm1_public_ip

# VM summary
terraform output all_vms

# SSH connections for all VMs
terraform output | grep ssh_connection
```

## 🧹 Cleanup

### Destroy Everything

```bash
terraform destroy \
  -var-file=terraform.tfvars \
  -var-file=vm1-infr1-dev.tfvars \
  -var-file=vm2-secu1-dev.tfvars \
  -var-file=vm3-apps1-dev.tfvars \
  -var-file=vm4-apps2-dev.tfvars \
  -var-file=vm5-data1-dev.tfvars
```

### Destroy Single VM

```bash
terraform destroy -target=module.vm5_data1 \
  -var-file=terraform.tfvars \
  -var-file=vm1-infr1-dev.tfvars \
  -var-file=vm2-secu1-dev.tfvars \
  -var-file=vm3-apps1-dev.tfvars \
  -var-file=vm4-apps2-dev.tfvars \
  -var-file=vm5-data1-dev.tfvars
```

## 🔧 Configuration Details

### Network Security

**Accessible Ports** (from laptop 136.56.79.92/32 AND WiFi 136.56.79.0/24):
- SSH: 22
- HTTP/HTTPS: 80, 443
- Keycloak: 8180, 8443
- Vault: 8200, 8201
- Config Server: 8888, 8889
- Gateway/Eureka: 8080, 8761
- Angular UIs: 4200, 4201
- APIs: 8081-8099
- Redis: 6379
- PostgreSQL: 5432
- RabbitMQ: 5672, 15672
- SMTP: 25, 587
- Kubernetes API: 6443
- NodePort: 30000-32767
- SMB: 445

**Inter-VM Traffic**: All ports open within VNet

### Kubernetes Configuration

- **Version**: 1.30
- **CNI**: Calico v3.27
- **Pod CIDR**: 192.168.0.0/16
- **Master Node**: VM1 (10.0.1.4)
- **Worker Nodes**: VM2-5 (10.0.1.5-8)

### Storage

- **Account**: datsbeeuxdevstacct (LRS)
- **File Share**: dats-beeux-dev-shaf-afs (100GB)
- **Mount Point**: /mnt/dats-beeux-dev-shaf-afs
- **Pre-created Dirs**: k8s-join-token, logs, backups, app-data

## 💰 Cost Estimate

| Resource | Quantity | Cost/Month |
|----------|----------|------------|
| Standard_B2s VMs | 5 | $185 |
| StandardSSD_LRS 20GB | 5 | $7.50 |
| Public IPs (Static) | 5 | $17.50 |
| Storage Account (LRS) | 1 | $2.40 |
| File Share 100GB | 1 | $2.05 |
| **Total** | - | **~$214/month** |

## 📁 File Structure

```
environments/dev/
├── backend.tf               # Terraform state backend
├── provider.tf              # Azure provider configuration
├── main.tf                  # Main orchestration (calls all modules)
├── variables.tf             # Variable declarations
├── outputs.tf               # Output definitions
├── terraform.tfvars.example # Common variables template
├── vm1-infr1-dev.tfvars.example  # VM1 specific vars
├── vm2-secu1-dev.tfvars.example  # VM2 specific vars
├── vm3-apps1-dev.tfvars.example  # VM3 specific vars
├── vm4-apps2-dev.tfvars.example  # VM4 specific vars
├── vm5-data1-dev.tfvars.example  # VM5 specific vars
└── README.md                # This file
```

## 🔒 Security Notes

⚠️ **IMPORTANT**:
1. **Never commit** `*.tfvars` files (they contain secrets like github_pat)
2. **Never commit** `ssh-keys/` directory (contains private keys)
3. Both are already in `.gitignore`, but double-check before git push
4. For production, use Azure Key Vault for secrets

## 🐛 Troubleshooting

### Issue: Terraform init fails
```bash
# Check Azure CLI authentication
az account show

# Re-authenticate if needed
az login
```

### Issue: Plan fails with "resource group not found"
The resource group is created by Terraform. Make sure you're running `terraform apply`, not trying to use an existing RG.

### Issue: SSH connection fails
```bash
# Check VM is running
az vm list -o table

# Check NSG rules
az network nsg show -g dats-beeux-dev-rg -n dats-beeux-dev-nsg

# Verify your IP is in laptop_ip or wifi_cidr range
curl ifconfig.me
```

### Issue: Storage mount fails on VMs
Cloud-init handles mounting. Check logs:
```bash
ssh beeuser@<vm_ip>
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log
```

## 📚 Related Documentation

- [Module Documentation](../../modules/README.md)
- [Cloud-Init Templates](../../cloud-init/README.md)
- [Deployment Scripts](../../scripts/deployment/README.md)
- [Architecture Guide](../../docs/architecture.md)

## 🤝 Support

For issues or questions:
1. Check [Troubleshooting Guide](../../docs/troubleshooting.md)
2. Review [Platform Register](../../Platform_Register.md)
3. Contact Platform Team
