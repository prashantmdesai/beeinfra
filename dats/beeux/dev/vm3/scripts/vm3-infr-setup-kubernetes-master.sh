#!/bin/bash
# =============================================================================
# VM3-INFR-SETUP-KUBERNETES-MASTER.SH
# =============================================================================
# Kubernetes master configuration script following naming convention:
# <component>-<subcomponent>-<purpose>-<function>-<detail>.sh
#
# Sets up dats-beeux-infr-dev as a Kubernetes master node
# Configures Docker, Kubernetes, and necessary components for cluster management
# =============================================================================

set -euo pipefail

# Import logging standard
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../../scripts/logging-standard-bash.sh"

# Initialize logging
setup_logging
echo "Starting Kubernetes master setup at $(date)"

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
apt-get install -y curl wget apt-transport-https ca-certificates gnupg lsb-release

# Install Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Configure Docker for Kubernetes
echo "Configuring Docker for Kubernetes..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl enable docker
systemctl restart docker

# Add user to docker group
usermod -aG docker beeuser

# Install Kubernetes
echo "Installing Kubernetes..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet=1.28.3-1.1 kubeadm=1.28.3-1.1 kubectl=1.28.3-1.1
apt-mark hold kubelet kubeadm kubectl

# Configure kubelet
echo "Configuring kubelet..."
echo 'KUBELET_EXTRA_ARGS="--cloud-provider=external"' > /etc/default/kubelet

# Disable swap
echo "Disabling swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Configure kernel modules
echo "Configuring kernel modules..."
cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Configure sysctl parameters
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Configure containerd
echo "Configuring containerd..."
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# Install additional useful tools
echo "Installing additional tools..."
apt-get install -y htop tree jq unzip git vim

# Install Azure CLI
echo "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install kubectl bash completion
echo "Configuring kubectl bash completion..."
kubectl completion bash > /etc/bash_completion.d/kubectl
echo 'source <(kubectl completion bash)' >> /home/beeuser/.bashrc
echo 'alias k=kubectl' >> /home/beeuser/.bashrc
echo 'complete -F __start_kubectl k' >> /home/beeuser/.bashrc

# Create kubeadm configuration
echo "Creating kubeadm configuration..."
cat > /tmp/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 10.0.1.6
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.3
controlPlaneEndpoint: "10.0.1.6:6443"
networking:
  serviceSubnet: "10.96.0.0/12"
  podSubnet: "192.168.0.0/16"
  dnsDomain: "cluster.local"
apiServer:
  advertiseAddress: 10.0.1.6
controllerManager: {}
scheduler: {}
etcd:
  local:
    dataDir: "/var/lib/etcd"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF

echo "Kubernetes master setup completed at $(date)"
echo "To initialize the cluster, run: sudo kubeadm init --config=/tmp/kubeadm-config.yaml"
echo "Then copy the admin.conf and install a CNI plugin like Calico or Flannel"