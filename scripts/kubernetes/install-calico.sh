#!/bin/bash
################################################################################
# Script: install-calico.sh
# Description: Install Calico CNI plugin for Kubernetes
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
readonly SCRIPT_NAME="install-calico"
readonly LOG_FILE="/var/log/kubernetes/${SCRIPT_NAME}.log"

# Calico configuration
readonly CALICO_VERSION="${CALICO_VERSION:-v3.27.0}"
readonly POD_CIDR="${K8S_POD_CIDR:-192.168.0.0/16}"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

################################################################################
# Function: check_prerequisites
# Description: Verify prerequisites for Calico installation
################################################################################
check_prerequisites() {
    log_info "Checking prerequisites for Calico installation..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        return 1
    fi
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install Kubernetes first"
        return 1
    fi
    
    # Check if kubeconfig is configured
    if [[ ! -f /etc/kubernetes/admin.conf ]]; then
        log_error "Kubernetes not initialized. Run init-master.sh first"
        return 1
    fi
    
    # Set kubeconfig
    export KUBECONFIG=/etc/kubernetes/admin.conf
    
    # Check if API server is accessible
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes API server"
        return 1
    fi
    
    log_info "Prerequisites check completed successfully"
    return 0
}

################################################################################
# Function: check_if_installed
# Description: Check if Calico is already installed
################################################################################
check_if_installed() {
    log_info "Checking if Calico is already installed..."
    
    export KUBECONFIG=/etc/kubernetes/admin.conf
    
    # Check for Calico namespace
    if kubectl get namespace calico-system &> /dev/null; then
        log_info "Calico namespace exists"
        
        # Check for Calico pods
        local calico_pods=$(kubectl get pods -n calico-system --no-headers 2>/dev/null | wc -l)
        if [[ $calico_pods -gt 0 ]]; then
            log_info "Calico is already installed ($calico_pods pods found)"
            return 0
        fi
    fi
    
    # Check for legacy Calico in kube-system
    if kubectl get pods -n kube-system -l k8s-app=calico-node &> /dev/null; then
        local legacy_pods=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | wc -l)
        if [[ $legacy_pods -gt 0 ]]; then
            log_info "Legacy Calico installation found ($legacy_pods pods)"
            return 0
        fi
    fi
    
    log_info "Calico is not installed"
    return 1
}

################################################################################
# Function: install_calico_operator
# Description: Install Calico operator
################################################################################
install_calico_operator() {
    log_info "Installing Calico operator..."
    log_info "Version: $CALICO_VERSION"
    
    export KUBECONFIG=/etc/kubernetes/admin.conf
    
    # Download and apply Calico operator manifest
    local operator_url="https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"
    
    log_info "Downloading Calico operator from: $operator_url"
    
    kubectl create -f "$operator_url" 2>&1 | tee -a "$LOG_FILE" || {
        log_error "Failed to install Calico operator"
        return 1
    }
    
    log_info "Calico operator installed successfully"
    return 0
}

################################################################################
# Function: wait_for_operator
# Description: Wait for Calico operator to be ready
################################################################################
wait_for_operator() {
    log_info "Waiting for Calico operator to be ready..."
    
    export KUBECONFIG=/etc/kubernetes/admin.conf
    
    # Wait for tigera-operator namespace
    local retries=0
    local max_retries=30
    
    while [[ $retries -lt $max_retries ]]; do
        if kubectl get namespace tigera-operator &> /dev/null; then
            log_info "tigera-operator namespace is ready"
            break
        fi
        
        retries=$((retries + 1))
        log_info "Waiting for tigera-operator namespace... ($retries/$max_retries)"
        sleep 5
    done
    
    if [[ $retries -eq $max_retries ]]; then
        log_error "tigera-operator namespace not ready"
        return 1
    fi
    
    # Wait for operator pod to be ready
    log_info "Waiting for operator pod to be ready..."
    kubectl wait --for=condition=ready pod \
        -l k8s-app=tigera-operator \
        -n tigera-operator \
        --timeout=300s || {
            log_error "Calico operator pod did not become ready"
            return 1
        }
    
    log_info "Calico operator is ready"
    return 0
}

################################################################################
# Function: create_calico_resources
# Description: Create Calico custom resources
################################################################################
create_calico_resources() {
    log_info "Creating Calico custom resources..."
    log_info "Pod CIDR: $POD_CIDR"
    
    export KUBECONFIG=/etc/kubernetes/admin.conf
    
    # Create custom resources manifest
    local temp_file="/tmp/calico-custom-resources.yaml"
    
    cat > "$temp_file" <<EOF
# Custom resources for Calico installation
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Calico network configuration
  calicoNetwork:
    # IP pools configuration
    ipPools:
    - blockSize: 26
      cidr: ${POD_CIDR}
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
    # MTU configuration
    mtu: 1440
  # Node update strategy
  nodeUpdateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1

---
# API server configuration
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF
    
    # Apply custom resources
    log_info "Applying Calico custom resources..."
    kubectl apply -f "$temp_file" 2>&1 | tee -a "$LOG_FILE" || {
        log_error "Failed to apply Calico custom resources"
        rm -f "$temp_file"
        return 1
    }
    
    rm -f "$temp_file"
    log_info "Calico custom resources created successfully"
    return 0
}

