# Cloud-Init Templates

This directory contains cloud-init configuration templates for automated VM bootstrapping.

## Overview

These templates are used by Terraform to automatically configure VMs during deployment. They handle:
- System initialization and package installation
- Docker and Kubernetes setup
- Azure File Share mounting
- Cluster initialization (master) or joining (workers)
- Infrastructure repository cloning (master only)

## Templates

### 1. master-node.yaml

**Purpose**: Bootstrap the Kubernetes master node (VM1)

**Key Operations**:
1. **System Setup**
   - Set hostname and timezone
   - Create admin user with sudo access
   - Install required packages (Docker, K8s, utilities)

2. **Azure File Share**
   - Mount shared storage using SMB/CIFS
   - Create directory structure (k8s-join-token, logs, configs, data)
   - Configure auto-mount via fstab

3. **Docker Installation**
   - Install Docker CE from official repository
   - Configure systemd cgroup driver
   - Enable and start Docker service

4. **Kubernetes Installation**
   - Disable swap (K8s requirement)
   - Load kernel modules (overlay, br_netfilter)
   - Configure sysctl for networking
   - Install kubeadm, kubelet, kubectl v1.30

5. **Cluster Initialization**
   - Initialize K8s cluster with kubeadm
   - Configure pod network CIDR (192.168.0.0/16)
   - Set up kubectl for admin user
   - Save join command to file share

6. **Calico CNI**
   - Install Calico operator
   - Configure Calico with pod CIDR
   - Wait for Calico pods to be ready

7. **Infrastructure Repository**
   - Clone GitHub repository using PAT
   - Set up repository at /home/beeuser/plt
   - Configure proper permissions

**Variables Required**:
```
${vm_name}                - VM hostname
${vm_role}                - Role: "master"
${vm_components}          - Component list (e.g., "WIOR,WCID")
${vm_private_ip}          - Private IP address
${admin_username}         - Admin user (e.g., "beeuser")
${org_name}               - Organization name
${platform_name}          - Platform name
${env_name}               - Environment name
${storage_account_name}   - Azure Storage account
${file_share_name}        - Azure File Share name
${storage_access_key}     - Storage access key (sensitive)
${github_pat}             - GitHub Personal Access Token (sensitive)
${github_infra_repo}      - GitHub repo URL
${github_infra_path}      - Clone destination path
${k8s_version}            - Kubernetes version (e.g., "1.30")
${k8s_pod_cidr}           - Pod network CIDR
${k8s_cni}                - CNI plugin (e.g., "calico")
```

**Bootstrap Process**:
```
master-node.yaml
    ↓
1. Mount Azure File Share
    ↓
2. Install Docker
    ↓
3. Install Kubernetes
    ↓
4. Initialize K8s Master (kubeadm init)
    ↓
5. Install Calico CNI
    ↓
6. Clone Infrastructure Repo
    ↓
7. Save join command to file share
```

**Logs**: `/var/log/bootstrap-master.log`

### 2. worker-node.yaml

**Purpose**: Bootstrap Kubernetes worker nodes (VM2-VM5)

**Key Operations**:
1. **System Setup**
   - Set hostname and timezone
   - Create admin user with sudo access
   - Install required packages (Docker, K8s, utilities)

2. **Azure File Share**
   - Mount shared storage using SMB/CIFS
   - Configure auto-mount via fstab

3. **Docker Installation**
   - Install Docker CE from official repository
   - Configure systemd cgroup driver
   - Enable and start Docker service

4. **Kubernetes Installation**
   - Disable swap (K8s requirement)
   - Load kernel modules (overlay, br_netfilter)
   - Configure sysctl for networking
   - Install kubeadm, kubelet, kubectl v1.30

5. **Cluster Join**
   - Wait for join command from master (via file share)
   - Execute join command to join cluster
   - Configure kubelet

