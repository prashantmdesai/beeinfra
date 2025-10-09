# Deployment Orchestration Scripts

This directory contains scripts for end-to-end deployment, validation, and rollback of the Azure infrastructure. These scripts automate the complete deployment lifecycle from initialization to verification.

## Overview

The deployment orchestration scripts provide:
- Automated infrastructure deployment with Terraform
- Comprehensive validation of deployed resources
- Safe rollback capabilities with state backups
- Detailed logging and error handling
- User confirmation for destructive operations

## Scripts

### 1. deploy-all.sh

Complete deployment orchestration for Azure infrastructure. Handles Terraform initialization, planning, and applying with comprehensive validation.

**Purpose:**
- Initialize Terraform working directory
- Validate configuration and variables
- Generate and review execution plan
- Apply infrastructure changes
- Verify deployed resources
- Save deployment outputs

**Usage:**
```bash
# Basic usage
./deploy-all.sh

# With custom Terraform directory
TERRAFORM_DIR=/path/to/terraform ./deploy-all.sh
```

**Prerequisites:**
- Terraform installed (v1.0+)
- Azure CLI installed and authenticated (`az login`)
- Required tfvars files configured (see below)
- Network connectivity to Azure

**Deployment Steps:**

1. **Prerequisites Check**
   - Verifies Terraform and Azure CLI installation
   - Checks Azure authentication
   - Validates Terraform directory exists

2. **Tfvars Validation**
   - Ensures all required tfvars files exist:
     - `terraform.tfvars`
     - `vm1-infr1-dev.tfvars`
     - `vm2-secu1-dev.tfvars`
     - `vm3-apps1-dev.tfvars`
     - `vm4-apps2-dev.tfvars`
     - `vm5-data1-dev.tfvars`

3. **State Backup**
   - Backs up existing Terraform state if present
   - Backup location: `/tmp/terraform-backups/terraform.tfstate.TIMESTAMP`

4. **Terraform Init**
   - Initializes Terraform working directory
   - Downloads required providers
   - Sets up backend (if configured)

5. **Terraform Validate**
   - Validates Terraform configuration syntax
   - Checks for configuration errors

6. **Terraform Plan**
   - Generates execution plan
   - Shows resources to be created/modified/destroyed
   - Saves plan to file for apply step
   - Displays plan summary

7. **User Confirmation**
   - Prompts user to review plan
   - Requires explicit "yes" confirmation to proceed

8. **Terraform Apply**
   - Applies the execution plan
   - Creates all infrastructure resources
   - Typically creates ~30 resources

9. **Save Outputs**
   - Saves Terraform outputs to JSON file
   - Displays key outputs (IPs, resource names)

10. **Verify Resources**
    - Verifies resource group exists
    - Counts deployed VMs
    - Lists VM details

**Expected Resources:**
- 1 Resource Group
- 1 Virtual Network
- 1 Subnet
- 1 Network Security Group with ~32 rules
- 1 Storage Account
- 1 File Share (100GB)
- 5 Virtual Machines (1 master + 4 workers)
- 5 Network Interfaces
- 5 Public IP Addresses
- 5 OS Disks
- Additional supporting resources

**Outputs:**
```
Deployment Outputs:
  - Resource Group: dats-beeux-dev-rg
  - Virtual Network: dats-beeux-dev-vnet
  - Storage Account: datsbeeuxdevstacct
  - VM IPs: 10.0.1.4-8
  - Public IPs: [assigned dynamically]
```

**Logs:**
- `/var/log/deployment/deploy-all.log`
- Plan files: `/tmp/terraform-backups/terraform.plan.TIMESTAMP`

**Error Handling:**
- Comprehensive error messages
- State backups preserved on failure
- Cleanup instructions provided
- Exit codes: 0 (success), 1 (failure)

---

### 2. validate-deployment.sh

Comprehensive validation of deployed Azure infrastructure. Performs 11 independent validation tests with color-coded output.

**Purpose:**
- Verify all resources deployed correctly
- Validate network connectivity
- Check NSG rules configuration
- Provide SSH access information
- Identify configuration issues

**Usage:**
```bash
# Basic usage
./validate-deployment.sh

# With custom Terraform directory
TERRAFORM_DIR=/path/to/terraform ./validate-deployment.sh
```

