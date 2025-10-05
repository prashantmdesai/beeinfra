# DEPLOYMENT GUIDE

## Quick Deployment Commands

### Deploy VM3 (Kubernetes Master)
```bash
cd dats/beeux/dev/vm3/scripts
./vm3-infr-deploy-azurecli-comprehensive.sh -k "ssh-rsa AAAAB3NzaC1yc2E..."
```

### Rename Existing VMs (Optional)
```bash
cd scripts
./rename-vms.sh
```

### Setup Azure File Share on New VM
```bash  
cd dats/beeux/dev/shared/scripts
./shared-storage-setup-azurefiles-mount.sh
```

## Deployment Steps

### 1. Deploy VM3 (Infrastructure/Master Node)
```bash
cd dats/beeux/dev/vm3/scripts
chmod +x vm3-infr-deploy-azurecli-comprehensive.sh
./vm3-infr-deploy-azurecli-comprehensive.sh -k "YOUR_SSH_PUBLIC_KEY"
```

### 2. Initialize Kubernetes Cluster (Optional)
```bash
# SSH to VM3 after deployment
ssh beeuser@[VM3_PUBLIC_IP]

# Initialize master
sudo kubeadm init --config=/tmp/kubeadm-config.yaml

# Configure kubectl
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Install CNI (Calico)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### 3. Verification Commands
```bash
# Test inter-VM connectivity
ssh beeuser@10.0.1.4  # VM1
ssh beeuser@10.0.1.5  # VM2

# Check Azure File Share
df -h | grep shared-data

# Run health check
/usr/local/bin/vm-health-check.sh
```

## Common Operations

### Rename VMs (Optional)
```bash
cd scripts
chmod +x rename-vms.sh
./rename-vms.sh
```

### Setup Azure File Share
```bash
cd dats/beeux/dev/shared/scripts  
chmod +x shared-storage-setup-azurefiles-mount.sh
./shared-storage-setup-azurefiles-mount.sh
```

### Troubleshooting
```bash
# Check VM status
az vm show --resource-group rg-dev-centralus --name [VM_NAME]

# Check services
systemctl status docker kubelet

# View logs
journalctl -u kubelet -f
tail -f /var/log/vm3-infr-setup.log
```