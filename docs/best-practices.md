# Best Practices Guide

This document outlines best practices, standards, and conventions used in this infrastructure project. Following these guidelines ensures consistency, maintainability, and security across the platform.

## Table of Contents

1. [Code Organization](#code-organization)
2. [Terraform Standards](#terraform-standards)
3. [Scripting Standards](#scripting-standards)
4. [Security Best Practices](#security-best-practices)
5. [Documentation Standards](#documentation-standards)
6. [Git Workflow](#git-workflow)
7. [Kubernetes Best Practices](#kubernetes-best-practices)
8. [Monitoring and Logging](#monitoring-and-logging)

---

## Code Organization

### Directory Structure

```
beeinfra/
├── terraform/
│   ├── modules/              # Reusable Terraform modules
│   │   ├── resource-group/
│   │   ├── networking/
│   │   ├── storage/
│   │   └── virtual-machine/
│   └── environments/         # Environment-specific configurations
│       ├── dev/
│       ├── staging/          # Future
│       └── prod/             # Future
├── scripts/
│   ├── common/              # Shared libraries
│   ├── kubernetes/          # K8s management
│   ├── infrastructure/      # Infrastructure setup
│   └── deployment/          # Deployment orchestration
├── cloud-init/              # VM initialization templates
└── docs/                    # Documentation
```

### Naming Conventions

**Resources**:
```
{project}-{component}-{environment}-{type}

Examples:
- dats-beeux-dev-rg        (Resource Group)
- dats-beeux-dev-vnet      (Virtual Network)
- vm1-infr1-dev            (Master Node VM)
- vm2-secu1-dev            (Worker Node VM)
```

**Files**:
```
- Terraform: kebab-case (main.tf, variables.tf)
- Scripts: kebab-case (deploy-all.sh, verify-mount.sh)
- Documentation: kebab-case (deployment-guide.md)
```

**Variables**:
```
- Terraform: snake_case (vm_size, storage_account_name)
- Bash: SCREAMING_SNAKE_CASE for constants (LOG_FILE, SCRIPT_DIR)
- Bash: snake_case for variables (vm_name, resource_count)
```

---

## Terraform Standards

### Module Design

**Principle**: Each module should be self-contained and reusable

**Structure**:
```
module/
├── main.tf          # Resource definitions
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── versions.tf      # Provider versions
├── README.md        # Module documentation
└── examples/        # Usage examples
    └── complete/
        └── main.tf
```

**Example Module**:
```hcl
# main.tf
resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location
  
  tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
    }
  )
}

# variables.tf
variable "name" {
  description = "Name of the resource group"
  type        = string
  
  validation {
    condition     = length(var.name) > 0
    error_message = "Resource group name cannot be empty"
  }
}

# outputs.tf
output "id" {
  description = "Resource group ID"
  value       = azurerm_resource_group.main.id
}
```

### Variable Management

**Use tfvars Files**:
```hcl
# Bad: Hardcoded values in main.tf
resource "azurerm_virtual_machine" "main" {
  vm_size = "Standard_D2s_v3"
}

# Good: Variables with defaults
variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_D2s_v3"
}

# Best: Separate tfvars per environment/VM
# vm1-infr1-dev.tfvars
vm_name = "vm1-infr1-dev"
vm_size = "Standard_D2s_v3"
```

### State Management

**Best Practices**:
1. **Use Remote Backend** (production):
   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "terraform-state-rg"
       storage_account_name = "tfstateaccount"
       container_name       = "tfstate"
       key                  = "dev.terraform.tfstate"
     }
   }
   ```

2. **Enable State Locking**:
   ```hcl
   backend "azurerm" {
     use_msi = true
   }
   ```

3. **Backup State Regularly**:
   ```bash
   cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d-%H%M%S)
   ```

### Resource Tagging

**Required Tags**:
```hcl
tags = {
  Project     = "dats-beeux"
  Environment = "dev"
  ManagedBy   = "Terraform"
  Owner       = "infrastructure-team"
  CostCenter  = "engineering"
}
```

### Terraform Workflow

```bash
# 1. Format code
terraform fmt -recursive

# 2. Validate syntax
terraform validate

# 3. Plan changes
terraform plan -out=tfplan

# 4. Review plan
terraform show tfplan

# 5. Apply changes
terraform apply tfplan

# 6. Verify deployment
terraform output
```

---

## Scripting Standards

### Bash Script Template

```bash
#!/bin/bash
################################################################################
# Script: script-name.sh
# Description: Brief description
# Author: Infrastructure Team
# Date: YYYY-MM-DD
# Version: 1.0.0
################################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../common"

source "${COMMON_DIR}/logging-standard.sh"
source "${COMMON_DIR}/error-handlers.sh"
source "${COMMON_DIR}/validation-helpers.sh"

# Script configuration
readonly SCRIPT_NAME="script-name"
readonly LOG_FILE="/var/log/${SCRIPT_NAME}.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

################################################################################
# Function: function_name
# Description: What the function does
################################################################################
function_name() {
    log_info "Starting operation..."
    
    # Implementation
    
    log_info "Operation completed"
    return 0
}

################################################################################
# Main execution
################################################################################
main() {
    log_info "=========================================="
    log_info "Starting ${SCRIPT_NAME}"
    log_info "=========================================="
    
    # Execute functions
    function_name || exit 1
    
    log_info "=========================================="
    log_info "Completed successfully"
    log_info "=========================================="
    
    exit 0
}

# Execute main function
main "$@"
```

### Error Handling

**Always Check Return Codes**:
```bash
# Bad
command_that_might_fail

# Good
command_that_might_fail || {
    log_error "Command failed"
    return 1
}

# Best
if ! command_that_might_fail; then
    log_error "Command failed with specific details"
    return 1
fi
```

### Idempotency

**Make Scripts Idempotent**:
```bash
# Bad: Always creates
kubectl create namespace myapp

# Good: Check first
if ! kubectl get namespace myapp &>/dev/null; then
    kubectl create namespace myapp
fi

# Best: Use declarative approach
kubectl apply -f namespace.yaml
```

### Logging

**Use Consistent Logging**:
```bash
# Use standard logging functions
log_info "Informational message"
log_warning "Warning message"
log_error "Error message"

# Log to file
log_info "Message" | tee -a "$LOG_FILE"

# Include context
log_info "Processing VM: ${vm_name}"
```

---

## Security Best Practices

### Credentials Management

**Never Commit Secrets**:
```bash
# .gitignore
*.tfvars           # Actual values
**/.env            # Environment files
**/credentials     # Credential files
terraform.tfstate  # May contain secrets
```

**Use Environment Variables**:
```bash
# Good
export STORAGE_ACCESS_KEY="secret"
./mount-azure-fileshare.sh

# Better
source /etc/azure-credentials.conf
./mount-azure-fileshare.sh
```

**Secure Credential Files**:
```bash
# Create with restrictive permissions
touch /etc/credentials.conf
chmod 600 /etc/credentials.conf
chown root:root /etc/credentials.conf
```

### SSH Security

**Use Strong Keys**:
```bash
# Generate Ed25519 key (preferred)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Or RSA 4096
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

**Configure SSH Properly**:
```bash
# ~/.ssh/config
Host azure-vm
    HostName <vm-ip>
    User beeuser
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking yes
    UserKnownHostsFile ~/.ssh/known_hosts
```

### Network Security

**Principle of Least Privilege**:
```hcl
# Bad: Allow all
security_rule {
  source_address_prefix = "*"
}

# Good: Specific IPs
security_rule {
  source_address_prefix = "YOUR_IP/32"
}

# Best: Multiple specific rules
security_rule {
  source_address_prefixes = [
    "YOUR_LAPTOP_IP/32",
    "YOUR_VPN_IP/32"
  ]
}
```

### File Permissions

**Standard Permissions**:
```bash
# Scripts
chmod 755 script.sh

# Configuration files
chmod 644 config.yaml

# Credentials
chmod 600 credentials.conf

# Directories
chmod 755 directory/
```

---

## Documentation Standards

### README Structure

Every module/directory should have a README with:
1. **Overview**: What it does
2. **Prerequisites**: Requirements
3. **Usage**: How to use it
4. **Examples**: Code samples
5. **Troubleshooting**: Common issues
6. **Related Docs**: Links

### Code Comments

**When to Comment**:
```bash
# Good: Explain why
# Skip validation for development environment
if [[ "$ENVIRONMENT" == "dev" ]]; then
    skip_validation=true
fi

# Bad: Explain what (code is self-explanatory)
# Set variable to true
skip_validation=true
```

**Function Documentation**:
```bash
################################################################################
# Function: deploy_application
# Description: Deploys application to Kubernetes cluster
# Arguments:
#   $1 - Application name
#   $2 - Environment (dev/staging/prod)
# Returns:
#   0 - Success
#   1 - Failure
# Example:
#   deploy_application "myapp" "dev"
################################################################################
```

### Inline Documentation

```hcl
# Terraform
variable "vm_size" {
  description = "Azure VM size. Standard_D2s_v3 provides 2 vCPUs and 8GB RAM"
  type        = string
  default     = "Standard_D2s_v3"
  
  validation {
    condition     = can(regex("^Standard_[A-Z]", var.vm_size))
    error_message = "VM size must start with 'Standard_'"
  }
}
```

---

## Git Workflow

### Commit Messages

**Format**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Testing
- `chore`: Maintenance

**Examples**:
```
feat(terraform): Add storage module

- Create storage account module
- Add file share support
- Include examples and documentation

Closes #123

---

fix(scripts): Handle missing credentials file

- Check if credentials file exists before sourcing
- Provide helpful error message
- Add fallback to environment variables
```

### Branch Strategy

**Main Branches**:
- `main`: Production-ready code
- `develop`: Integration branch (future)

**Feature Branches**:
```
feature/add-monitoring
feature/multi-region-support
fix/storage-mount-issue
docs/update-deployment-guide
```

### Pull Requests

**PR Checklist**:
- [ ] Code follows style guide
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Changelog updated
- [ ] Reviewed by team member

---

## Kubernetes Best Practices

### Resource Limits

**Always Define Limits**:
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

### Labels and Annotations

**Use Consistent Labels**:
```yaml
metadata:
  labels:
    app: myapp
    version: v1.0.0
    environment: dev
    tier: backend
    managed-by: terraform
```

### Health Checks

**Define Probes**:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

### ConfigMaps and Secrets

**Separate Config from Code**:
```yaml
# ConfigMap for non-sensitive data
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_host: "db.example.com"

# Secret for sensitive data
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  database_password: <base64-encoded>
```

### Network Policies

**Implement Network Segmentation**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      tier: backend
  ingress:
    - from:
        - podSelector:
            matchLabels:
              tier: frontend
```

---

## Monitoring and Logging

### Application Logging

**Structured Logging**:
```python
# Good: Structured logs
logger.info("User login", extra={
    "user_id": 123,
    "ip_address": "1.2.3.4",
    "timestamp": datetime.now()
})

# Bad: Unstructured logs
logger.info(f"User 123 logged in from 1.2.3.4")
```

### Log Levels

**Use Appropriate Levels**:
- **DEBUG**: Detailed diagnostic information
- **INFO**: General informational messages
- **WARNING**: Warning messages (recoverable)
- **ERROR**: Error messages (needs attention)
- **CRITICAL**: Critical issues (system failure)

### Metrics Collection

**Track Key Metrics**:
```python
# Application metrics
http_requests_total.inc()
http_request_duration.observe(duration)
active_users.set(count)

# Infrastructure metrics
cpu_usage_percent
memory_usage_bytes
disk_io_operations
network_throughput_bytes
```

### Alerting

**Alert on Important Events**:
```yaml
# Example: Prometheus alert
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
  for: 10m
  labels:
    severity: critical
  annotations:
    summary: "High error rate detected"
    description: "Error rate is {{ $value | humanizePercentage }}"
```

---

## Performance Optimization

### Terraform Performance

**Parallelize Operations**:
```bash
# Use -parallelism flag
terraform apply -parallelism=10
```

**Target Specific Resources**:
```bash
# Update single resource
terraform apply -target=module.vm1
```

### Script Performance

**Avoid Unnecessary Loops**:
```bash
# Bad: Multiple kubectl calls
for pod in $(kubectl get pods -o name); do
    kubectl describe $pod
done

# Good: Single call
kubectl describe pods
```

### Kubernetes Performance

**Use Horizontal Pod Autoscaling**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

---

## Testing Standards

### Infrastructure Testing

**Test Terraform Changes**:
```bash
# 1. Validate syntax
terraform validate

# 2. Check formatting
terraform fmt -check

# 3. Security scan
tfsec .

# 4. Plan
terraform plan
```

### Script Testing

**Test Scripts Locally**:
```bash
# 1. Syntax check
bash -n script.sh

# 2. ShellCheck
shellcheck script.sh

# 3. Run in dry-run mode
./script.sh --dry-run

# 4. Test with sample data
./script.sh --test
```

### Kubernetes Testing

**Test Manifests**:
```bash
# 1. Validate syntax
kubectl apply --dry-run=client -f manifest.yaml

# 2. Server-side validation
kubectl apply --dry-run=server -f manifest.yaml

# 3. Test in dev namespace
kubectl apply -f manifest.yaml -n dev-test
```

---

## Disaster Recovery

### Backup Strategy

**What to Backup**:
1. Terraform state files
2. Kubernetes manifests
3. Application data
4. Configuration files
5. etcd snapshots

**Backup Schedule**:
- **Daily**: Application data
- **Weekly**: Full system backup
- **Before Changes**: State files

### Recovery Procedures

**Document Recovery Steps**:
1. Restore Terraform state
2. Run `terraform apply`
3. Restore etcd snapshot
4. Verify cluster health
5. Restore application data

---

## Compliance and Auditing

### Access Logging

**Enable Audit Logs**:
```bash
# Kubernetes audit policy
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: Metadata
```

### Change Management

**Document All Changes**:
1. Create issue/ticket
2. Document proposed changes
3. Review with team
4. Implement with PR
5. Verify in dev
6. Deploy to production
7. Update documentation

---

## Continuous Improvement

### Review Regularly

**Schedule Reviews**:
- **Weekly**: Team sync
- **Monthly**: Architecture review
- **Quarterly**: Security audit
- **Annually**: Full infrastructure review

### Metrics to Track

**Infrastructure Metrics**:
- Deployment frequency
- Mean time to recovery (MTTR)
- Change failure rate
- Lead time for changes

**Cost Metrics**:
- Monthly spend by resource
- Cost per application
- Trend analysis
- Optimization opportunities

---

## Related Documentation

- [Architecture](./architecture.md) - Infrastructure design
- [Deployment Guide](./deployment-guide.md) - Deployment steps
- [Troubleshooting](./troubleshooting.md) - Issue resolution
- [Port Mapping](./port-mapping.md) - Network access

---

**Last Updated**: 2025-10-08  
**Version**: 1.0.0  
**Maintainer**: Infrastructure Team