**Validation Tests:**

1. **Prerequisites**
   - ✓ Terraform installed and version
   - ✓ Azure CLI installed and version
   - ✓ Azure authentication active
   - ✓ Terraform directory exists

2. **Terraform State**
   - ✓ State file exists
   - ✓ Resources in state (count)
   - ✓ Expected resource count met (≥25)

3. **Resource Group**
   - ✓ Resource group name in outputs
   - ✓ Resource group exists in Azure
   - ✓ Resource group location
   - ✓ Resources in group (count)

4. **Networking**
   - ✓ VNet name in outputs
   - ✓ VNet exists in Azure
   - ✓ VNet address space
   - ✓ Subnet count
   - ✓ NSG count

5. **Storage**
   - ✓ Storage account name in outputs
   - ✓ Storage account exists
   - ✓ Storage account SKU
   - ✓ File share exists
   - ✓ File share quota (100GB)

6. **Virtual Machines**
   - ✓ All 5 VMs deployed
   - ✓ VM power states (running/stopped)
   - ✓ VM private IPs
   - ✓ VM sizes displayed

7. **Network Connectivity**
   - ✓ All 5 public IPs allocated
   - ✓ Public IP addresses listed
   - ✓ All 5 NICs created

8. **NSG Rules**
   - ✓ NSG exists
   - ✓ Rule count (≥30 rules)
   - ✓ Key rules present (SSH, K8s API)

9. **SSH Access** (Manual Test)
   - ⚠ Provides SSH commands for testing
   - ⚠ Requires manual verification

10. **Cloud-Init Status** (Manual Test)
    - ⚠ Provides verification commands
    - ⚠ Requires SSH access to VMs

11. **Kubernetes Cluster** (Manual Test)
    - ⚠ Provides kubectl commands
    - ⚠ Requires SSH access to master

**Output Example:**
```
==========================================
Test 1: Prerequisites
==========================================
✓ Terraform installed: v1.5.7
✓ Azure CLI installed: 2.53.0
✓ Azure authenticated: My Subscription
✓ Terraform directory exists: /path/to/terraform

==========================================
Test 2: Terraform State
==========================================
✓ Terraform state file exists
✓ Resources in state: 32
✓ Expected resource count met (≥25 resources)

...

==========================================
Validation Summary
==========================================
Total Tests: 11
Passed: 8
Failed: 0
Warnings: 3

Status: PASSED WITH WARNINGS ⚠
==========================================
```

**Color Codes:**
- **Green (✓)**: Test passed
- **Red (✗)**: Test failed
- **Yellow (⚠)**: Warning or manual test required
- **Blue**: Section headers

**Exit Codes:**
- 0: All tests passed (warnings allowed)
- 1: One or more tests failed

**Logs:**
- `/var/log/deployment/validate-deployment.log`

**Manual Validation:**

After running the script, SSH to VMs for additional checks:

```bash
# SSH to master node
ssh beeuser@<master-public-ip>

# Check cloud-init status
cloud-init status --wait
cat /var/log/cloud-init-output.log

# Verify Kubernetes cluster
kubectl get nodes
kubectl get pods --all-namespaces
kubectl cluster-info

# Verify Azure File Share mount
df -h /mnt/dats-beeux-dev-shaf-afs
ls -la /mnt/dats-beeux-dev-shaf-afs
```

---

### 3. rollback-deployment.sh

Safe rollback of Azure infrastructure deployment. Destroys all resources with comprehensive backups and user confirmation.

**Purpose:**
- Destroy all deployed infrastructure
- Backup state before destruction
- Verify complete resource removal
- Clean up local Terraform files
- Provide recovery information

**Usage:**
```bash
# Basic usage
./rollback-deployment.sh

# With custom Terraform directory
TERRAFORM_DIR=/path/to/terraform ./rollback-deployment.sh
```

**Prerequisites:**
- Terraform installed
- Azure CLI authenticated
- Existing Terraform state file
- Network connectivity to Azure

**Rollback Steps:**

1. **Prerequisites Check**
   - Verifies Terraform and Azure CLI
   - Checks for existing state file
   - Validates Azure authentication

