#!/bin/bash
################################################################################
# Script: join-worker.sh
# Description: Join Kubernetes worker node to cluster
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
readonly SCRIPT_NAME="join-worker"
readonly LOG_FILE="/var/log/kubernetes/${SCRIPT_NAME}.log"

# File share configuration (for reading join token)
readonly FILE_SHARE_MOUNT="${FILE_SHARE_MOUNT:-/mnt/dats-beeux-dev-shaf-afs}"
readonly JOIN_TOKEN_DIR="${FILE_SHARE_MOUNT}/k8s-join-token"
readonly JOIN_COMMAND_FILE="${JOIN_TOKEN_DIR}/join-command.sh"

# Timeouts
readonly MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-600}"  # 10 minutes

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

################################################################################
# Function: check_prerequisites
# Description: Verify prerequisites for joining cluster
################################################################################
check_prerequisites() {
    log_info "Checking prerequisites for joining cluster..."
    
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
    
    # Check if file share is mounted
    if [[ ! -d "$FILE_SHARE_MOUNT" ]]; then
        log_error "File share not mounted at $FILE_SHARE_MOUNT"
        log_error "Please mount the file share first"
        return 1
    fi
    
    log_info "Prerequisites check completed successfully"
    return 0
}

################################################################################
# Function: check_if_joined
# Description: Check if node is already part of a cluster
################################################################################
check_if_joined() {
    log_info "Checking if node is already part of a cluster..."
    
    # Check if kubelet is running and configured
    if systemctl is-active --quiet kubelet; then
        # Check if kubelet has joined a cluster
        if [[ -f /etc/kubernetes/kubelet.conf ]]; then
            log_info "Node appears to be already joined to a cluster"
            
            # Try to verify cluster connectivity
            if kubectl --kubeconfig=/etc/kubernetes/kubelet.conf get nodes &> /dev/null; then
                log_info "Node is connected to cluster"
                return 0
            else
                log_warning "kubelet.conf exists but cluster connection failed"
                return 1
            fi
        fi
    fi
    
    log_info "Node is not part of any cluster"
    return 1
}

################################################################################
# Function: wait_for_join_command
# Description: Wait for join command to be available from master
################################################################################
wait_for_join_command() {
    log_info "Waiting for join command from master node..."
    log_info "Join command file: $JOIN_COMMAND_FILE"
    log_info "Max wait time: ${MAX_WAIT_SECONDS}s"
    
    local elapsed=0
    local check_interval=10
    
    while [[ $elapsed -lt $MAX_WAIT_SECONDS ]]; do
        if [[ -f "$JOIN_COMMAND_FILE" ]]; then
            log_info "Join command file found after ${elapsed}s"
            
            # Verify file is not empty
            if [[ -s "$JOIN_COMMAND_FILE" ]]; then
                log_info "Join command file is valid"
                return 0
            else
                log_warning "Join command file is empty, waiting..."
            fi
        fi
        
        log_info "Waiting for join command... (${elapsed}/${MAX_WAIT_SECONDS}s)"
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
    done
    
    log_error "Join command not found after ${MAX_WAIT_SECONDS}s"
    log_error "Please ensure:"
    log_error "  1. Master node initialization is complete"
    log_error "  2. File share is properly mounted"
    log_error "  3. Join command was generated on master"
    return 1
}

################################################################################
# Function: validate_join_command
# Description: Validate join command format
################################################################################
validate_join_command() {
    local join_command="$1"
    
    log_info "Validating join command..."
    
    # Check if command starts with 'kubeadm join'
    if [[ ! "$join_command" =~ ^kubeadm\ join ]]; then
        log_error "Invalid join command format (must start with 'kubeadm join')"
        return 1
    fi
    
    # Check if command contains token
    if [[ ! "$join_command" =~ --token ]]; then
        log_error "Join command missing token parameter"
        return 1
    fi
    
    # Check if command contains discovery token CA cert hash
    if [[ ! "$join_command" =~ --discovery-token-ca-cert-hash ]]; then
        log_error "Join command missing discovery-token-ca-cert-hash parameter"
        return 1
    fi
    
    log_info "Join command validation passed"
    return 0
}

