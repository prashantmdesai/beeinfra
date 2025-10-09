# Virtual Machine Module

Creates Azure Linux Virtual Machines with Public IP, NIC, and Managed Disk. Supports both Kubernetes master and worker node roles with automatic SSH key generation.

## Features

- **Linux VM**: Ubuntu 22.04 LTS (configurable)
- **Public IP**: Static IP with Standard SKU for zone support
- **Network Interface**: Static private IP with NSG association
- **SSH Key Management**: Auto-generate or use existing SSH keys
- **Cloud-Init**: Bootstrap VMs with custom cloud-init configuration
- **Availability Zones**: Zone-redundant deployment support
- **Role-Based**: Distinct configuration for master and worker nodes
- **Per-VM Configuration**: Independent tfvars files for maximum flexibility

## Usage

### Basic Usage (Auto-generate SSH keys)

```hcl
module "vm_master" {
  source = "../../modules/virtual-machine"

  org_name            = "dats"
  platform_name       = "beeux"
  env_name            = "dev"
  location            = "centralus"
  resource_group_name = module.resource_group.rg_name

  vm_name        = "dats-beeux-infr1-dev"
  vm_size        = "Standard_B2s"
  vm_disk_size_gb = 20
  vm_disk_sku    = "StandardSSD_LRS"
  vm_private_ip  = "10.0.1.4"
  vm_zone        = "1"
  vm_role        = "master"
  vm_components  = "WIOR,WCID"

  subnet_id = module.networking.subnet_id
  nsg_id    = module.networking.nsg_id

  admin_username = "beeuser"
  ssh_public_key = null  # Auto-generate
  save_ssh_key_locally = true

  cloud_init_data = file("${path.module}/cloud-init/master-node.yaml")

  tags = {
    CostCenter = "Engineering"
  }
}
```

### Using Existing SSH Key

```hcl
module "vm_worker" {
  source = "../../modules/virtual-machine"

  # ... (same as above)

  ssh_public_key = file("~/.ssh/id_rsa.pub")  # Use existing key
  save_ssh_key_locally = false
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| org_name | Organization name | string | - | yes |
| platform_name | Platform name | string | - | yes |
| env_name | Environment (dev/sit/uat/prd) | string | - | yes |
| location | Azure region | string | "centralus" | no |
| resource_group_name | Resource group name | string | - | yes |
| vm_name | VM name (1-64 chars, lowercase, alphanumeric, hyphens) | string | - | yes |
| vm_size | Azure VM size | string | "Standard_B2s" | no |
| vm_disk_size_gb | OS disk size (20-4096 GB) | number | 20 | no |
| vm_disk_sku | Disk SKU | string | "StandardSSD_LRS" | no |
| vm_private_ip | Static private IP | string | - | yes |
| vm_zone | Availability zone (1/2/3/null) | string | "1" | no |
| vm_role | Kubernetes role (master/worker) | string | - | yes |
| vm_components | Component names (comma-separated) | string | "" | no |
| subnet_id | Subnet ID | string | - | yes |
| nsg_id | NSG ID | string | - | yes |
| admin_username | Admin username | string | "beeuser" | no |
| ssh_public_key | SSH public key (null to auto-generate) | string | null | no |
| save_ssh_key_locally | Save generated keys to ssh-keys/ | bool | true | no |
| cloud_init_data | Cloud-init YAML configuration | string | null | no |
| vm_image_publisher | Image publisher | string | "Canonical" | no |
| vm_image_offer | Image offer | string | "0001-com-ubuntu-server-jammy" | no |
| vm_image_sku | Image SKU | string | "22_04-lts-gen2" | no |
| vm_image_version | Image version | string | "latest" | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vm_id | VM ID |
| vm_name | VM name |
| private_ip | Private IP address |
| public_ip | Public IP address |
| public_ip_fqdn | Public IP FQDN (if configured) |
| nic_id | Network interface ID |
| ssh_connection_string | SSH connection command |
| ssh_private_key_path | Path to generated private key (if generated) |
| ssh_public_key_path | Path to generated public key (if generated) |
| ssh_public_key | SSH public key used |
| vm_role | VM role (master/worker) |
| vm_components | Components on this VM |
| vm_zone | Availability zone |

## SSH Key Management

### Auto-Generated Keys
When `ssh_public_key = null`, Terraform generates a new 4096-bit RSA key pair:
- **Private key**: `ssh-keys/{vm_name}-id_rsa` (mode 0600)
- **Public key**: `ssh-keys/{vm_name}-id_rsa.pub` (mode 0644)

⚠️ **IMPORTANT**: Add `ssh-keys/` to `.gitignore` to prevent committing private keys!

### Using Existing Keys
```hcl
ssh_public_key = file("~/.ssh/id_rsa.pub")
save_ssh_key_locally = false
```

### Connect to VM
```bash
# With auto-generated key
terraform output -raw vm1_ssh_connection_string
# Output: ssh beeuser@<public_ip>

