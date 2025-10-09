# Resource Group Module

Creates an Azure Resource Group with standardized naming convention for the BeEux Word Learning Platform.

## Naming Convention

```
{org}-{platform}-{env}-rg
```

**Example**: `dats-beeux-dev-rg`

## Usage

```hcl
module "resource_group" {
  source = "../../modules/resource-group"

  org_name      = "dats"
  platform_name = "beeux"
  env_name      = "dev"
  location      = "centralus"

  tags = {
    CostCenter = "Engineering"
    Owner      = "Platform Team"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| org_name | Organization name (lowercase, alphanumeric) | string | - | yes |
| platform_name | Platform name (lowercase, alphanumeric) | string | - | yes |
| env_name | Environment (dev, sit, uat, prd) | string | - | yes |
| location | Azure region | string | "centralus" | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| rg_name | The name of the resource group |
| rg_id | The ID of the resource group |
| rg_location | The location of the resource group |
| rg_tags | The tags applied to the resource group |

## Validation

- **org_name**: Must contain only lowercase letters and numbers
- **platform_name**: Must contain only lowercase letters and numbers
- **env_name**: Must be one of: dev, sit, uat, prd
- **location**: Must contain only lowercase letters

## Default Tags

The module automatically applies these tags:
- `Environment`: The environment name
- `Organization`: The organization name
- `Platform`: The platform name
- `ManagedBy`: "Terraform"
- `Purpose`: "BeEux Word Learning Platform Infrastructure"
- `CreatedDate`: Timestamp of creation (ignored in lifecycle)

## Examples

### Development Environment
```hcl
module "rg_dev" {
  source = "../../modules/resource-group"
  
  org_name      = "dats"
  platform_name = "beeux"
  env_name      = "dev"
  location      = "centralus"
}
```

### Production Environment
```hcl
module "rg_prd" {
  source = "../../modules/resource-group"
  
  org_name      = "dats"
  platform_name = "beeux"
  env_name      = "prd"
  location      = "eastus"
  
  tags = {
    CostCenter = "Production"
    Owner      = "Platform Team"
    Compliance = "Required"
  }
}
```

## Notes

- The `CreatedDate` tag is ignored in lifecycle to prevent unnecessary resource updates
- All naming follows lowercase convention for Azure resource compatibility
- Multi-environment support via `env_name` variable