2. **State Backup**
   - Backs up current state
   - Backs up state backup file
   - Backup location: `/tmp/terraform-backups/terraform.tfstate.pre-rollback.TIMESTAMP`

3. **Show Current Resources**
   - Lists all resources in Terraform state
   - Displays Azure resources in resource group
   - Shows what will be destroyed

4. **Generate Destroy Plan**
   - Creates destroy execution plan
   - Shows resources to be destroyed
   - Saves plan for apply step

5. **User Confirmation** (Double Confirmation)
   - First: Type "destroy" to confirm
   - Second: Type "yes" to proceed
   - WARNING messages displayed
   - Emphasizes destructive operation

6. **Terraform Destroy**
   - Executes destroy plan
   - Removes all resources
   - Deletes in reverse dependency order

7. **Verify Destruction**
   - Checks Terraform state is empty
   - Verifies resource group deleted
   - Lists any remaining resources

8. **Cleanup Local State**
   - Moves state files to backup
   - Removes .terraform directory
   - Removes lock file

**Warning Messages:**
```
==========================================
WARNING: DESTRUCTIVE OPERATION
==========================================
This will DESTROY all infrastructure resources including:
  - All 5 Virtual Machines
  - Virtual Network and Subnets
  - Storage Account and File Share
  - Network Security Groups
  - Public IP Addresses
  - Network Interfaces
  - All data will be PERMANENTLY DELETED

This operation CANNOT be undone!
==========================================
```

**Confirmation Process:**
```bash
Are you ABSOLUTELY SURE you want to destroy all resources? Type 'destroy' to confirm: destroy

Final confirmation - Type 'yes' to proceed: yes
```

**Backups Created:**
- State file: `/tmp/terraform-backups/terraform.tfstate.pre-rollback.TIMESTAMP`
- State backup: `/tmp/terraform-backups/terraform.tfstate.backup.pre-rollback.TIMESTAMP`
- Destroy plan: `/tmp/terraform-backups/terraform.destroy.plan.TIMESTAMP`
- Final state: `/tmp/terraform-backups/terraform.tfstate.final.TIMESTAMP`

**Logs:**
- `/var/log/deployment/rollback-deployment.log`

**Recovery:**

If you need to redeploy after rollback:

```bash
# Navigate to Terraform directory
cd terraform/environments/dev

# Redeploy infrastructure
../../scripts/deployment/deploy-all.sh
```

**Error Recovery:**

If rollback fails mid-process:

1. Check logs: `tail -f /var/log/deployment/rollback-deployment.log`
2. Review Azure portal for remaining resources
3. Manual cleanup if needed:
   ```bash
   az group delete --name dats-beeux-dev-rg --yes --no-wait
   ```
4. Restore state from backup if needed
5. Re-run rollback script

---

## Common Features

All deployment scripts share these features:

### 1. Common Libraries
- **logging-standard.sh**: Standardized logging with timestamps
- **error-handlers.sh**: Consistent error handling
- **validation-helpers.sh**: Input validation and checks

### 2. Comprehensive Logging
Each script logs to `/var/log/deployment/`:
- Detailed operation logs
- Error messages with context
- Success confirmations
- Resource information

### 3. State Management
- Automatic state backups before changes
- Backup location: `/tmp/terraform-backups/`
- Timestamped backup files
- Plan files saved for reference

### 4. Error Handling
- Proper exit codes (0 for success, 1 for errors)
- Detailed error messages with troubleshooting steps
- Cleanup instructions on failure
- State preservation on errors

### 5. User Confirmations
- Interactive prompts for destructive operations
- Plan review before apply
- Double confirmation for destroy
- Cancellation allowed at any stage

---

## Deployment Workflow

### Initial Deployment

1. **Prepare Configuration**
   ```bash
   cd terraform/environments/dev
   
   # Copy example files
   cp terraform.tfvars.example terraform.tfvars
   cp vm1-infr1-dev.tfvars.example vm1-infr1-dev.tfvars
   cp vm2-secu1-dev.tfvars.example vm2-secu1-dev.tfvars
   cp vm3-apps1-dev.tfvars.example vm3-apps1-dev.tfvars
   cp vm4-apps2-dev.tfvars.example vm4-apps2-dev.tfvars
   cp vm5-data1-dev.tfvars.example vm5-data1-dev.tfvars
   
   # Edit with your values
   nano terraform.tfvars
   # ... edit other tfvars files
   ```