**Variables Required**:
```
${vm_name}                - VM hostname
${vm_role}                - Role: "worker"
${vm_components}          - Component list (e.g., "KIAM,SCSM,SCCM")
${vm_private_ip}          - Private IP address
${admin_username}         - Admin user (e.g., "beeuser")
${org_name}               - Organization name
${platform_name}          - Platform name
${env_name}               - Environment name
${storage_account_name}   - Azure Storage account
${file_share_name}        - Azure File Share name
${storage_access_key}     - Storage access key (sensitive)
${master_ip}              - Master node IP address
${k8s_version}            - Kubernetes version (e.g., "1.30")
```

**Bootstrap Process**:
```
worker-node.yaml
    ↓
1. Mount Azure File Share
    ↓
2. Install Docker
    ↓
3. Install Kubernetes
    ↓
4. Wait for join command (from file share)
    ↓
5. Join K8s Cluster (kubeadm join)
```

**Logs**: `/var/log/bootstrap-worker.log`

## Usage in Terraform

These templates are referenced in `terraform/environments/dev/main.tf`:

```hcl
# Master node (VM1)
module "vm1_infr1" {
  source = "../../modules/virtual-machine"
  # ... other variables ...
  
  cloud_init_data = base64encode(templatefile("${path.module}/../../cloud-init/master-node.yaml", {
    vm_name              = var.vm1_name
    vm_role              = var.vm1_role
    vm_components        = var.vm1_components
    vm_private_ip        = var.vm1_private_ip
    admin_username       = var.admin_username
    org_name             = var.org_name
    platform_name        = var.platform_name
    env_name             = var.env_name
    storage_account_name = module.storage.storage_account_name
    file_share_name      = module.storage.file_share_name
    storage_access_key   = module.storage.storage_access_key
    github_pat           = var.github_pat
    github_infra_repo    = var.github_infra_repo
    github_infra_path    = var.github_infra_path
    k8s_version          = var.k8s_version
    k8s_pod_cidr         = var.k8s_pod_cidr
    k8s_cni              = var.k8s_cni
  }))
}

# Worker nodes (VM2-VM5)
module "vm2_secu1" {
  source = "../../modules/virtual-machine"
  # ... other variables ...
  
  cloud_init_data = base64encode(templatefile("${path.module}/../../cloud-init/worker-node.yaml", {
    vm_name              = var.vm2_name
    vm_role              = var.vm2_role
    vm_components        = var.vm2_components
    vm_private_ip        = var.vm2_private_ip
    admin_username       = var.admin_username
    org_name             = var.org_name
    platform_name        = var.platform_name
    env_name             = var.env_name
    storage_account_name = module.storage.storage_account_name
    file_share_name      = module.storage.file_share_name
    storage_access_key   = module.storage.storage_access_key
    master_ip            = var.vm1_private_ip
    k8s_version          = var.k8s_version
  }))
}
```

## Environment Variables Set

All VMs get the following environment variables:

```bash
ORGNM=dats              # Organization name
PLTNM=beeux             # Platform name
ENVNM=dev               # Environment name
VM_NAME=<vm-hostname>   # VM name
VM_ROLE=master|worker   # VM role
VM_COMPONENTS=<list>    # Component list
```

These are available in:
- `/etc/profile.d/platform.sh` (system-wide)
- `/etc/environment.d/platform.conf` (systemd)

## Deployment Timeline

**Master Node (VM1)**:
- Package updates: ~3-5 minutes
- Docker installation: ~2-3 minutes
- Kubernetes installation: ~2-3 minutes
- Cluster initialization: ~2-4 minutes
- Calico CNI installation: ~3-5 minutes
- Repository cloning: ~1-2 minutes
- **Total**: ~13-22 minutes

**Worker Nodes (VM2-VM5)**:
- Package updates: ~3-5 minutes
- Docker installation: ~2-3 minutes
- Kubernetes installation: ~2-3 minutes
- Wait for join command: ~1-15 minutes (depends on master completion)
- Cluster join: ~1-2 minutes
- **Total**: ~9-28 minutes

**Full Cluster**: ~20-30 minutes for all 5 VMs to be ready

## Monitoring Bootstrap Progress

### View bootstrap logs

