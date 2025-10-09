# Infrastructure Setup Scripts

This directory contains scripts for setting up and managing infrastructure components on Azure VMs. These scripts complement the cloud-init templates by providing manual management capabilities and additional automation.

## Overview

The infrastructure setup scripts handle:
- Azure File Share mounting and verification
- GitHub repository cloning and authentication
- Infrastructure component initialization
- Manual management of cloud resources

## Scripts

### 1. mount-azure-fileshare.sh

Mounts an Azure File Share using SMB/CIFS protocol. This script is idempotent and can be run multiple times safely.

**Purpose:**
- Mount Azure File Share for shared storage across cluster nodes
- Create standard directory structure
- Configure persistent mounting via fstab
- Verify mount accessibility

**Usage:**
```bash
# Basic usage (uses defaults)
sudo ./mount-azure-fileshare.sh

# With environment variables
STORAGE_ACCOUNT_NAME=mystorageacct \
FILE_SHARE_NAME=myshare \
STORAGE_ACCESS_KEY=mykey \
MOUNT_POINT=/mnt/myshare \
sudo ./mount-azure-fileshare.sh
```

**Environment Variables:**
- `STORAGE_ACCOUNT_NAME`: Azure storage account name (default: datsbeeuxdevstacct)
- `FILE_SHARE_NAME`: Azure file share name (default: dats-beeux-dev-shaf-afs)
- `STORAGE_ACCESS_KEY`: Storage account access key (required)
- `MOUNT_POINT`: Local mount point (default: /mnt/dats-beeux-dev-shaf-afs)

**Prerequisites:**
- Must run as root
- Network connectivity to Azure Storage
- Valid storage account access key