# Use specific private key
terraform output -raw vm1_ssh_private_key_path
# Output: /path/to/ssh-keys/dats-beeux-infr1-dev-id_rsa

ssh -i $(terraform output -raw vm1_ssh_private_key_path) beeuser@<public_ip>
```

## VM Roles

### Master Node
- Role: `vm_role = "master"`
- Purpose: Kubernetes control plane
- Components: WIOR, WCID
- IP: 10.0.1.4 (first in subnet)
- Cloud-init: `master-node.yaml`

### Worker Node
- Role: `vm_role = "worker"`
- Purpose: Kubernetes workload nodes
- Components: Various (KIAM, SCSM, NGLB, etc.)
- IPs: 10.0.1.5-10.0.1.8
- Cloud-init: `worker-node.yaml`

## Disk SKU Options

| SKU | Type | IOPS | Throughput | Use Case |
|-----|------|------|------------|----------|
| Standard_LRS | HDD | 500 | 60 MB/s | Cost-optimized, low I/O |
| StandardSSD_LRS | SSD | 500-6000 | 60-750 MB/s | **Recommended** for dev/test |
| Premium_LRS | SSD | 120-20000 | 25-900 MB/s | Production, high I/O |
| StandardSSD_ZRS | SSD | 500-6000 | 60-750 MB/s | Zone-redundant |
| Premium_ZRS | SSD | 120-20000 | 25-900 MB/s | Zone-redundant, high I/O |

## VM Size Options

| Size | vCPU | RAM | Disk | Cost/Month | Use Case |
|------|------|-----|------|------------|----------|
| Standard_B1s | 1 | 1 GB | 30 GB | ~$8 | Minimal, non-production |
| **Standard_B2s** | 2 | 4 GB | 8 GB | ~$37 | **Recommended** for dev |
| Standard_B2ms | 2 | 8 GB | 16 GB | ~$73 | Medium workloads |
| Standard_D2s_v5 | 2 | 8 GB | - | ~$96 | Production |

## Cloud-Init Integration

The module supports cloud-init for VM bootstrapping:

```yaml
#cloud-config
package_update: true
package_upgrade: true

packages:
  - docker.io
  - kubernetes

runcmd:
  - kubeadm init --pod-network-cidr=192.168.0.0/16
```

Pass to module:
```hcl
cloud_init_data = file("${path.module}/cloud-init/master-node.yaml")
```

## Availability Zones

- **Zone 1**: `vm_zone = "1"`
- **Zone 2**: `vm_zone = "2"`
- **Zone 3**: `vm_zone = "3"`
- **No Zone**: `vm_zone = null`

⚠️ Not all regions support all zones. Check Azure documentation.

## Security Features

### SSH Only
- Password authentication **disabled**
- SSH key-based authentication only
- 4096-bit RSA keys (when auto-generated)

### Network Security
- NSG attached to NIC
- Private IP for VNet communication
- Public IP for external access (can be removed for production)

### Boot Diagnostics
- Enabled with managed storage
- Useful for troubleshooting boot issues

## Per-VM Configuration Pattern

Each VM has its own tfvars file for independent management:

**vm1-infr1-dev.tfvars**:
```hcl
vm1_name        = "dats-beeux-infr1-dev"
vm1_size        = "Standard_B2s"
vm1_disk_size_gb = 20
vm1_disk_sku    = "StandardSSD_LRS"
vm1_private_ip  = "10.0.1.4"
vm1_zone        = "1"
vm1_role        = "master"
vm1_components  = "WIOR,WCID"
```

Deploy with all configs:
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=vm1-infr1-dev.tfvars \
  -var-file=vm2-secu1-dev.tfvars \
  # ... etc
```

