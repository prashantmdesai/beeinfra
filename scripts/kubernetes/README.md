# Kubernetes Setup Scripts

This directory contains scripts for installing, configuring, and managing Kubernetes clusters.

## Overview

These scripts automate the setup and management of Kubernetes 1.30 clusters on Ubuntu VMs. They include:
- Kubernetes installation (kubeadm, kubelet, kubectl)
- Master node initialization
- Worker node joining
- Calico CNI installation
- Cluster verification

## Scripts

### 1. install-k8s-1.30.sh

**Purpose**: Install Kubernetes 1.30 components on Ubuntu VMs

**Features**:
- ✅ Idempotent (safe to run multiple times)
- ✅ Automatic prerequisite checking
- ✅ Swap disable (required for Kubernetes)
- ✅ Kernel module loading (overlay, br_netfilter)
- ✅ Sysctl configuration for networking
- ✅ Kubernetes APT repository setup
- ✅ Install kubeadm, kubelet, kubectl
- ✅ Version locking to prevent unintended upgrades
- ✅ Comprehensive logging

**Usage**:
```bash
# Install with default version (1.30)
sudo ./install-k8s-1.30.sh

# Install specific version
sudo K8S_VERSION=1.30 ./install-k8s-1.30.sh
```

**Prerequisites**:
- Ubuntu 20.04/22.04
- Root access
- Internet connectivity
- Minimum 2GB RAM
- Minimum 10GB disk space

**Output**:
- Log file: `/var/log/kubernetes/install-k8s-1.30.log`
- Installed: kubeadm, kubelet, kubectl v1.30

---

### 2. init-master.sh

**Purpose**: Initialize Kubernetes master/control-plane node

**Features**:
- ✅ Idempotent (safe to run multiple times)
- ✅ Automatic cluster initialization
- ✅ kubectl configuration for root and regular user
- ✅ Join token generation
- ✅ Join command saved to file share
- ✅ Cluster info exported
- ✅ API server readiness check
- ✅ Comprehensive logging

**Usage**:
```bash
# Initialize with defaults
sudo ./init-master.sh

# Initialize with custom pod CIDR
sudo K8S_POD_CIDR=192.168.0.0/16 ./init-master.sh

# Initialize with custom API server address
sudo K8S_API_SERVER_ADDRESS=10.0.1.4 ./init-master.sh
```

**Environment Variables**:
- `K8S_POD_CIDR`: Pod network CIDR (default: 192.168.0.0/16)
- `K8S_SERVICE_CIDR`: Service CIDR (default: 10.96.0.0/12)
- `K8S_API_SERVER_ADDRESS`: API server advertise address (default: first IP)
- `FILE_SHARE_MOUNT`: File share mount point (default: /mnt/dats-beeux-dev-shaf-afs)

**Prerequisites**:
- Kubernetes installed (run install-k8s-1.30.sh first)
- containerd running
- kubelet enabled
- File share mounted (optional, for join token sharing)

**Output**:
- Log file: `/var/log/kubernetes/init-master.log`
- kubeconfig: `/etc/kubernetes/admin.conf`
- User kubeconfig: `~/.kube/config`
- Join command: `${FILE_SHARE_MOUNT}/k8s-join-token/join-command.sh`
- Cluster info: `${FILE_SHARE_MOUNT}/k8s-join-token/cluster-info.txt`

---

### 3. join-worker.sh

**Purpose**: Join worker node to Kubernetes cluster

**Features**:
- ✅ Idempotent (safe to run multiple times)
- ✅ Automatic join command retrieval from file share
- ✅ Join command validation
- ✅ Configurable timeout for waiting
- ✅ Kubelet verification
- ✅ API server connectivity check
- ✅ Comprehensive logging

**Usage**:
```bash
# Join with defaults (waits up to 10 minutes)
sudo ./join-worker.sh

# Join with custom timeout
sudo MAX_WAIT_SECONDS=1200 ./join-worker.sh

# Join with custom file share location
sudo FILE_SHARE_MOUNT=/mnt/custom-share ./join-worker.sh
```

**Environment Variables**:
- `FILE_SHARE_MOUNT`: File share mount point (default: /mnt/dats-beeux-dev-shaf-afs)
- `MAX_WAIT_SECONDS`: Maximum wait time for join command (default: 600)

**Prerequisites**:
- Kubernetes installed (run install-k8s-1.30.sh first)
- containerd running
- kubelet enabled
- File share mounted with join command available
- Master node initialized