################################################################################
# Function: join_cluster
# Description: Execute kubeadm join command
################################################################################
join_cluster() {
    log_info "Reading join command from file share..."
    
    # Read join command
    local join_command
    join_command=$(cat "$JOIN_COMMAND_FILE")
    
    if [[ -z "$join_command" ]]; then
        log_error "Join command file is empty"
        return 1
    fi
    
    # Validate join command
    validate_join_command "$join_command" || return 1
    
    # Log join command (sanitized)
    log_info "Join command: ${join_command%% --token*}"
    
    # Execute join command
    log_info "Joining cluster (this may take several minutes)..."
    
    eval "$join_command --ignore-preflight-errors=NumCPU,Mem --v=5" 2>&1 | tee -a "$LOG_FILE" || {
        log_error "Failed to join cluster"
        return 1
    }
    
    log_info "Successfully joined cluster"
    return 0
}

################################################################################
# Function: verify_join
# Description: Verify node successfully joined cluster
################################################################################
verify_join() {
    log_info "Verifying cluster join..."
    
    # Wait for kubelet to be active
    log_info "Waiting for kubelet to be active..."
    local retries=0
    local max_retries=30
    
    while [[ $retries -lt $max_retries ]]; do
        if systemctl is-active --quiet kubelet; then
            log_info "Kubelet is active"
            break
        fi
        
        retries=$((retries + 1))
        log_info "Waiting for kubelet... ($retries/$max_retries)"
        sleep 10
    done
    
    if [[ $retries -eq $max_retries ]]; then
        log_error "Kubelet did not become active"
        return 1
    fi
    
    # Check if kubelet.conf exists
    if [[ -f /etc/kubernetes/kubelet.conf ]]; then
        log_info "kubelet.conf created successfully"
    else
        log_error "kubelet.conf not found"
        return 1
    fi
    
    # Check if kubelet can connect to API server
    log_info "Testing connection to API server..."
    if kubectl --kubeconfig=/etc/kubernetes/kubelet.conf get nodes &> /dev/null; then
        log_info "Successfully connected to API server"
    else
        log_warning "Unable to connect to API server (this may be normal initially)"
    fi
    
    log_info "Cluster join verified successfully"
    return 0
}

################################################################################
# Function: print_summary
# Description: Print join summary
################################################################################
print_summary() {
    local hostname=$(hostname)
    
    echo ""
    echo "=========================================="
    echo "Kubernetes Worker Join Summary"
    echo "=========================================="
    echo "Status: SUCCESS"
    echo "Node: $hostname"
    echo ""
    echo "Configuration Files:"
    echo "  - kubelet.conf: /etc/kubernetes/kubelet.conf"
    echo "  - ca.crt: /etc/kubernetes/pki/ca.crt"
    echo ""
    echo "Next Steps:"
    echo "  1. Check node status on master:"
    echo "     kubectl get nodes"
    echo "  2. Check pod status on master:"
    echo "     kubectl get pods -A"
    echo "  3. View kubelet logs:"
    echo "     journalctl -u kubelet -f"
    echo ""
    echo "View logs: tail -f $LOG_FILE"
    echo "=========================================="
}

################################################################################
# Main execution
################################################################################
main() {
    log_info "=========================================="
    log_info "Starting Kubernetes worker join process"
    log_info "=========================================="
    
    # Check if already joined (idempotency)
    if check_if_joined; then
        log_info "Node is already joined to a cluster, skipping join"
        print_summary
        exit 0
    fi
    
    # Execute join steps
    check_prerequisites || exit 1
    wait_for_join_command || exit 1
    join_cluster || exit 1
    verify_join || exit 1
    
    log_info "=========================================="
    log_info "Worker join completed successfully"
    log_info "=========================================="
    
    print_summary
    exit 0
}

# Execute main function
main "$@"
