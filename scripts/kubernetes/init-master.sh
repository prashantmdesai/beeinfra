#!/bin/bash
################################################################################
# Script: init-master.sh
# Description: Initialize Kubernetes master node
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
readonly SCRIPT_NAME="init-master"
readonly LOG_FILE="/var/log/kubernetes/${SCRIPT_NAME}.log"

# Kubernetes configuration (can be overridden by environment variables)
readonly POD_CIDR="${K8S_POD_CIDR:-192.168.0.0/16}"
readonly SERVICE_CIDR="${K8S_SERVICE_CIDR:-10.96.0.0/12}"
readonly API_SERVER_ADVERTISE_ADDRESS="${K8S_API_SERVER_ADDRESS:-$(hostname -I | awk '{print $1}')}"
readonly K8S_VERSION="${K8S_VERSION:-1.30}"

# File share configuration (for saving join token)
readonly FILE_SHARE_MOUNT="${FILE_SHARE_MOUNT:-/mnt/dats-beeux-dev-shaf-afs}"
readonly JOIN_TOKEN_DIR="${FILE_SHARE_MOUNT}/k8s-join-token"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

################################################################################
# Function: check_prerequisites
# Description: Verify prerequisites for master initialization
################################################################################
check_prerequisites() {
    log_info "Checking prerequisites for master initialization..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        return 1
    fi
    
    # Check if Kubernetes is installed
    if ! command -v kubeadm &> /dev/null; then
        log_error "kubeadm not found. Please install Kubernetes first"
        return 1
    fi
    
    # Check if Docker/containerd is running
    if ! systemctl is-active --quiet containerd; then
        log_error "containerd is not running"
        return 1
    fi
    
    # Check if kubelet is enabled
    if ! systemctl is-enabled --quiet kubelet; then
        log_error "kubelet is not enabled"
        return 1
    fi
    
    # Check if file share is mounted (optional)
    if [[ -d "$FILE_SHARE_MOUNT" ]]; then
        log_info "File share is mounted at $FILE_SHARE_MOUNT"
    else
        log_warning "File share not found at $FILE_SHARE_MOUNT (join token will not be saved)"
    fi
    
    log_info "Prerequisites check completed successfully"
    return 0
}

################################################################################
# Function: check_if_initialized
# Description: Check if cluster is already initialized
################################################################################
check_if_initialized() {
    log_info "Checking if cluster is already initialized..."
    
    # Check if kubeconfig exists
    if [[ -f /etc/kubernetes/admin.conf ]]; then
        log_info "Cluster appears to be already initialized"
        
        # Try to connect to API server
        if kubectl --kubeconfig=/etc/kubernetes/admin.conf cluster-info &> /dev/null; then
            log_info "Cluster is running and accessible"
            return 0
        else
            log_warning "kubeconfig exists but cluster is not accessible"
            return 1
        fi
    fi
    
    log_info "Cluster is not initialized"
    return 1
}

################################################################################
# Function: initialize_cluster
# Description: Initialize Kubernetes cluster with kubeadm
################################################################################
initialize_cluster() {
    log_info "Initializing Kubernetes cluster..."
    log_info "Configuration:"
    log_info "  - Pod CIDR: $POD_CIDR"
    log_info "  - Service CIDR: $SERVICE_CIDR"
    log_info "  - API Server Address: $API_SERVER_ADVERTISE_ADDRESS"
    
    # Run kubeadm init
    log_info "Running kubeadm init (this may take several minutes)..."
    
    kubeadm init \
        --pod-network-cidr="$POD_CIDR" \
        --service-cidr="$SERVICE_CIDR" \
        --apiserver-advertise-address="$API_SERVER_ADVERTISE_ADDRESS" \
        --ignore-preflight-errors=NumCPU,Mem \
        --v=5 2>&1 | tee -a "$LOG_FILE" || {
            log_error "kubeadm init failed"
            return 1
        }
    
    log_info "Cluster initialized successfully"
    return 0
}

################################################################################
# Function: configure_kubectl_root
# Description: Configure kubectl for root user
################################################################################
configure_kubectl_root() {
    log_info "Configuring kubectl for root user..."
    
    # Set KUBECONFIG environment variable
    export KUBECONFIG=/etc/kubernetes/admin.conf
    
    # Add to root's bashrc
    if ! grep -q "KUBECONFIG=/etc/kubernetes/admin.conf" /root/.bashrc; then
        echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc
        log_info "Added KUBECONFIG to /root/.bashrc"
    fi
    
    # Test kubectl
    if kubectl cluster-info &> /dev/null; then
        log_info "kubectl configured successfully for root"
        return 0
    else
        log_error "kubectl configuration failed"
        return 1
    fi
}

################################################################################
# Function: configure_kubectl_user
# Description: Configure kubectl for regular user (beeuser)
################################################################################
configure_kubectl_user() {
    local username="${SUDO_USER:-beeuser}"
    log_info "Configuring kubectl for user: $username..."
    
    # Get user home directory
    local user_home=$(getent passwd "$username" | cut -d: -f6)
    
    if [[ -z "$user_home" ]]; then
        log_warning "User $username not found, skipping user kubectl configuration"
        return 0
    fi
    
    # Create .kube directory
    mkdir -p "$user_home/.kube"
    
    # Copy admin.conf
    cp /etc/kubernetes/admin.conf "$user_home/.kube/config"
    
    # Set ownership
    chown -R "$username:$username" "$user_home/.kube"
    
    # Set permissions
    chmod 600 "$user_home/.kube/config"
    
    # Add to user's bashrc
    if ! grep -q "KUBECONFIG=" "$user_home/.bashrc" 2>/dev/null; then
        echo "export KUBECONFIG=$user_home/.kube/config" >> "$user_home/.bashrc"
        chown "$username:$username" "$user_home/.bashrc"
        log_info "Added KUBECONFIG to $user_home/.bashrc"
    fi
    
    log_info "kubectl configured successfully for user: $username"
    return 0
}