**Output**:
- Log file: `/var/log/kubernetes/join-worker.log`
- kubelet.conf: `/etc/kubernetes/kubelet.conf`
- CA certificate: `/etc/kubernetes/pki/ca.crt`

---

### 4. install-calico.sh

**Purpose**: Install Calico CNI plugin for Kubernetes networking

**Features**:
- ✅ Idempotent (safe to run multiple times)
- ✅ Calico operator installation
- ✅ Custom resource configuration
- ✅ IP pool configuration with pod CIDR
- ✅ VXLANCrossSubnet encapsulation
- ✅ NAT outgoing enabled
- ✅ Pod readiness verification
- ✅ Installation status checking
- ✅ Comprehensive logging

**Usage**:
```bash
# Install with defaults
sudo ./install-calico.sh

# Install with custom pod CIDR
sudo K8S_POD_CIDR=192.168.0.0/16 ./install-calico.sh

# Install specific Calico version
sudo CALICO_VERSION=v3.27.0 ./install-calico.sh
```

**Environment Variables**:
- `CALICO_VERSION`: Calico version (default: v3.27.0)
- `K8S_POD_CIDR`: Pod network CIDR (default: 192.168.0.0/16)

**Prerequisites**:
- Kubernetes master initialized (run init-master.sh first)
- kubectl configured
- API server accessible
- Internet connectivity

**Output**:
- Log file: `/var/log/kubernetes/install-calico.log`
- Namespaces: tigera-operator, calico-system
- Pods: calico-node (per node), calico-kube-controllers

---

### 5. verify-cluster.sh

**Purpose**: Comprehensive cluster health verification

**Features**:
- ✅ Cluster information display
- ✅ Node status checking
- ✅ System pod verification
- ✅ Networking status
- ✅ Component health
- ✅ Resource usage (if metrics-server available)
- ✅ Storage configuration
- ✅ DNS verification
- ✅ Color-coded output
- ✅ Comprehensive summary

**Usage**:
```bash
# Verify cluster (can run as non-root if kubectl configured)
./verify-cluster.sh

# Verify as root
sudo ./verify-cluster.sh
```

**Prerequisites**:
- Kubernetes cluster running
- kubectl configured
- kubeconfig available

**Output**:
- Log file: `/var/log/kubernetes/verify-cluster.log`
- Color-coded console output:
  - 🟢 Green: Success/OK
  - 🟡 Yellow: Warnings
  - 🔴 Red: Errors
  - 🔵 Blue: Information

---

## Deployment Workflows

### New Cluster Setup (Master + Workers)

**On Master Node (VM1)**:
```bash
# 1. Install Kubernetes
sudo ./install-k8s-1.30.sh

# 2. Initialize master
sudo ./init-master.sh

# 3. Install Calico CNI
sudo ./install-calico.sh

# 4. Verify cluster
./verify-cluster.sh
```

**On Worker Nodes (VM2-VM5)**:
```bash
# 1. Install Kubernetes
sudo ./install-k8s-1.30.sh

# 2. Join cluster (waits for master join command)
sudo ./join-worker.sh
```

**On Master Node (verify full cluster)**:
```bash
# Wait for all workers to join
kubectl get nodes -w

# Verify complete cluster
./verify-cluster.sh
```

---

## Environment Variables

All scripts support environment variables for configuration:

| Variable | Default | Description |
|----------|---------|-------------|
| `K8S_VERSION` | 1.30 | Kubernetes version to install |
| `K8S_POD_CIDR` | 192.168.0.0/16 | Pod network CIDR |
| `K8S_SERVICE_CIDR` | 10.96.0.0/12 | Service CIDR |
| `K8S_API_SERVER_ADDRESS` | (auto) | API server advertise address |
| `CALICO_VERSION` | v3.27.0 | Calico CNI version |
| `FILE_SHARE_MOUNT` | /mnt/dats-beeux-dev-shaf-afs | File share mount point |
| `MAX_WAIT_SECONDS` | 600 | Join command wait timeout |

---

## Logging

All scripts generate detailed logs:

| Script | Log File |
|--------|----------|
| install-k8s-1.30.sh | /var/log/kubernetes/install-k8s-1.30.log |
| init-master.sh | /var/log/kubernetes/init-master.log |
| join-worker.sh | /var/log/kubernetes/join-worker.log |
| install-calico.sh | /var/log/kubernetes/install-calico.log |
| verify-cluster.sh | /var/log/kubernetes/verify-cluster.log |