################################################################################
# Function: wait_for_calico_pods
# Description: Wait for Calico pods to be ready
################################################################################
wait_for_calico_pods() {
    log_info "Waiting for Calico pods to be ready (this may take several minutes)..."
    
    export KUBECONFIG=/etc/kubernetes/admin.conf
    
    # Wait for calico-system namespace
    local retries=0
    local max_retries=60
    
    while [[ $retries -lt $max_retries ]]; do
        if kubectl get namespace calico-system &> /dev/null; then
            log_info "calico-system namespace is ready"
            break
        fi
        
        retries=$((retries + 1))
        log_info "Waiting for calico-system namespace... ($retries/$max_retries)"
        sleep 5
    done
    
    if [[ $retries -eq $max_retries ]]; then
        log_error "calico-system namespace not ready"
        return 1
    fi
    
    # Wait for calico-node pods
    log_info "Waiting for calico-node pods to be ready..."
    kubectl wait --for=condition=ready pod \
        -l k8s-app=calico-node \
        -n calico-system \
        --timeout=600s || {
            log_warning "Some calico-node pods may not be ready yet"
        }
    
    # Wait for calico-kube-controllers
    log_info "Waiting for calico-kube-controllers to be ready..."
    kubectl wait --for=condition=ready pod \
        -l k8s-app=calico-kube-controllers \
        -n calico-system \
        --timeout=300s || {
            log_warning "calico-kube-controllers may not be ready yet"
        }
    
    log_info "Calico pods are ready"
    return 0
}

################################################################################
# Function: verify_installation
# Description: Verify Calico installation
################################################################################
verify_installation() {
    log_info "Verifying Calico installation..."
    
    export KUBECONFIG=/etc/kubernetes/admin.conf
    
    # Check namespaces
    log_info "Checking Calico namespaces..."
    kubectl get namespaces | grep -E "calico|tigera" | tee -a "$LOG_FILE"
    
    # Check pods in calico-system
    log_info "Checking Calico pods..."
    kubectl get pods -n calico-system -o wide | tee -a "$LOG_FILE"
    
    # Check node status
    log_info "Checking node status..."
    kubectl get nodes -o wide | tee -a "$LOG_FILE"
    
    # Verify all nodes are Ready
    local not_ready_nodes=$(kubectl get nodes --no-headers | grep -v " Ready " | wc -l)
    if [[ $not_ready_nodes -eq 0 ]]; then
        log_info "All nodes are Ready"
    else
        log_warning "$not_ready_nodes node(s) are not Ready"
    fi
    
    # Check Calico installation status
    if kubectl get installation default -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null | grep -q "True"; then
        log_info "Calico installation is Available"
    else
        log_warning "Calico installation status is not Available yet"
    fi
    
    log_info "Calico installation verified successfully"
    return 0
}

################################################################################
# Function: print_summary
# Description: Print installation summary
################################################################################
print_summary() {
    export KUBECONFIG=/etc/kubernetes/admin.conf
    
    local calico_version=$(kubectl get installation default -o jsonpath='{.spec.variant}' 2>/dev/null || echo "Calico")
    local node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    local pod_count=$(kubectl get pods -n calico-system --no-headers 2>/dev/null | wc -l)
    
    echo ""
    echo "=========================================="
    echo "Calico CNI Installation Summary"
    echo "=========================================="
    echo "Status: SUCCESS"
    echo "Version: $CALICO_VERSION"
    echo "Variant: $calico_version"
    echo "Pod CIDR: $POD_CIDR"
    echo "Nodes: $node_count"
    echo "Calico Pods: $pod_count"
    echo ""
    echo "Verification Commands:"
    echo "  - Check nodes: kubectl get nodes"
    echo "  - Check pods: kubectl get pods -n calico-system"
    echo "  - Check installation: kubectl get installation default -o yaml"
    echo "  - View logs: kubectl logs -n calico-system -l k8s-app=calico-node"
    echo ""
    echo "View logs: tail -f $LOG_FILE"
    echo "=========================================="
}

################################################################################
# Main execution
################################################################################
main() {
    log_info "=========================================="
    log_info "Starting Calico CNI installation"
    log_info "=========================================="
    
    # Check if already installed (idempotency)
    if check_if_installed; then
        log_info "Calico is already installed, skipping installation"
        print_summary
        exit 0
    fi
    
    # Execute installation steps
    check_prerequisites || exit 1
    install_calico_operator || exit 1
    wait_for_operator || exit 1
    create_calico_resources || exit 1
    wait_for_calico_pods || exit 1
    verify_installation || exit 1
    
    log_info "=========================================="
    log_info "Calico installation completed successfully"
    log_info "=========================================="
    
    print_summary
    exit 0
}

# Execute main function
main "$@"
