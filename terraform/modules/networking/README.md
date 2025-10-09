# Networking Module

Creates Azure Virtual Network, Subnet, and Network Security Group with comprehensive NSG rules for the BeEux Word Learning Platform.

## Features

- **Virtual Network**: Isolated network environment with configurable address space
- **Subnet**: Dedicated subnet for VM placement
- **Network Security Group**: 32 NSG rules for comprehensive port access control
- **Dual Access**: ALL ports accessible from BOTH laptop AND WiFi network

## NSG Rules Summary

### Access Sources
- **Laptop**: `136.56.79.92/32` (priorities 100-240)
- **WiFi Network**: `136.56.79.0/24` (priorities 300-440)
- **Inter-VM**: VirtualNetwork to VirtualNetwork (priority 500)

### Ports Covered

| Service | Ports | Priority (Laptop) | Priority (WiFi) |
|---------|-------|-------------------|-----------------|
| SSH | 22 | 100 | 300 |
| HTTP/HTTPS | 80, 443 | 110 | 310 |
| Keycloak (KIAM) | 8180, 8443 | 120 | 320 |
| Vault (SCSM) | 8200, 8201 | 130 | 330 |
| Config Server (SCCM) | 8888, 8889 | 140 | 340 |
| Gateway/Eureka (SCGC) | 8080, 8761 | 150 | 350 |
| Angular UIs (WEUI, WAUI) | 4200, 4201 | 160 | 360 |
| Swagger & APIs | 8081-8099 | 170 | 370 |
| Redis (SCSD) | 6379 | 180 | 380 |
| PostgreSQL (WDAT) | 5432 | 190 | 390 |
| RabbitMQ (WEDA) | 5672, 15672 | 200 | 400 |
| SMTP (PFIX) | 25, 587 | 210 | 410 |
| Kubernetes API | 6443 | 220 | 420 |
| K8s NodePort Range | 30000-32767 | 230 | 430 |
| SMB File Share | 445 | 240 | 440 |

### Outbound Rules
- VNet-to-VNet: All protocols (priority 100)
- Internet Access: All protocols (priority 110)

## Usage

```hcl
module "networking" {
  source = "../../modules/networking"

  org_name            = "dats"
  platform_name       = "beeux"
  env_name            = "dev"
  location            = "centralus"
  resource_group_name = module.resource_group.rg_name

  vnet_address_space    = "10.0.0.0/16"
  subnet_address_prefix = "10.0.1.0/24"
  laptop_ip             = "136.56.79.92/32"
  wifi_cidr             = "136.56.79.0/24"

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
| vnet_address_space | VNet CIDR | string | "10.0.0.0/16" | no |
| subnet_address_prefix | Subnet CIDR | string | "10.0.1.0/24" | no |
| laptop_ip | Laptop IP (CIDR) | string | - | yes |
| wifi_cidr | WiFi network (CIDR) | string | - | yes |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | Virtual network ID |
| vnet_name | Virtual network name |
| vnet_address_space | VNet address space |
| subnet_id | Subnet ID |
| subnet_name | Subnet name |
| subnet_address_prefix | Subnet address prefix |
| nsg_id | Network security group ID |
| nsg_name | Network security group name |

## Security Notes

⚠️ **DEVELOPMENT CONFIGURATION** ⚠️

This NSG configuration is designed for **DEVELOPMENT** environments with easy access from laptop and WiFi. For **PRODUCTION** environments:

1. **Remove WiFi CIDR rules** (priorities 300-440)
2. **Replace laptop IP with bastion/VPN** gateway
3. **Restrict database ports** (PostgreSQL, Redis) to VNet only
4. **Enable Azure DDoS Protection Standard**
5. **Implement Private Endpoints** for storage
6. **Add Azure Firewall** for advanced threat protection
7. **Enable NSG Flow Logs** for monitoring

## Component Port Mapping

Based on Platform_Register.md:

- **WIOR** (Orchestrator): 8080 (Gateway)
- **WCID** (Identity): 8180/8443 (Keycloak)
- **KIAM** (Keycloak): 8180/8443
- **SCSM** (Vault): 8200/8201
- **SCCM** (Config Server): 8888/8889
- **NGLB** (NGINX): 80/443
- **WEUI** (Web UI): 4200
- **WAUI** (Admin UI): 4201
- **WCAC** (Cache): 6379 (Redis)
- **SWAG** (Swagger): 8081
- **SCGC** (Gateway): 8080/8761
- **SCSD** (Redis): 6379
- **WAPI** (API): 8082-8099
- **PFIX** (Postfix): 25/587
- **WDAT** (PostgreSQL): 5432
- **WEDA** (RabbitMQ): 5672/15672
- **SCBQ** (Batch): 8083

## Examples

### Tighten Security for Production
```hcl
module "networking_prd" {
  source = "../../modules/networking"
  
  org_name            = "dats"
  platform_name       = "beeux"
  env_name            = "prd"
  location            = "eastus"
  resource_group_name = module.resource_group.rg_name
  
  # Use VPN gateway instead of direct laptop/WiFi access
  laptop_ip = "10.200.0.0/24"  # VPN subnet
  wifi_cidr = "10.200.0.0/24"  # Same as VPN for consistency
  
  tags = {
    Environment = "Production"
    Compliance  = "Required"
  }
}
```

## Validation

All CIDR inputs are validated to ensure they're valid CIDR blocks using Terraform's `cidrhost()` function.