**View logs**:
```bash
# Tail specific log
tail -f /var/log/kubernetes/install-k8s-1.30.log

# View all Kubernetes logs
tail -f /var/log/kubernetes/*.log

# Search for errors
grep -i error /var/log/kubernetes/*.log
```

---

## Troubleshooting

### Installation Issues

**Problem**: Kubernetes packages fail to install
```bash
# Check repository configuration
cat /etc/apt/sources.list.d/kubernetes.list

# Verify GPG key
ls -la /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Update package index
sudo apt-get update

# Retry installation
sudo ./install-k8s-1.30.sh
```

**Problem**: Swap disable fails
```bash
# Check swap status
swapon --show

# Manually disable
sudo swapoff -a

# Update fstab
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

### Master Initialization Issues

**Problem**: kubeadm init fails with preflight errors
```bash
# Check swap
swapon --show

# Check kernel modules
lsmod | grep br_netfilter

# Check ports
sudo netstat -tuln | grep -E "6443|10250"

# Run with ignore preflight
sudo kubeadm init --ignore-preflight-errors=all
```

**Problem**: API server not accessible
```bash
# Check kubelet status
sudo systemctl status kubelet

# Check kubelet logs
sudo journalctl -u kubelet -f

# Check API server logs
sudo journalctl -u kube-apiserver -f
```

### Worker Join Issues

**Problem**: Join command not found
```bash
# Check file share mount
df -h | grep /mnt

# Check join command file
ls -la /mnt/dats-beeux-dev-shaf-afs/k8s-join-token/

# Regenerate on master
sudo kubeadm token create --print-join-command
```

**Problem**: Join fails with certificate error
```bash
# Verify master is reachable
ping <master-ip>

# Check port 6443
telnet <master-ip> 6443

# Manually specify discovery token CA cert hash
sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

### Calico Installation Issues

**Problem**: Calico pods not starting
```bash
# Check operator logs
kubectl logs -n tigera-operator -l k8s-app=tigera-operator

# Check calico-node logs
kubectl logs -n calico-system -l k8s-app=calico-node

# Check installation status
kubectl get installation default -o yaml
```

**Problem**: Nodes not becoming Ready
```bash
# Wait for Calico pods
kubectl get pods -n calico-system -w

# Check node conditions
kubectl describe node <node-name>

# Restart kubelet
sudo systemctl restart kubelet
```

---

## Best Practices

1. **Always run install-k8s-1.30.sh first** on all nodes
2. **Initialize master before joining workers**
3. **Install CNI immediately after master init**
4. **Use file share for join token sharing** (automated)
5. **Verify cluster after each major step**
6. **Check logs if any step fails**
7. **Keep scripts idempotent** (safe to re-run)
8. **Use environment variables** for customization
9. **Monitor resource usage** during setup
10. **Document any customizations**

---

## Integration with Cloud-Init

These scripts complement the cloud-init templates in `terraform/cloud-init/`:

- **master-node.yaml**: Calls install-k8s-1.30.sh, init-master.sh, install-calico.sh
- **worker-node.yaml**: Calls install-k8s-1.30.sh, join-worker.sh

Cloud-init automates the entire process, but these scripts can be run manually for:
- Troubleshooting
- Custom configurations
- Cluster upgrades
- Additional node additions

---

## File Structure

```
scripts/kubernetes/
├── install-k8s-1.30.sh    # Install Kubernetes components (400+ lines)
├── init-master.sh          # Initialize master node (350+ lines)
├── join-worker.sh          # Join worker to cluster (300+ lines)
├── install-calico.sh       # Install Calico CNI (400+ lines)
├── verify-cluster.sh       # Verify cluster health (450+ lines)
└── README.md              # This file
```

---

## Next Steps

After cluster setup:
1. ✅ Verify cluster: `./verify-cluster.sh`
2. 📦 Deploy applications to cluster
3. 📊 Install metrics-server for resource monitoring
4. 🔒 Configure RBAC policies
5. 💾 Set up persistent storage
6. 🌐 Configure ingress controller
7. 📈 Set up monitoring (Prometheus/Grafana)
8. 📝 Configure logging (ELK/Loki)

---

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubeadm Setup](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Calico Documentation](https://docs.projectcalico.org/)
- [Ubuntu Kubernetes Guide](https://ubuntu.com/kubernetes)