## Examples

### Master Node (VM1)
```hcl
module "vm1_master" {
  source = "../../modules/virtual-machine"
  
  org_name            = "dats"
  platform_name       = "beeux"
  env_name            = "dev"
  location            = "centralus"
  resource_group_name = module.resource_group.rg_name
  
  vm_name         = "dats-beeux-infr1-dev"
  vm_size         = "Standard_B2s"
  vm_disk_size_gb = 20
  vm_disk_sku     = "StandardSSD_LRS"
  vm_private_ip   = "10.0.1.4"
  vm_zone         = "1"
  vm_role         = "master"
  vm_components   = "WIOR,WCID"
  
  subnet_id = module.networking.subnet_id
  nsg_id    = module.networking.nsg_id
  
  admin_username      = "beeuser"
  save_ssh_key_locally = true
  cloud_init_data     = templatefile("${path.module}/../../cloud-init/master-node.yaml", {
    k8s_version = "1.30"
    pod_cidr    = "192.168.0.0/16"
  })
}
```

### Worker Node (VM2)
```hcl
module "vm2_worker" {
  source = "../../modules/virtual-machine"
  
  # ... (same org/platform/env)
  
  vm_name         = "dats-beeux-secu1-dev"
  vm_size         = "Standard_B2s"
  vm_disk_size_gb = 20
  vm_disk_sku     = "StandardSSD_LRS"
  vm_private_ip   = "10.0.1.5"
  vm_zone         = "1"
  vm_role         = "worker"
  vm_components   = "KIAM,SCSM,SCCM"
  
  subnet_id = module.networking.subnet_id
  nsg_id    = module.networking.nsg_id
  
  admin_username      = "beeuser"
  ssh_public_key      = module.vm1_master.ssh_public_key  # Use same key as master
  save_ssh_key_locally = false
  cloud_init_data     = file("${path.module}/../../cloud-init/worker-node.yaml")
}
```

## Lifecycle Management

The module ignores changes to `custom_data` to prevent VM recreation when cloud-init changes. To apply new cloud-init:
1. Update cloud-init file
2. Recreate VM manually: `terraform taint module.vm1.azurerm_linux_virtual_machine.main`
3. Apply: `terraform apply`

Or use user data scripts for runtime changes.

## Troubleshooting

### SSH Connection Failed
1. Verify public IP: `terraform output vm1_public_ip`
2. Check NSG allows SSH from your IP
3. Test SSH key: `ssh-keygen -l -f <private_key_path>`
4. Check VM is running: Azure Portal → VM → Overview

### Cloud-Init Not Running
1. Check cloud-init logs on VM: `sudo cat /var/log/cloud-init.log`
2. Verify cloud-init status: `cloud-init status`
3. Check user data: `sudo cat /var/lib/cloud/instance/user-data.txt`

### VM Creation Fails
1. Check disk SKU compatibility with VM size
2. Verify availability zone supported in region
3. Check quota limits: `az vm list-usage --location centralus`

## Cost Optimization

**Development** (~$37/VM/month):
- VM: Standard_B2s (~$37)
- Disk: StandardSSD_LRS 20GB (~$1.50)
- Public IP: Static Standard (~$3.50)

**Production** (~$100/VM/month):
- VM: Standard_D2s_v5 (~$96)
- Disk: Premium_LRS 30GB (~$5)
- Public IP: Replace with Azure Bastion (~$140/month shared)

**5 VMs Dev Total**: ~$210/month

## Validation

All inputs are validated:
- **vm_name**: 1-64 chars, lowercase, alphanumeric, hyphens
- **vm_disk_size_gb**: 20-4096 GB
- **vm_disk_sku**: Must be valid Azure disk SKU
- **vm_private_ip**: Must be valid IP address
- **vm_zone**: Must be '1', '2', '3', or null
- **vm_role**: Must be 'master' or 'worker'
- **admin_username**: Must start with lowercase letter
