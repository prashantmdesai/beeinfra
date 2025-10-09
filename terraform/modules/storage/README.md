# Storage Module

Creates Azure Storage Account and File Share for shared storage across the Kubernetes cluster in the BeEux Word Learning Platform.

## Features

- **Storage Account**: Secure, network-restricted storage with HTTPS and TLS 1.2
- **File Share**: SMB 3.0 compatible Azure Files share with configurable quota
- **Pre-created Directories**: Organized structure for K8s tokens, logs, backups, and app data
- **Network Security**: Deny by default, allow only from specified subnet and IP ranges

## Usage

```hcl
module "storage" {
  source = "../../modules/storage"

  org_name              = "dats"
  platform_name         = "beeux"
  env_name              = "dev"
  location              = "centralus"
  resource_group_name   = module.resource_group.rg_name

  storage_account_name  = "datsbeeuxdevstacct"
  file_share_name       = "dats-beeux-dev-shaf-afs"
  file_share_quota_gb   = 100

  subnet_ids = [module.networking.subnet_id]
  allowed_ip_ranges = [
    "136.56.79.92",    # Laptop
    "136.56.79.0/24"   # WiFi network
  ]

  tags = {
    CostCenter = "Engineering"
  }
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
| storage_account_name | Storage account name (3-24 chars, lowercase alphanumeric) | string | - | yes |
| account_tier | Standard or Premium | string | "Standard" | no |
| account_replication_type | LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS | string | "LRS" | no |
| account_kind | StorageV2 (recommended) | string | "StorageV2" | no |
| file_share_name | File share name (3-63 chars) | string | - | yes |
| file_share_quota_gb | File share size (1-102400 GB) | number | 100 | no |
| subnet_ids | Subnet IDs allowed to access storage | list(string) | [] | no |
| allowed_ip_ranges | IP addresses/CIDRs allowed (without /32 suffix) | list(string) | [] | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| storage_account_id | Storage account ID | No |
| storage_account_name | Storage account name | No |
| primary_access_key | Primary access key | **Yes** |
| secondary_access_key | Secondary access key | **Yes** |
| primary_connection_string | Primary connection string | **Yes** |
| primary_file_endpoint | Primary file endpoint URL | No |
| file_share_name | File share name | No |
| file_share_id | File share ID | No |
| file_share_url | File share URL | No |
| mount_command | Linux mount command (template) | No |
| mount_path | Recommended mount path | No |

## Pre-created Directories

The module automatically creates these directories in the file share:

1. **k8s-join-token/**: Stores Kubernetes join token and certificates
2. **logs/**: Centralized log storage for all VMs
3. **backups/**: Database and application backups
4. **app-data/**: Shared application data

## Mounting the File Share

### On Linux VMs

```bash
# Install cifs-utils if not already installed
sudo apt-get update && sudo apt-get install -y cifs-utils

# Create mount point
sudo mkdir -p /mnt/dats-beeux-dev-shaf-afs

# Mount the file share
sudo mount -t cifs //datsbeeuxdevstacct.file.core.windows.net/dats-beeux-dev-shaf-afs \
  /mnt/dats-beeux-dev-shaf-afs \
  -o vers=3.0,username=datsbeeuxdevstacct,password=<ACCESS_KEY>,dir_mode=0777,file_mode=0777,serverino

# Add to /etc/fstab for persistent mount
echo "//datsbeeuxdevstacct.file.core.windows.net/dats-beeux-dev-shaf-afs /mnt/dats-beeux-dev-shaf-afs cifs nofail,vers=3.0,username=datsbeeuxdevstacct,password=<ACCESS_KEY>,dir_mode=0777,file_mode=0777,serverino 0 0" | sudo tee -a /etc/fstab
```

### Using the Output

You can use the `mount_command` output directly:

```bash
terraform output -raw mount_command | sudo bash -c 'eval "$(cat -)"'
```

## Security Features

### Network Rules
- **Default Action**: Deny all traffic
- **Bypass**: Allow Azure services (for Portal access)
- **Allowed Sources**:
  - VMs in specified subnet(s)
  - Laptop IP address
  - WiFi network CIDR

### HTTPS & TLS
- HTTPS traffic only (no HTTP)
- Minimum TLS version: 1.2
- No public blob access allowed

### Access Keys
- Primary and secondary keys rotated regularly
- Keys marked as sensitive in Terraform state
- Use Azure Key Vault for production

## Cost Estimation

For **dev environment** (Standard LRS, 100GB):
- Storage account: ~$2/month (100GB)
- Transaction costs: ~$1-3/month (varies by usage)
- **Total**: ~$3-5/month

For **production** (Standard GRS, 500GB):
- Storage account: ~$40/month (500GB with geo-redundancy)
- Transaction costs: ~$5-10/month
- **Total**: ~$45-50/month

## Examples

### Development Environment (Cost-Optimized)
```hcl
module "storage_dev" {
  source = "../../modules/storage"
  
  org_name              = "dats"
  platform_name         = "beeux"
  env_name              = "dev"
  location              = "centralus"
  resource_group_name   = module.resource_group.rg_name
  storage_account_name  = "datsbeeuxdevstacct"
  file_share_name       = "dats-beeux-dev-shaf-afs"
  file_share_quota_gb   = 100
  account_tier          = "Standard"
  account_replication_type = "LRS"
  subnet_ids            = [module.networking.subnet_id]
  allowed_ip_ranges     = ["136.56.79.92", "136.56.79.0/24"]
}
```

### Production Environment (High Availability)
```hcl
module "storage_prd" {
  source = "../../modules/storage"
  
  org_name              = "dats"
  platform_name         = "beeux"
  env_name              = "prd"
  location              = "eastus"
  resource_group_name   = module.resource_group.rg_name
  storage_account_name  = "datsbeeuxprdstacct"
  file_share_name       = "dats-beeux-prd-shaf-afs"
  file_share_quota_gb   = 500
  account_tier          = "Standard"
  account_replication_type = "GRS"  # Geo-redundant
  subnet_ids            = [module.networking.subnet_id]
  allowed_ip_ranges     = ["10.200.0.0/24"]  # VPN only
  
  tags = {
    Environment = "Production"
    Compliance  = "Required"
    Backup      = "Daily"
  }
}
```

## Validation

All inputs are validated:
- **storage_account_name**: 3-24 characters, lowercase alphanumeric only
- **file_share_name**: 3-63 characters, lowercase, start/end with letter/number
- **account_tier**: Must be Standard or Premium
- **account_replication_type**: Must be LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS
- **file_share_quota_gb**: Must be between 1 and 102400 GB

## Troubleshooting

### Mount Fails with "Permission Denied"
1. Verify storage account key is correct
2. Check network rules allow your VM's subnet
3. Ensure SMB port 445 is open in NSG

### Cannot Access from Laptop
1. Verify your IP is in `allowed_ip_ranges`
2. Check if IP has changed (dynamic IP)
3. Verify NSG allows SMB port 445

### File Share Full
1. Check current usage: `df -h /mnt/dats-beeux-dev-shaf-afs`
2. Increase quota: Update `file_share_quota_gb` variable
3. Clean up old logs/backups in respective directories
