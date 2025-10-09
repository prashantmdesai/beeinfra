#!/bin/bash
################################################################################
# Script: install-k8s-1.30.sh
# Description: Install Kubernetes 1.30 components (kubeadm, kubelet, kubectl)
# Author: Infrastructure Team
# Date: 2025-10-08
# Version: 1.0.0
################################################################################

set -euo pipefail

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../common"

source "${COMMON_DIR}/logging-standard.sh"
source "${COMMON_DIR}/error-handlers.sh"
source "${COMMON_DIR}/validation-helpers.sh"

# Script configuration
readonly SCRIPT_NAME="install-k8s-1.30"
readonly K8S_VERSION="${K8S_VERSION:-1.30}"
readonly LOG_FILE="/var/log/kubernetes/${SCRIPT_NAME}.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

################################################################################
# Function: check_prerequisites
# Description: Verify system prerequisites for Kubernetes installation
################################################################################
check_prerequisites() {
    log_info "Checking prerequisites for Kubernetes installation..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        return 1
    fi
    
    # Check Ubuntu version
    if ! grep -q "Ubuntu" /etc/os-release; then
        log_error "This script is designed for Ubuntu systems"
        return 1
    fi
    
    # Check system architecture
    local arch=$(dpkg --print-architecture)
    if [[ "$arch" != "amd64" && "$arch" != "arm64" ]]; then
        log_error "Unsupported architecture: $arch"
        return 1
    fi
    
    # Check available disk space (minimum 10GB)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 10485760 ]]; then
        log_warning "Low disk space: $(($available_space / 1024 / 1024))GB available"
    fi
    
    # Check available memory (minimum 2GB)
    local available_mem=$(free -m | awk 'NR==2 {print $7}')
    if [[ $available_mem -lt 2048 ]]; then
        log_warning "Low memory: ${available_mem}MB available"
    fi
    
    log_info "Prerequisites check completed successfully"
    return 0
}

################################################################################
# Function: check_if_installed
# Description: Check if Kubernetes is already installed
################################################################################
check_if_installed() {
    log_info "Checking if Kubernetes is already installed..."
    
    if command -v kubeadm &> /dev/null && \
       command -v kubelet &> /dev/null && \
       command -v kubectl &> /dev/null; then
        
        local installed_version=$(kubeadm version -o short)
        log_info "Kubernetes is already installed: $installed_version"
        
        # Check if installed version matches desired version
        if [[ "$installed_version" == *"$K8S_VERSION"* ]]; then
            log_info "Desired version $K8S_VERSION is already installed"
            return 0
        else
            log_warning "Installed version $installed_version differs from desired version $K8S_VERSION"
            return 1
        fi
    fi
    
    log_info "Kubernetes is not installed"
    return 1
}

################################################################################
# Function: disable_swap
# Description: Disable swap (required for Kubernetes)
################################################################################
disable_swap() {
    log_info "Disabling swap..."
    
    # Check if swap is enabled
    if swapon --show | grep -q .; then
        log_info "Swap is currently enabled, disabling..."
        swapoff -a
        
        # Disable swap permanently
        sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
        log_info "Swap disabled and fstab updated"
    else
        log_info "Swap is already disabled"
    fi
    
    return 0
}

################################################################################
# Function: load_kernel_modules
# Description: Load required kernel modules for Kubernetes
################################################################################
load_kernel_modules() {
    log_info "Loading required kernel modules..."
    
    # Create modules configuration
    cat > /etc/modules-load.d/k8s.conf <<EOF
# Kubernetes required kernel modules
overlay
br_netfilter
EOF
    
    # Load modules immediately
    modprobe overlay || log_error "Failed to load overlay module"
    modprobe br_netfilter || log_error "Failed to load br_netfilter module"
    
    # Verify modules are loaded
    if lsmod | grep -q overlay && lsmod | grep -q br_netfilter; then
        log_info "Kernel modules loaded successfully"
        return 0
    else
        log_error "Failed to verify kernel modules"
        return 1
    fi
}

################################################################################
# Function: configure_sysctl
# Description: Configure sysctl parameters for Kubernetes networking
################################################################################
configure_sysctl() {
    log_info "Configuring sysctl parameters..."
    
    # Create sysctl configuration
    cat > /etc/sysctl.d/k8s.conf <<EOF
# Kubernetes networking parameters
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
    
    # Apply sysctl parameters
    sysctl --system &> /dev/null || {
        log_error "Failed to apply sysctl parameters"
        return 1
    }
    
    # Verify parameters
    local ipv4_forward=$(sysctl -n net.ipv4.ip_forward)
    if [[ "$ipv4_forward" == "1" ]]; then
        log_info "Sysctl parameters configured successfully"
        return 0
    else
        log_error "Failed to verify sysctl parameters"
        return 1
    fi
}