**Features:**
- Automatic cifs-utils installation
- Idempotent mounting (checks if already mounted)
- Secure credentials storage (/etc/smbcredentials/*.cred with 600 permissions)
- fstab entry for persistence across reboots
- Standard directory structure creation:
  - k8s-join-token (for Kubernetes join tokens)
  - logs (for application logs)
  - configs (for configuration files)
  - data (for application data)
  - backups (for backup files)
  - scripts (for automation scripts)
- Comprehensive verification and summary

**Mount Options:**
- `nofail`: Don't fail boot if mount fails
- `credentials`: Use credentials file
- `dir_mode=0777`: Directory permissions
- `file_mode=0666`: File permissions
- `serverino`: Use server-provided inode numbers
- `nosharesock`: Don't use shared socket
- `actimeo=30`: Attribute cache timeout

**Logs:**
- `/var/log/infrastructure/mount-azure-fileshare.log`

**Integration:**
- Called by cloud-init templates during VM initialization
- Can be run manually for troubleshooting or remounting

---

### 2. verify-mount.sh

Comprehensive verification script for Azure File Share mount. Performs 9 independent tests with color-coded output.

**Purpose:**
- Verify mount point exists and is accessible
- Check mount status and permissions
- Test read/write operations
- Validate directory structure
- Verify persistence configuration
- Audit security settings
- Benchmark performance

**Usage:**
```bash
# Basic usage
sudo ./verify-mount.sh

# Run as regular user (some checks may be limited)
./verify-mount.sh
```

**Verification Tests:**

1. **Mount Point Exists**: Checks if mount directory exists
2. **File Share Mounted**: Verifies mount via `mountpoint` command
3. **Mount Accessible**: Tests read access and lists contents
4. **Write Permissions**: Creates, reads, and deletes test file
5. **Storage Information**: Displays storage usage with warnings at 80%/90%
6. **Directory Structure**: Validates 6 standard directories
7. **fstab Persistence**: Checks for persistent mount entry
8. **Credentials Security**: Audits credentials file permissions (should be 600)
9. **Performance Test**: 10MB write/read benchmark with timing

**Output:**
```
==========================================
Azure File Share Mount Verification
==========================================

Test 1: Mount point exists
✓ Mount point exists: /mnt/dats-beeux-dev-shaf-afs

Test 2: File share is mounted
✓ File share is mounted at /mnt/dats-beeux-dev-shaf-afs

...

==========================================
Verification Summary
==========================================
Total Tests: 8
Passed: 8
Failed: 0
Warnings: 0

Status: ALL CHECKS PASSED ✓
==========================================
```

**Color Codes:**
- **Green (✓)**: Success/OK
- **Yellow (⚠)**: Warnings
- **Red (✗)**: Errors/Failures
- **Blue**: Information headers

**Logs:**
- `/var/log/infrastructure/verify-mount.log`

**Use Cases:**
- Post-mount verification
- Troubleshooting mount issues
- Health checks
- Performance testing
- Security audits

---

### 3. clone-infra-repo.sh

Clones the infrastructure repository from GitHub using Personal Access Token authentication.

**Purpose:**
- Clone infrastructure code repository
- Configure repository settings
- Set proper ownership and permissions
- Verify successful clone

**Usage:**
```bash
# Basic usage (uses defaults)
GITHUB_PAT=your_pat_here sudo ./clone-infra-repo.sh

# With environment variables
GITHUB_PAT=your_pat_here \
GITHUB_REPO_URL=https://github.com/username/repo \
CLONE_PATH=/path/to/clone \
REPO_OWNER=username \
sudo ./clone-infra-repo.sh
```

**Environment Variables:**
- `GITHUB_PAT`: GitHub Personal Access Token (required)
- `GITHUB_REPO_URL`: Repository URL (default: https://github.com/prashantmdesai/infra)
- `CLONE_PATH`: Local clone path (default: /home/beeuser/plt)
- `REPO_OWNER`: Repository owner user (default: beeuser)

**Prerequisites:**
- Must run as root
- Git installed (auto-installed if missing)
- Valid GitHub PAT with repo access
- Network connectivity to GitHub

**Features:**
- Automatic git installation if missing
- Idempotent cloning (checks if already cloned)
- Backup of existing directory if present
- Repository configuration (user.name, user.email)
- Proper ownership and permissions:
  - Directories: 755
  - Files: 644
  - Scripts: 755 (*.sh files)
- Comprehensive verification
- Pull latest changes if already cloned

**Credentials Sources** (in order):
1. `GITHUB_PAT` environment variable
2. `/home/${REPO_OWNER}/.github-credentials` file
3. `/etc/github-credentials.conf` file

**Logs:**
- `/var/log/infrastructure/clone-infra-repo.log`

**Integration:**
- Called by cloud-init templates during VM initialization
- Can be run manually for repository updates

---

### 4. setup-github-auth.sh

Configures GitHub authentication using Personal Access Token for the target user.

**Purpose:**
- Configure Git global settings
- Set up credential storage
- Create helper scripts
- Test authentication
- Configure SSH known hosts

**Usage:**
```bash
# Basic usage (uses defaults)
GITHUB_PAT=your_pat_here sudo ./setup-github-auth.sh

# With environment variables
GITHUB_PAT=your_pat_here \
TARGET_USER=username \
GITHUB_USERNAME=githubuser \
sudo ./setup-github-auth.sh
```

**Environment Variables:**
- `GITHUB_PAT`: GitHub Personal Access Token (required)
- `TARGET_USER`: System user for authentication setup (default: beeuser)
- `GITHUB_USERNAME`: GitHub username (default: prashantmdesai)

**Prerequisites:**
- Must run as root
- Git installed
- Target user must exist

**Features:**
- Git global configuration:
  - user.name
  - user.email
  - init.defaultBranch (main)
  - credential.helper (store)
- Credential storage:
  - `~/.github-credentials` (environment variables)
  - `~/.git-credentials` (git credential store)
- SSH known hosts configuration
- Helper scripts:
  - `git-push-infra`: Push changes to infrastructure repo
  - `git-pull-infra`: Pull changes from infrastructure repo
- Idempotent (checks if already configured)
- Authentication testing

**Created Files:**
- `~/.github-credentials` (600 permissions)
- `~/.git-credentials` (600 permissions)
- `~/.gitconfig` (git global configuration)
- `~/.local/bin/git-push-infra` (helper script)
- `~/.local/bin/git-pull-infra` (helper script)
- `~/.ssh/known_hosts` (GitHub host keys)

**Helper Scripts Usage:**
```bash
# Push changes to infrastructure repository
git-push-infra "Update configuration"

# Pull latest changes
git-pull-infra
```

**Logs:**
- `/var/log/infrastructure/setup-github-auth.log`

**Integration:**
- Called by cloud-init templates during VM initialization
- Can be run manually for authentication reconfiguration

---

## Common Features

All infrastructure scripts share these features:

### 1. Common Libraries
- **logging-standard.sh**: Standardized logging with timestamps
- **error-handlers.sh**: Consistent error handling
- **validation-helpers.sh**: Input validation and checks

### 2. Idempotency
All scripts check current state before making changes:
- Skip operations if already configured
- Safe to run multiple times
- Update/refresh existing configurations

### 3. Comprehensive Logging
Each script logs to `/var/log/infrastructure/`:
- Detailed operation logs
- Error messages with context
- Success confirmations
- Summary information

### 4. Error Handling
- Proper exit codes (0 for success, 1 for errors)
- Detailed error messages
- Rollback on failures where applicable
- Prerequisites checking

### 5. Security
- Secure credentials storage (600 permissions)
- Non-root execution where possible
- Sensitive data masking in logs
- Proper ownership and permissions

---

## Deployment Workflow

### 1. Initial Deployment (via cloud-init)

The infrastructure scripts are automatically executed during VM initialization:

```yaml
# cloud-init excerpt
runcmd:
  # Mount Azure File Share
  - sudo /opt/scripts/infrastructure/mount-azure-fileshare.sh
  
  # Verify mount
  - sudo /opt/scripts/infrastructure/verify-mount.sh
  
  # Clone infrastructure repository
  - sudo /opt/scripts/infrastructure/clone-infra-repo.sh
  
  # Setup GitHub authentication
  - sudo /opt/scripts/infrastructure/setup-github-auth.sh
```

### 2. Manual Execution

For troubleshooting or manual updates:

```bash
# 1. Mount Azure File Share
sudo STORAGE_ACCESS_KEY=your_key \
  /opt/scripts/infrastructure/mount-azure-fileshare.sh

# 2. Verify mount
sudo /opt/scripts/infrastructure/verify-mount.sh

# 3. Clone infrastructure repository
sudo GITHUB_PAT=your_pat \
  /opt/scripts/infrastructure/clone-infra-repo.sh

# 4. Setup GitHub authentication
sudo GITHUB_PAT=your_pat \
  /opt/scripts/infrastructure/setup-github-auth.sh
```

---

## Environment Configuration

### Storage Account Configuration

Create `/etc/azure-fileshare.conf`:

```bash
# Azure File Share Configuration
STORAGE_ACCOUNT_NAME=datsbeeuxdevstacct
FILE_SHARE_NAME=dats-beeux-dev-shaf-afs
STORAGE_ACCESS_KEY=your_access_key_here
MOUNT_POINT=/mnt/dats-beeux-dev-shaf-afs
```

Set permissions:
```bash
sudo chmod 600 /etc/azure-fileshare.conf
```

### GitHub Configuration

Create `/etc/github-credentials.conf`:

```bash
# GitHub Credentials Configuration
GITHUB_PAT=your_github_pat_here
GITHUB_REPO_URL=https://github.com/prashantmdesai/infra
CLONE_PATH=/home/beeuser/plt
REPO_OWNER=beeuser
GITHUB_USERNAME=prashantmdesai
```

Set permissions:
```bash
sudo chmod 600 /etc/github-credentials.conf
```

---

## Troubleshooting

### Mount Issues

**Problem**: File share won't mount

**Solutions**:
1. Check storage account credentials:
   ```bash
   cat /etc/smbcredentials/datsbeeuxdevstacct.cred
   ```

2. Verify network connectivity:
   ```bash
   ping datsbeeuxdevstacct.file.core.windows.net
   ```

3. Check cifs-utils installation:
   ```bash
   dpkg -l | grep cifs-utils
   ```

4. View detailed logs:
   ```bash
   tail -f /var/log/infrastructure/mount-azure-fileshare.log
   ```

5. Try manual mount:
   ```bash
   sudo mount -t cifs //datsbeeuxdevstacct.file.core.windows.net/dats-beeux-dev-shaf-afs \
     /mnt/dats-beeux-dev-shaf-afs \
     -o credentials=/etc/smbcredentials/datsbeeuxdevstacct.cred
   ```

### Clone Issues

**Problem**: Repository won't clone

**Solutions**:
1. Verify GitHub PAT:
   ```bash
   echo $GITHUB_PAT
   ```

2. Test GitHub connectivity:
   ```bash
   curl -I https://github.com
   ```

3. Try manual clone:
   ```bash
   git clone https://your_pat@github.com/prashantmdesai/infra /tmp/test-clone
   ```

4. View detailed logs:
   ```bash
   tail -f /var/log/infrastructure/clone-infra-repo.log
   ```

### Authentication Issues

**Problem**: Git authentication fails

**Solutions**:
1. Check credentials file:
   ```bash
   cat ~/.git-credentials
   ```

2. Test authentication:
   ```bash
   git ls-remote https://github.com/prashantmdesai/infra.git HEAD
   ```

3. Reconfigure authentication:
   ```bash
   sudo GITHUB_PAT=your_pat ./setup-github-auth.sh
   ```

4. View detailed logs:
   ```bash
   tail -f /var/log/infrastructure/setup-github-auth.log
   ```

### Verification Failures

**Problem**: Verification script reports failures

**Solutions**:
1. Run verification with verbose output:
   ```bash
   sudo ./verify-mount.sh | tee verify-output.txt
   ```

2. Check mount status:
   ```bash
   mount | grep dats-beeux-dev-shaf-afs
   mountpoint /mnt/dats-beeux-dev-shaf-afs
   ```

3. Test write permissions:
   ```bash
   sudo touch /mnt/dats-beeux-dev-shaf-afs/test.txt
   sudo rm /mnt/dats-beeux-dev-shaf-afs/test.txt
   ```

4. Check storage usage:
   ```bash
   df -h /mnt/dats-beeux-dev-shaf-afs
   ```

---

## Security Best Practices

### 1. Credentials Management

- Store credentials in files with 600 permissions
- Never commit credentials to version control
- Use environment variables for sensitive data
- Rotate credentials regularly

### 2. File Permissions

- Scripts: 755 (executable, read-only for others)
- Credentials: 600 (owner read/write only)
- Configuration: 644 (read-only for others)
- Directories: 755 (accessible by all)

### 3. User Privileges

- Run infrastructure scripts as root only when necessary
- Use sudo for privilege escalation
- Set proper ownership for cloned repositories
- Limit GitHub PAT scope to necessary permissions

### 4. Network Security

- Verify SSL/TLS for GitHub connections
- Use Azure Storage over HTTPS
- Configure firewall rules for necessary ports
- Monitor access logs

---

## Integration with Cloud-Init

The infrastructure scripts are designed to work seamlessly with cloud-init templates:

### Master Node (master-node.yaml)

```yaml
write_files:
  - path: /etc/azure-fileshare.conf
    content: |
      STORAGE_ACCOUNT_NAME=${storage_account_name}
      FILE_SHARE_NAME=${file_share_name}
      STORAGE_ACCESS_KEY=${storage_access_key}
    permissions: '0600'

  - path: /etc/github-credentials.conf
    content: |
      GITHUB_PAT=${github_pat}
      GITHUB_REPO_URL=${github_repo_url}
    permissions: '0600'

runcmd:
  - /opt/scripts/infrastructure/mount-azure-fileshare.sh
  - /opt/scripts/infrastructure/verify-mount.sh
  - /opt/scripts/infrastructure/clone-infra-repo.sh
  - /opt/scripts/infrastructure/setup-github-auth.sh
```

### Worker Node (worker-node.yaml)

```yaml
write_files:
  - path: /etc/azure-fileshare.conf
    content: |
      STORAGE_ACCOUNT_NAME=${storage_account_name}
      FILE_SHARE_NAME=${file_share_name}
      STORAGE_ACCESS_KEY=${storage_access_key}
    permissions: '0600'

runcmd:
  - /opt/scripts/infrastructure/mount-azure-fileshare.sh
  - /opt/scripts/infrastructure/verify-mount.sh
```

---

## Monitoring and Maintenance

### Log Monitoring

Monitor script execution:
```bash
# Watch all infrastructure logs
tail -f /var/log/infrastructure/*.log

# Check for errors
grep -i error /var/log/infrastructure/*.log

# View recent operations
tail -n 100 /var/log/infrastructure/mount-azure-fileshare.log
```

### Periodic Verification

Create a cron job for periodic verification:
```bash
# Add to crontab
0 * * * * /opt/scripts/infrastructure/verify-mount.sh >> /var/log/infrastructure/hourly-verify.log 2>&1
```

### Health Checks

Create a simple health check script:
```bash
#!/bin/bash
# health-check.sh

echo "Infrastructure Health Check - $(date)"

# Check mount
if mountpoint -q /mnt/dats-beeux-dev-shaf-afs; then
    echo "✓ File share mounted"
else
    echo "✗ File share not mounted"
fi

# Check repository
if [[ -d /home/beeuser/plt/.git ]]; then
    echo "✓ Repository cloned"
else
    echo "✗ Repository not cloned"
fi

# Check GitHub auth
if sudo -u beeuser git config --global user.name &>/dev/null; then
    echo "✓ GitHub authentication configured"
else
    echo "✗ GitHub authentication not configured"
fi
```

---

## Related Documentation

- [Cloud-Init Templates](../cloud-init/README.md) - VM initialization templates
- [Kubernetes Scripts](../kubernetes/README.md) - Kubernetes cluster management
- [Common Scripts](../common/README.md) - Shared libraries and utilities
- [Deployment Guide](../../docs/deployment-guide.md) - Complete deployment process

---

## Support

For issues or questions:
1. Check logs in `/var/log/infrastructure/`
2. Review troubleshooting section above
3. Verify prerequisites are met
4. Test individual components manually
5. Contact infrastructure team

---

## Changelog

### Version 1.0.0 (2025-10-08)
- Initial release
- Mount Azure File Share script
- Verify mount script
- Clone infrastructure repository script
- Setup GitHub authentication script
- Comprehensive documentation

---

**Last Updated**: 2025-10-08  
**Version**: 1.0.0  
**Maintainer**: Infrastructure Team
