# Calicoctl Installation - Automated Setup

## Overview

`calicoctl` is now automatically installed on all Kubernetes nodes (master and workers) during the initial cloud-init provisioning process.

## Changes Made

### 1. Master Node (`master-node.yaml`)

**Location**: `terraform/cloud-init/master-node.yaml`

**Modified Section**: Install Calico CNI script (`/usr/local/bin/install-calico.sh`)

**Added**:
- Automatic download and installation of `calicoctl v3.27.0` binary
- Binary placed in `/usr/local/bin/calicoctl` (available system-wide)
- Version verification after installation
- Added to the Calico installation step (runs after Calico CNI is deployed)

### 2. Worker Nodes (`worker-node.yaml`)

**Location**: `terraform/cloud-init/worker-node.yaml`

**Added New Script**: `/usr/local/bin/install-calicoctl.sh`
- Downloads `calicoctl v3.27.0` binary from GitHub releases
- Installs to `/usr/local/bin/calicoctl`
- Verifies installation with version check

**Modified**: Bootstrap orchestration (`/usr/local/bin/bootstrap-worker.sh`)
- Added Step 5: Install calicoctl (runs after joining Kubernetes cluster)

## Calico and Calicoctl Versions

- **Calico Version**: v3.27.0
- **Calicoctl Version**: v3.27.0 (matching Calico version)

## Installation Timeline

### Master Node Bootstrap Sequence:
1. Mount Azure File Share
2. Install Docker
3. Install Kubernetes
4. Initialize Kubernetes Master
5. **Install Calico CNI + calicoctl** ← calicoctl installed here
6. Clone Infrastructure Repository

### Worker Node Bootstrap Sequence:
1. Mount Azure File Share
2. Install Docker
3. Install Kubernetes
4. Join Kubernetes Cluster
5. **Install calicoctl** ← calicoctl installed here

## Usage

After a VM is provisioned (or re-provisioned), `calicoctl` will be available system-wide:

```bash
# Check version
calicoctl version

# View Calico nodes
calicoctl get nodes -o wide

# View IP pools
calicoctl get ippools

# Check node status (requires sudo)
sudo calicoctl node status

# View workload endpoints
calicoctl get workloadendpoints

# View BGP peer status
calicoctl get bgppeer

# View BGP configuration
calicoctl get bgpconfig
```

## Verification

To verify calicoctl is installed on all nodes:

```bash
# From any node with kubectl access
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== $node ==="
  ssh $node "calicoctl version --poll=1s 2>&1 | head -2"
  echo ""
done
```

## Manual Installation (If Needed)

If you need to install calicoctl manually on a node:

```bash
# Download and install
CALICO_VERSION="v3.27.0"
curl -L -o /tmp/calicoctl \
  https://github.com/projectcalico/calico/releases/download/${CALICO_VERSION}/calicoctl-linux-amd64
chmod +x /tmp/calicoctl
sudo mv /tmp/calicoctl /usr/local/bin/calicoctl

# Verify
calicoctl version
```

## Logs

Installation logs can be found at:

**Master Node**:
- `/logs/install-calico-<timestamp>.log` (includes calicoctl installation)
- `/logs/bootstrap-master-<timestamp>.log` (full bootstrap log)

**Worker Nodes**:
- `/var/log/bootstrap-worker.log` (includes calicoctl installation step)

## Future VM Provisioning

All new VMs provisioned using these cloud-init templates will automatically have `calicoctl` installed and ready to use.

## Related Files

- `terraform/cloud-init/master-node.yaml` - Master node cloud-init configuration
- `terraform/cloud-init/worker-node.yaml` - Worker node cloud-init configuration

## Notes

- The calicoctl version matches the deployed Calico CNI version (v3.27.0)
- Binary is installed system-wide in `/usr/local/bin/`
- No additional configuration required - works out of the box with kubeconfig
- On worker nodes, installation happens after cluster join to ensure connectivity
