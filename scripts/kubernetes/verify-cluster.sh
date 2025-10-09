#!/bin/bash
################################################################################
# Script: verify-cluster.sh
# Description: Verify Kubernetes cluster health and status
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
readonly SCRIPT_NAME="verify-cluster"
readonly LOG_FILE="/var/log/kubernetes/${SCRIPT_NAME}.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

################################################################################
# Function: check_prerequisites
# Description: Verify prerequisites for cluster verification
################################################################################
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found"
        return 1
    fi
    
    # Check if kubeconfig exists
    if [[ -f /etc/kubernetes/admin.conf ]]; then
        export KUBECONFIG=/etc/kubernetes/admin.conf
    elif [[ -f ~/.kube/config ]]; then
        export KUBECONFIG=~/.kube/config
    elif [[ -f /etc/kubernetes/kubelet.conf ]]; then
        export KUBECONFIG=/etc/kubernetes/kubelet.conf
    else
        log_error "No kubeconfig found"
        return 1
    fi
    
    # Check API server connectivity
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes API server"
        return 1
    fi
    
    log_info "Prerequisites check passed"
    return 0
}

################################################################################
# Function: print_header
# Description: Print section header
################################################################################
print_header() {
    local title="$1"
    echo ""
    echo -e "${BLUE}=========================================="
    echo -e "$title"
    echo -e "==========================================${NC}"
}

################################################################################
# Function: print_status
# Description: Print status with color
################################################################################
print_status() {
    local status="$1"
    local message="$2"
    
    case "$status" in
        "OK"|"PASS"|"SUCCESS")
            echo -e "${GREEN}✓ $message${NC}"
            ;;
        "WARNING"|"WARN")
            echo -e "${YELLOW}⚠ $message${NC}"
            ;;
        "ERROR"|"FAIL"|"FAILED")
            echo -e "${RED}✗ $message${NC}"
            ;;
        *)
            echo "  $message"
            ;;
    esac
}

################################################################################
# Function: verify_cluster_info
# Description: Verify cluster information
################################################################################
verify_cluster_info() {
    print_header "Cluster Information"
    
    log_info "Gathering cluster information..."
    
    # Get cluster info
    echo ""
    kubectl cluster-info 2>&1 | tee -a "$LOG_FILE"
    
    # Get cluster version
    echo ""
    local version=$(kubectl version --short 2>/dev/null || kubectl version 2>/dev/null)
    echo "$version" | tee -a "$LOG_FILE"
    
    return 0
}

################################################################################
# Function: verify_nodes
# Description: Verify node status
################################################################################
verify_nodes() {
    print_header "Node Status"
    
    log_info "Checking node status..."
    
    # Get all nodes
    echo ""
    kubectl get nodes -o wide 2>&1 | tee -a "$LOG_FILE"
    
    echo ""
    
    # Check each node status
    local total_nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    local ready_nodes=$(kubectl get nodes --no-headers 2>/dev/null | grep " Ready " | wc -l)
    local not_ready_nodes=$((total_nodes - ready_nodes))
    
    print_status "INFO" "Total nodes: $total_nodes"
    
    if [[ $ready_nodes -eq $total_nodes ]]; then
        print_status "OK" "All nodes are Ready ($ready_nodes/$total_nodes)"
    else
        print_status "WARNING" "Not all nodes are Ready ($ready_nodes/$total_nodes ready, $not_ready_nodes not ready)"
    fi
    
    # Check for master/control-plane nodes
    local master_nodes=$(kubectl get nodes --no-headers 2>/dev/null | grep -E "control-plane|master" | wc -l)
    print_status "INFO" "Control plane nodes: $master_nodes"
    
    # Check for worker nodes
    local worker_nodes=$((total_nodes - master_nodes))
    print_status "INFO" "Worker nodes: $worker_nodes"
    
    return 0
}

################################################################################
# Function: verify_system_pods
# Description: Verify system pod status
################################################################################
verify_system_pods() {
    print_header "System Pods Status"
    
    log_info "Checking system pods..."
    
    # Check kube-system pods
    echo ""
    echo "kube-system namespace:"
    kubectl get pods -n kube-system -o wide 2>&1 | tee -a "$LOG_FILE"
    
    # Check calico-system pods
    if kubectl get namespace calico-system &> /dev/null; then
        echo ""
        echo "calico-system namespace:"
        kubectl get pods -n calico-system -o wide 2>&1 | tee -a "$LOG_FILE"
    fi
    
    echo ""
    
    # Count pod statuses
    local total_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | wc -l)
    local running_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep " Running " | wc -l)
    local pending_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep " Pending " | wc -l)
    local failed_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -E " Error | CrashLoopBackOff | Failed " | wc -l)
    
    print_status "INFO" "kube-system pods: $total_pods total"
    
    if [[ $running_pods -eq $total_pods ]]; then
        print_status "OK" "All system pods are Running ($running_pods/$total_pods)"
    else
        print_status "WARNING" "Not all system pods are Running ($running_pods/$total_pods)"
    fi
    
    if [[ $pending_pods -gt 0 ]]; then
        print_status "WARNING" "Pending pods: $pending_pods"
    fi
    
    if [[ $failed_pods -gt 0 ]]; then
        print_status "ERROR" "Failed/Error pods: $failed_pods"
    fi
    
    return 0
}