2. **Deploy Infrastructure**
   ```bash
   ../../scripts/deployment/deploy-all.sh
   ```

3. **Validate Deployment**
   ```bash
   ../../scripts/deployment/validate-deployment.sh
   ```

4. **Manual Verification**
   ```bash
   # SSH to master node
   ssh beeuser@<master-ip>
   
   # Check Kubernetes cluster
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

### Update Deployment

To update existing infrastructure:

1. **Modify Configuration**
   ```bash
   # Edit tfvars files with changes
   nano terraform.tfvars
   ```

2. **Deploy Changes**
   ```bash
   # Run deployment script (will show plan for changes)
   ./scripts/deployment/deploy-all.sh
   ```

3. **Validate Changes**
   ```bash
   ./scripts/deployment/validate-deployment.sh
   ```

### Rollback Deployment

To completely remove infrastructure:

```bash
# Run rollback script
./scripts/deployment/rollback-deployment.sh

# Confirm when prompted
# Type 'destroy' and then 'yes'
```

---

## Configuration Files

### Required Tfvars Files

1. **terraform.tfvars** - General configuration
   ```hcl
   project          = "dats-beeux"
   environment      = "dev"
   location         = "canadacentral"
   admin_username   = "beeuser"
   ssh_public_key   = "ssh-rsa ..."
   storage_access_key = "your_key_here"
   github_pat       = "your_pat_here"
   ```

2. **vm1-infr1-dev.tfvars** - Master node configuration
   ```hcl
   vm_name     = "vm1-infr1-dev"
   vm_size     = "Standard_D2s_v3"
   private_ip  = "10.0.1.4"
   node_type   = "master"
   ```

3. **vm2-secu1-dev.tfvars** - Worker node 1
   ```hcl
   vm_name     = "vm2-secu1-dev"
   vm_size     = "Standard_D2s_v3"
   private_ip  = "10.0.1.5"
   node_type   = "worker"
   ```

4. **vm3-apps1-dev.tfvars** - Worker node 2
5. **vm4-apps2-dev.tfvars** - Worker node 3
6. **vm5-data1-dev.tfvars** - Worker node 4

---

## Troubleshooting

### Deployment Failures

**Problem**: Terraform plan or apply fails

**Solutions**:
1. Check logs:
   ```bash
   tail -f /var/log/deployment/deploy-all.log
   ```

2. Verify Azure authentication:
   ```bash
   az account show
   az account list
   ```

3. Check Terraform configuration:
   ```bash
   cd terraform/environments/dev
   terraform validate
   ```

4. Review tfvars files for correct values

5. Check Azure quotas and limits:
   ```bash
   az vm list-usage --location canadacentral -o table
   ```

### Validation Failures

**Problem**: Validation script reports failures

**Solutions**:
1. Review specific test failures in output

2. Check Azure portal for resource status

3. Wait for cloud-init to complete (can take 10-15 minutes):
   ```bash
   ssh beeuser@<vm-ip>
   cloud-init status --wait
   ```

4. Verify network connectivity

5. Check NSG rules:
   ```bash
   az network nsg rule list --resource-group dats-beeux-dev-rg --nsg-name dats-beeux-dev-nsg -o table
   ```

### Rollback Failures

**Problem**: Rollback script fails to destroy resources

**Solutions**:
1. Check logs:
   ```bash
   tail -f /var/log/deployment/rollback-deployment.log
   ```

2. Manual resource group deletion:
   ```bash
   az group delete --name dats-beeux-dev-rg --yes --no-wait
   ```

3. Check for resource locks:
   ```bash
   az lock list --resource-group dats-beeux-dev-rg
   ```

4. Verify Azure permissions (contributor/owner role required)

5. Re-run rollback after manual cleanup

### State Issues

**Problem**: Terraform state corrupted or inconsistent

**Solutions**:
1. Restore from backup:
   ```bash
   cd terraform/environments/dev
   cp /tmp/terraform-backups/terraform.tfstate.TIMESTAMP terraform.tfstate
   ```

2. Refresh state:
   ```bash
   terraform refresh
   ```

3. Import existing resources:
   ```bash
   terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/dats-beeux-dev-rg
   ```

4. If state is completely lost, consider recreating from Azure:
   - Use `terraform import` for each resource
   - Or destroy and redeploy

---

## Best Practices

### Before Deployment

1. **Review Configuration**
   - Verify all tfvars files configured correctly
   - Check SSH key is correct
   - Validate storage access key
   - Confirm GitHub PAT is valid

2. **Azure Preparation**
   - Ensure authenticated: `az login`
   - Select correct subscription: `az account set --subscription "..."`
   - Check quotas and limits
   - Verify permissions (contributor/owner role)

3. **Backup Existing State**
   - If updating existing deployment
   - Copy state file manually for safety
   - Document current configuration

### During Deployment

1. **Review Plan Carefully**
   - Check resource counts (should be ~30)
   - Verify no unexpected deletions
   - Confirm resource names and locations
   - Review security group rules

2. **Monitor Progress**
   - Watch deployment logs
   - Check Azure portal for resource creation
   - Note any warnings or errors
   - Be patient (deployment takes 15-20 minutes)

3. **Don't Interrupt**
   - Avoid Ctrl+C during apply
   - Let deployment complete
   - If interrupted, can re-run safely (idempotent)

### After Deployment

1. **Always Validate**
   - Run validation script immediately
   - Check all tests pass
   - Perform manual SSH verification
   - Test Kubernetes cluster

2. **Document Configuration**
   - Note public IP addresses
   - Save output values
   - Document any customizations
   - Update team documentation

3. **Monitor Resources**
   - Check VM status regularly
   - Monitor costs in Azure portal
   - Review activity logs
   - Set up alerts if needed

---

## Security Considerations

### Credentials Management

- **Never commit secrets to git**
- Use `.gitignore` for `*.tfvars` files (not `.example`)
- Store GitHub PAT securely
- Rotate storage access keys regularly
- Use Azure Key Vault for production

### SSH Access

- Use strong SSH keys (RSA 4096 or Ed25519)
- Restrict SSH access to specific IPs in NSG
- Disable password authentication
- Use SSH agent forwarding cautiously
- Rotate SSH keys periodically

### Network Security

- Review NSG rules before deployment
- Minimize exposed ports
- Use private IPs for internal communication
- Configure Azure Firewall for production
- Enable network flow logs

### State File Security

- State files contain sensitive data
- Restrict access to state files
- Use remote backend (Azure Storage) for production
- Enable state locking
- Encrypt state at rest

---

## Performance Optimization

### Deployment Time

- Average deployment: 15-20 minutes
- Factors affecting time:
  - Number of VMs (5 VMs)
  - VM sizes
  - Cloud-init execution
  - Kubernetes installation

### Parallel Execution

Terraform deploys resources in parallel where possible:
- VMs created in parallel
- Network resources can overlap
- Dependencies respected automatically

### Resource Cleanup

- Destroy takes 5-10 minutes
- Resource deletion in reverse order
- Some resources have soft-delete (recovery possible)

---

## Related Documentation

- [Terraform Modules](../../terraform/modules/README.md) - Module documentation
- [Dev Environment](../../terraform/environments/dev/README.md) - Environment config
- [Cloud-Init Templates](../cloud-init/README.md) - VM initialization
- [Kubernetes Scripts](../kubernetes/README.md) - Cluster management
- [Infrastructure Scripts](../infrastructure/README.md) - Infrastructure management

---

## Support

For issues or questions:
1. Check logs in `/var/log/deployment/`
2. Review troubleshooting section above
3. Verify prerequisites are met
4. Test individual Terraform commands manually
5. Check Azure portal for resource status
6. Contact infrastructure team

---

## Changelog

### Version 1.0.0 (2025-10-08)
- Initial release
- Complete deployment orchestration script
- Comprehensive validation script
- Safe rollback script with confirmations
- Comprehensive documentation

---

**Last Updated**: 2025-10-08  
**Version**: 1.0.0  
**Maintainer**: Infrastructure Team