################################################################################
# Function: add_kubernetes_repository
# Description: Add Kubernetes APT repository
################################################################################
add_kubernetes_repository() {
    log_info "Adding Kubernetes APT repository..."
    
    # Install prerequisites
    apt-get update -qq
    apt-get install -y -qq apt-transport-https ca-certificates curl gpg
    
    # Create keyrings directory
    mkdir -p /etc/apt/keyrings
    
    # Download Kubernetes GPG key
    log_info "Downloading Kubernetes GPG key for version $K8S_VERSION..."
    curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key" | \
        gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    
    if [[ ! -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]]; then
        log_error "Failed to download Kubernetes GPG key"
        return 1
    fi
    
    # Add Kubernetes repository
    log_info "Adding Kubernetes repository..."
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | \
        tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
    
    # Update package index
    apt-get update -qq
    
    log_info "Kubernetes repository added successfully"
    return 0
}

################################################################################
# Function: install_kubernetes_packages
# Description: Install Kubernetes packages (kubeadm, kubelet, kubectl)
################################################################################
install_kubernetes_packages() {
    log_info "Installing Kubernetes packages..."
    
    # Install packages
    apt-get install -y -qq kubelet kubeadm kubectl || {
        log_error "Failed to install Kubernetes packages"
        return 1
    }
    
    # Hold packages at current version
    apt-mark hold kubelet kubeadm kubectl
    log_info "Kubernetes packages marked to hold version"
    
    # Enable and start kubelet
    systemctl enable kubelet
    systemctl start kubelet || log_warning "Kubelet failed to start (expected before cluster init)"
    
    # Verify installation
    local kubeadm_version=$(kubeadm version -o short)
    local kubelet_version=$(kubelet --version | awk '{print $2}')
    local kubectl_version=$(kubectl version --client -o json | grep -o '"gitVersion":"[^"]*"' | cut -d'"' -f4)
    
    log_info "Installed versions:"
    log_info "  - kubeadm: $kubeadm_version"
    log_info "  - kubelet: $kubelet_version"
    log_info "  - kubectl: $kubectl_version"
    
    return 0
}

################################################################################
# Function: configure_kubelet
# Description: Configure kubelet service
################################################################################
configure_kubelet() {
    log_info "Configuring kubelet..."
    
    # Create kubelet configuration directory
    mkdir -p /var/lib/kubelet
    
    # Create kubelet configuration
    cat > /var/lib/kubelet/config.yaml <<EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    log_info "Kubelet configuration completed"
    return 0
}

################################################################################
# Function: verify_installation
# Description: Verify Kubernetes installation
################################################################################
verify_installation() {
    log_info "Verifying Kubernetes installation..."
    
    # Check if commands are available
    local commands=("kubeadm" "kubelet" "kubectl")
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Command not found: $cmd"
            return 1
        fi
    done
    
    # Check kubelet service
    if systemctl is-enabled kubelet &> /dev/null; then
        log_info "Kubelet service is enabled"
    else
        log_error "Kubelet service is not enabled"
        return 1
    fi
    
    # Check kernel modules
    if ! lsmod | grep -q br_netfilter; then
        log_error "br_netfilter module not loaded"
        return 1
    fi
    
    # Check sysctl parameters
    if [[ "$(sysctl -n net.ipv4.ip_forward)" != "1" ]]; then
        log_error "IP forwarding not enabled"
        return 1
    fi
    
    log_info "Kubernetes installation verified successfully"
    return 0
}

################################################################################
# Function: print_summary
# Description: Print installation summary
################################################################################
print_summary() {
    echo ""
    echo "=========================================="
    echo "Kubernetes Installation Summary"
    echo "=========================================="
    echo "Status: SUCCESS"
    echo "Version: $(kubeadm version -o short)"
    echo "Components:"
    echo "  - kubeadm: Installed"
    echo "  - kubelet: Installed and enabled"
    echo "  - kubectl: Installed"
    echo ""
    echo "Next Steps:"
    echo "  - Initialize master: sudo ./init-master.sh"
    echo "  - Join worker: sudo ./join-worker.sh"
    echo "  - Install CNI: sudo ./install-calico.sh"
    echo "=========================================="
}

################################################################################
# Main execution
################################################################################
main() {
    log_info "=========================================="
    log_info "Starting Kubernetes $K8S_VERSION installation"
    log_info "=========================================="
    
    # Check if already installed (idempotency)
    if check_if_installed; then
        log_info "Kubernetes is already installed, skipping installation"
        print_summary
        exit 0
    fi
    
    # Execute installation steps
    check_prerequisites || exit 1
    disable_swap || exit 1
    load_kernel_modules || exit 1
    configure_sysctl || exit 1
    add_kubernetes_repository || exit 1
    install_kubernetes_packages || exit 1
    configure_kubelet || exit 1
    verify_installation || exit 1
    
    log_info "=========================================="
    log_info "Kubernetes installation completed successfully"
    log_info "=========================================="
    
    print_summary
    exit 0
}

# Execute main function
main "$@"