################################################################################
# Function: generate_join_command
# Description: Generate join command for worker nodes
################################################################################
generate_join_command() {
    log_info "Generating join command for worker nodes..."
    
    # Generate join command
    local join_command=$(kubeadm token create --print-join-command 2>/dev/null)
    
    if [[ -z "$join_command" ]]; then
        log_error "Failed to generate join command"
        return 1
    fi
    
    log_info "Join command generated successfully"
    
    # Save to file share if available
    if [[ -d "$FILE_SHARE_MOUNT" ]]; then
        mkdir -p "$JOIN_TOKEN_DIR"
        
        # Save join command
        echo "$join_command" > "$JOIN_TOKEN_DIR/join-command.sh"
        chmod 644 "$JOIN_TOKEN_DIR/join-command.sh"
        
        # Save cluster info
        kubectl cluster-info > "$JOIN_TOKEN_DIR/cluster-info.txt" 2>&1
        
        log_info "Join command saved to: $JOIN_TOKEN_DIR/join-command.sh"
        log_info "Cluster info saved to: $JOIN_TOKEN_DIR/cluster-info.txt"
    else
        log_warning "File share not available, join command not saved"
        log_info "Join command: $join_command"
    fi
    
    return 0
}

################################################################################
# Function: untaint_master
# Description: Remove master node taint to allow scheduling (optional)
################################################################################
untaint_master() {
    log_info "Checking master node taints..."
    
    local node_name=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
    local taints=$(kubectl get node "$node_name" -o jsonpath='{.spec.taints[*].key}')
    
    if [[ "$taints" == *"node-role.kubernetes.io/control-plane"* ]]; then
        log_info "Master node has control-plane taint"
        log_info "To allow pod scheduling on master, run:"
        log_info "  kubectl taint nodes $node_name node-role.kubernetes.io/control-plane-"
    else
        log_info "Master node does not have control-plane taint"
    fi
    
    return 0
}

################################################################################
# Function: verify_initialization
# Description: Verify cluster initialization
################################################################################
verify_initialization() {
    log_info "Verifying cluster initialization..."
    
    # Wait for API server to be ready
    log_info "Waiting for API server to be ready..."
    local retries=0
    local max_retries=30
    
    while [[ $retries -lt $max_retries ]]; do
        if kubectl cluster-info &> /dev/null; then
            log_info "API server is ready"
            break
        fi
        
        retries=$((retries + 1))
        log_info "Waiting for API server... ($retries/$max_retries)"
        sleep 10
    done
    
    if [[ $retries -eq $max_retries ]]; then
        log_error "API server did not become ready"
        return 1
    fi
    
    # Check node status
    local node_status=$(kubectl get nodes -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}')
    if [[ "$node_status" == "True" ]]; then
        log_info "Master node is Ready"
    else
        log_warning "Master node is not Ready yet (this is normal before CNI installation)"
    fi
    
    # Check system pods
    log_info "Checking system pods..."
    kubectl get pods -n kube-system -o wide | tee -a "$LOG_FILE"
    
    log_info "Cluster initialization verified successfully"
    return 0
}

################################################################################
# Function: print_summary
# Description: Print initialization summary
################################################################################
print_summary() {
    local node_name=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
    local node_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    
    echo ""
    echo "=========================================="
    echo "Kubernetes Master Initialization Summary"
    echo "=========================================="
    echo "Status: SUCCESS"
    echo "Node Name: $node_name"
    echo "Node IP: $node_ip"
    echo "API Server: https://${node_ip}:6443"
    echo "Pod CIDR: $POD_CIDR"
    echo "Service CIDR: $SERVICE_CIDR"
    echo ""
    echo "Configuration Files:"
    echo "  - Admin kubeconfig: /etc/kubernetes/admin.conf"
    echo "  - User kubeconfig: ~/.kube/config"
    if [[ -f "$JOIN_TOKEN_DIR/join-command.sh" ]]; then
        echo "  - Join command: $JOIN_TOKEN_DIR/join-command.sh"
    fi
    echo ""
    echo "Next Steps:"
    echo "  1. Install CNI plugin: sudo ./install-calico.sh"
    echo "  2. Join worker nodes: sudo ./join-worker.sh (on worker nodes)"
    echo "  3. Verify cluster: kubectl get nodes"
    echo ""
    echo "View logs: tail -f $LOG_FILE"
    echo "=========================================="
}

################################################################################
# Main execution
################################################################################
main() {
    log_info "=========================================="
    log_info "Starting Kubernetes master initialization"
    log_info "=========================================="
    
    # Check if already initialized (idempotency)
    if check_if_initialized; then
        log_info "Cluster is already initialized, skipping initialization"
        print_summary
        exit 0
    fi
    
    # Execute initialization steps
    check_prerequisites || exit 1
    initialize_cluster || exit 1
    configure_kubectl_root || exit 1
    configure_kubectl_user || exit 1
    generate_join_command || exit 1
    untaint_master || exit 1
    verify_initialization || exit 1
    
    log_info "=========================================="
    log_info "Master initialization completed successfully"
    log_info "=========================================="
    
    print_summary
    exit 0
}

# Execute main function
main "$@"