**On master node**:
```bash
ssh beeuser@<master-public-ip>
tail -f /var/log/bootstrap-master.log
```

**On worker nodes**:
```bash
ssh beeuser@<worker-public-ip>
tail -f /var/log/bootstrap-worker.log
```

### Check cloud-init status

```bash
cloud-init status
cloud-init status --long
cloud-init status --wait  # Wait until complete
```

### View cloud-init logs

```bash
# Main log
tail -f /var/log/cloud-init-output.log

# Detailed logs
tail -f /var/log/cloud-init.log
```

### Check Kubernetes cluster status

**On master node**:
```bash
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

## Troubleshooting

### Bootstrap failed

**Check cloud-init logs**:
```bash
cat /var/log/cloud-init-output.log
cat /var/log/bootstrap-master.log  # or bootstrap-worker.log
```

**Common issues**:
1. **Docker installation fails**: Check network connectivity, retry with `apt-get update`
2. **K8s installation fails**: Verify kernel modules loaded (`lsmod | grep overlay`)
3. **Master init fails**: Check swap is disabled (`swapon --show`)
4. **Worker join fails**: Verify master completed, check join command in file share
5. **Calico installation fails**: Wait longer, check pod status (`kubectl get pods -n calico-system`)

### File share not mounted

**Check mount status**:
```bash
df -h | grep /mnt
mount | grep cifs
```

**Verify credentials**:
```bash
cat /etc/smbcredentials/*.cred
cat /etc/azure-fileshare.conf
```

**Manual mount**:
```bash
/usr/local/bin/mount-azure-fileshare.sh
```

### Join command not found

**Check file share**:
```bash
source /etc/azure-fileshare.conf
ls -la $MOUNT_POINT/k8s-join-token/
cat $MOUNT_POINT/k8s-join-token/join-command.sh
```

**Regenerate join token** (on master):
```bash
kubeadm token create --print-join-command
```

### Kubernetes cluster not ready

**Check node status**:
```bash
kubectl get nodes -o wide
kubectl describe node <node-name>
```

**Check pod status**:
```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
```

**Check logs**:
```bash
journalctl -u kubelet -f
journalctl -u docker -f
```

## Security Considerations

1. **Sensitive Variables**:
   - `storage_access_key`: Azure Storage access key
   - `github_pat`: GitHub Personal Access Token
   - Both are passed securely via Terraform and not logged

2. **File Permissions**:
   - `/etc/azure-fileshare.conf`: 0600 (root only)
   - `/home/beeuser/.github-credentials`: 0600 (beeuser only)
   - `/etc/smbcredentials/*.cred`: 0600 (root only)

3. **Network Security**:
   - All ports configured in NSG rules
   - File share accessible only from VNet
   - K8s API secured with TLS certificates

4. **Best Practices**:
   - Never log sensitive values
   - Rotate GitHub PAT regularly
   - Use Azure Key Vault for production secrets
   - Enable encryption at rest for file share

## Customization

To customize bootstrap behavior:

1. **Add additional packages**: Update `packages:` list in YAML
2. **Add custom scripts**: Add to `write_files:` section
3. **Modify bootstrap order**: Update `runcmd:` section
4. **Add pre/post hooks**: Create additional scripts in `/usr/local/bin/`

## File Structure

```
terraform/cloud-init/
├── master-node.yaml        # Master node bootstrap config (500+ lines)
├── worker-node.yaml        # Worker node bootstrap config (400+ lines)
└── README.md              # This file
```

## Next Steps

After cloud-init completes:
1. Verify cluster status: `kubectl get nodes`
2. Deploy applications to K8s cluster
3. Configure persistent volumes
4. Set up monitoring and logging
5. Configure ingress controllers
6. Deploy platform components (from infra repo)

## References

- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Kubernetes Setup](https://kubernetes.io/docs/setup/)
- [Calico Installation](https://docs.projectcalico.org/getting-started/kubernetes/)
- [Azure File Share Mounting](https://learn.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-linux)
- [kubeadm Documentation](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)