################################################################################
# Function: verify_networking
# Description: Verify cluster networking
################################################################################
verify_networking() {
    print_header "Networking Status"
    
    log_info "Checking cluster networking..."
    
    # Check CNI installation
    echo ""
    if kubectl get installation default &> /dev/null; then
        local cni_status=$(kubectl get installation default -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)
        if [[ "$cni_status" == "True" ]]; then
            print_status "OK" "Calico CNI is Available"
        else
            print_status "WARNING" "Calico CNI status: $cni_status"
        fi
    else
        print_status "WARNING" "CNI installation status unknown"
    fi
    
    # Check services
    echo ""
    echo "Cluster services:"
    kubectl get services -A -o wide 2>&1 | tee -a "$LOG_FILE"
    
    return 0
}

################################################################################
# Function: verify_component_health
# Description: Verify component health
################################################################################
verify_component_health() {
    print_header "Component Health"
    
    log_info "Checking component health..."
    
    echo ""
    kubectl get componentstatuses 2>&1 | tee -a "$LOG_FILE" || {
        print_status "WARNING" "componentstatuses deprecated in this version"
    }
    
    # Check control plane pods
    echo ""
    echo "Control plane pods:"
    kubectl get pods -n kube-system -l tier=control-plane -o wide 2>&1 | tee -a "$LOG_FILE"
    
    return 0
}

################################################################################
# Function: verify_resources
# Description: Verify cluster resources
################################################################################
verify_resources() {
    print_header "Cluster Resources"
    
    log_info "Checking cluster resources..."
    
    # Get resource usage
    echo ""
    echo "Node resource usage:"
    kubectl top nodes 2>&1 | tee -a "$LOG_FILE" || {
        print_status "WARNING" "Metrics server not installed or not ready"
    }
    
    echo ""
    echo "Pod resource usage (top 10):"
    kubectl top pods -A --sort-by=memory 2>&1 | head -n 11 | tee -a "$LOG_FILE" || {
        print_status "WARNING" "Metrics server not installed or not ready"
    }
    
    return 0
}

################################################################################
# Function: verify_storage
# Description: Verify storage configuration
################################################################################
verify_storage() {
    print_header "Storage Configuration"
    
    log_info "Checking storage configuration..."
    
    # Check storage classes
    echo ""
    echo "Storage classes:"
    kubectl get storageclass 2>&1 | tee -a "$LOG_FILE"
    
    # Check persistent volumes
    echo ""
    echo "Persistent volumes:"
    kubectl get pv 2>&1 | tee -a "$LOG_FILE"
    
    # Check persistent volume claims
    echo ""
    echo "Persistent volume claims:"
    kubectl get pvc -A 2>&1 | tee -a "$LOG_FILE"
    
    return 0
}

################################################################################
# Function: verify_dns
# Description: Verify cluster DNS
################################################################################
verify_dns() {
    print_header "DNS Verification"
    
    log_info "Checking cluster DNS..."
    
    # Check CoreDNS pods
    echo ""
    echo "CoreDNS pods:"
    kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide 2>&1 | tee -a "$LOG_FILE"
    
    local coredns_pods=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep " Running " | wc -l)
    
    echo ""
    if [[ $coredns_pods -gt 0 ]]; then
        print_status "OK" "CoreDNS is running ($coredns_pods pod(s))"
    else
        print_status "ERROR" "CoreDNS is not running"
    fi
    
    # Check DNS service
    echo ""
    echo "DNS service:"
    kubectl get service -n kube-system kube-dns 2>&1 | tee -a "$LOG_FILE"
    
    return 0
}

################################################################################
# Function: print_summary
# Description: Print verification summary
################################################################################
print_summary() {
    print_header "Verification Summary"
    
    local total_nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    local ready_nodes=$(kubectl get nodes --no-headers 2>/dev/null | grep " Ready " | wc -l)
    local total_pods=$(kubectl get pods -A --no-headers 2>/dev/null | wc -l)
    local running_pods=$(kubectl get pods -A --no-headers 2>/dev/null | grep " Running " | wc -l)
    
    echo ""
    echo "Cluster Status:"
    print_status "INFO" "Nodes: $ready_nodes/$total_nodes Ready"
    print_status "INFO" "Pods: $running_pods/$total_pods Running"
    
    echo ""
    
    if [[ $ready_nodes -eq $total_nodes ]] && [[ $running_pods -eq $total_pods ]]; then
        print_status "SUCCESS" "Cluster verification PASSED"
        echo ""
        echo "Cluster is healthy and ready to use!"
    else
        print_status "WARNING" "Cluster verification completed with warnings"
        echo ""
        echo "Please review the warnings above"
    fi
    
    echo ""
    echo "View detailed logs: tail -f $LOG_FILE"
    echo ""
}

################################################################################
# Main execution
################################################################################
main() {
    log_info "=========================================="
    log_info "Starting cluster verification"
    log_info "=========================================="
    
    # Execute verification steps
    check_prerequisites || exit 1
    
    verify_cluster_info
    verify_nodes
    verify_system_pods
    verify_networking
    verify_component_health
    verify_resources
    verify_storage
    verify_dns
    
    print_summary
    
    log_info "=========================================="
    log_info "Cluster verification completed"
    log_info "=========================================="
    
    exit 0
}

# Execute main function
main "$@"
