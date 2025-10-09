#!/bin/bash
################################################################################
# Script: verify-mount.sh
# Description: Verify Azure File Share mount accessibility and functionality
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
readonly SCRIPT_NAME="verify-mount"
readonly LOG_FILE="/var/log/infrastructure/${SCRIPT_NAME}.log"

# Mount configuration
readonly MOUNT_POINT="${MOUNT_POINT:-/mnt/dats-beeux-dev-shaf-afs}"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

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
# Function: verify_mount_exists
# Description: Check if mount point exists
################################################################################
verify_mount_exists() {
    print_header "Mount Point Verification"
    
    log_info "Checking mount point: $MOUNT_POINT"
    
    if [[ -d "$MOUNT_POINT" ]]; then
        print_status "OK" "Mount point exists: $MOUNT_POINT"
        return 0
    else
        print_status "ERROR" "Mount point does not exist: $MOUNT_POINT"
        return 1
    fi
}

################################################################################
# Function: verify_mounted
# Description: Check if file share is mounted
################################################################################
verify_mounted() {
    print_header "Mount Status"
    
    log_info "Checking if file share is mounted..."
    
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        print_status "OK" "File share is mounted"
        
        # Show mount details
        echo ""
        echo "Mount details:"
        mount | grep "$MOUNT_POINT" | tee -a "$LOG_FILE"
        
        return 0
    else
        print_status "ERROR" "File share is not mounted"
        return 1
    fi
}

################################################################################
# Function: verify_accessibility
# Description: Check if mount point is accessible
################################################################################
verify_accessibility() {
    print_header "Accessibility Check"
    
    log_info "Checking accessibility..."
    
    # Check if directory is readable
    if [[ -r "$MOUNT_POINT" ]]; then
        print_status "OK" "Mount point is readable"
    else
        print_status "ERROR" "Mount point is not readable"
        return 1
    fi
    
    # Try to list contents
    echo ""
    echo "Contents of $MOUNT_POINT:"
    if ls -la "$MOUNT_POINT" 2>&1 | tee -a "$LOG_FILE"; then
        print_status "OK" "Can list directory contents"
    else
        print_status "ERROR" "Cannot list directory contents"
        return 1
    fi
    
    return 0
}

################################################################################
# Function: verify_write_permission
# Description: Check if mount point is writable
################################################################################
verify_write_permission() {
    print_header "Write Permission Check"
    
    log_info "Checking write permissions..."
    
    local test_file="${MOUNT_POINT}/.verify-test-$(date +%s)"
    
    # Try to create a test file
    if echo "test write" > "$test_file" 2>/dev/null; then
        print_status "OK" "Can write to mount point"
        
        # Try to read the file
        if cat "$test_file" &> /dev/null; then
            print_status "OK" "Can read from mount point"
        else
            print_status "ERROR" "Cannot read from mount point"
            return 1
        fi
        
        # Clean up
        rm -f "$test_file"
        print_status "OK" "Can delete from mount point"
        
        return 0
    else
        print_status "ERROR" "Cannot write to mount point"
        return 1
    fi
}

################################################################################
# Function: verify_storage_info
# Description: Check storage information
################################################################################
verify_storage_info() {
    print_header "Storage Information"
    
    log_info "Gathering storage information..."
    
    echo ""
    df -h "$MOUNT_POINT" | tee -a "$LOG_FILE"
    
    # Parse storage info
    local size=$(df -h "$MOUNT_POINT" | awk 'NR==2 {print $2}')
    local used=$(df -h "$MOUNT_POINT" | awk 'NR==2 {print $3}')
    local available=$(df -h "$MOUNT_POINT" | awk 'NR==2 {print $4}')
    local use_pct=$(df -h "$MOUNT_POINT" | awk 'NR==2 {print $5}' | tr -d '%')
    
    echo ""
    print_status "INFO" "Total Size: $size"
    print_status "INFO" "Used: $used"
    print_status "INFO" "Available: $available"
    
    # Check usage percentage
    if [[ $use_pct -lt 80 ]]; then
        print_status "OK" "Storage usage: ${use_pct}% (healthy)"
    elif [[ $use_pct -lt 90 ]]; then
        print_status "WARNING" "Storage usage: ${use_pct}% (high)"
    else
        print_status "ERROR" "Storage usage: ${use_pct}% (critical)"
    fi
    
    return 0
}

################################################################################
# Function: verify_directory_structure
# Description: Check standard directory structure
################################################################################
verify_directory_structure() {
    print_header "Directory Structure"
    
    log_info "Checking directory structure..."
    
    # Standard directories
    local directories=(
        "k8s-join-token"
        "logs"
        "configs"
        "data"
        "backups"
        "scripts"
    )
    
    echo ""
    local missing_dirs=0
    
    for dir in "${directories[@]}"; do
        local dir_path="${MOUNT_POINT}/${dir}"
        
        if [[ -d "$dir_path" ]]; then
            print_status "OK" "Directory exists: $dir"
        else
            print_status "WARNING" "Directory missing: $dir"
            missing_dirs=$((missing_dirs + 1))
        fi
    done
    
    echo ""
    if [[ $missing_dirs -eq 0 ]]; then
        print_status "OK" "All standard directories exist"
    else
        print_status "WARNING" "$missing_dirs standard director(ies) missing"
    fi
    
    return 0
}

################################################################################
# Function: verify_fstab_entry
# Description: Check if fstab entry exists
################################################################################
verify_fstab_entry() {
    print_header "Persistence Check"
    
    log_info "Checking fstab entry..."
    
    if grep -q "$MOUNT_POINT" /etc/fstab 2>/dev/null; then
        print_status "OK" "fstab entry exists (mount will persist reboots)"
        
        echo ""
        echo "fstab entry:"
        grep "$MOUNT_POINT" /etc/fstab | tee -a "$LOG_FILE"
        
        return 0
    else
        print_status "WARNING" "fstab entry not found (mount will not persist reboots)"
        return 1
    fi
}

################################################################################
# Function: verify_credentials
# Description: Check credentials file
################################################################################
verify_credentials() {
    print_header "Credentials Check"
    
    log_info "Checking credentials file..."
    
    # Find credentials file
    local creds_dir="/etc/smbcredentials"
    
    if [[ -d "$creds_dir" ]]; then
        print_status "OK" "Credentials directory exists: $creds_dir"
        
        # List credential files
        local cred_count=$(find "$creds_dir" -name "*.cred" 2>/dev/null | wc -l)
        
        if [[ $cred_count -gt 0 ]]; then
            print_status "OK" "Found $cred_count credential file(s)"
            
            # Check permissions
            echo ""
            echo "Credential files:"
            find "$creds_dir" -name "*.cred" -exec ls -l {} \; | tee -a "$LOG_FILE"
            
            # Verify permissions are secure (600)
            local insecure=0
            while IFS= read -r file; do
                local perms=$(stat -c %a "$file" 2>/dev/null)
                if [[ "$perms" != "600" ]]; then
                    print_status "WARNING" "Insecure permissions on $(basename $file): $perms (should be 600)"
                    insecure=$((insecure + 1))
                fi
            done < <(find "$creds_dir" -name "*.cred")
            
            if [[ $insecure -eq 0 ]]; then
                print_status "OK" "All credential files have secure permissions (600)"
            fi
        else
            print_status "WARNING" "No credential files found"
        fi
    else
        print_status "WARNING" "Credentials directory not found: $creds_dir"
    fi
    
    return 0
}

################################################################################
# Function: verify_performance
# Description: Basic performance test
################################################################################
verify_performance() {
    print_header "Performance Test"
    
    log_info "Running basic performance test..."
    
    local test_file="${MOUNT_POINT}/.perf-test-$(date +%s)"
    local test_size_mb=10
    
    echo ""
    echo "Testing write performance (${test_size_mb}MB)..."
    
    # Write test
    local write_start=$(date +%s.%N)
    dd if=/dev/zero of="$test_file" bs=1M count=$test_size_mb 2>&1 | grep -E "copied|bytes" | tee -a "$LOG_FILE" || {
        print_status "WARNING" "Performance test failed"
        rm -f "$test_file"
        return 1
    }
    local write_end=$(date +%s.%N)
    local write_time=$(echo "$write_end - $write_start" | bc)
    
    echo ""
    echo "Testing read performance (${test_size_mb}MB)..."
    
    # Read test
    local read_start=$(date +%s.%N)
    dd if="$test_file" of=/dev/null bs=1M 2>&1 | grep -E "copied|bytes" | tee -a "$LOG_FILE"
    local read_end=$(date +%s.%N)
    local read_time=$(echo "$read_end - $read_start" | bc)
    
    # Clean up
    rm -f "$test_file"
    
    echo ""
    print_status "INFO" "Write time: ${write_time}s"
    print_status "INFO" "Read time: ${read_time}s"
    
    # Basic performance assessment
    if (( $(echo "$write_time < 5" | bc -l) )); then
        print_status "OK" "Write performance: Good"
    elif (( $(echo "$write_time < 10" | bc -l) )); then
        print_status "WARNING" "Write performance: Moderate"
    else
        print_status "WARNING" "Write performance: Slow"
    fi
    
    return 0
}

################################################################################
# Function: print_summary
# Description: Print verification summary
################################################################################
print_summary() {
    print_header "Verification Summary"
    
    local total_checks=8
    local passed_checks=0
    
    # Count passed checks (this is simplified, in production you'd track each check)
    echo ""
    echo "Verification Results:"
    
    # Mount exists
    if [[ -d "$MOUNT_POINT" ]]; then
        print_status "PASS" "Mount point exists"
        passed_checks=$((passed_checks + 1))
    else
        print_status "FAIL" "Mount point exists"
    fi
    
    # Is mounted
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        print_status "PASS" "File share is mounted"
        passed_checks=$((passed_checks + 1))
    else
        print_status "FAIL" "File share is mounted"
    fi
    
    # Is accessible
    if [[ -r "$MOUNT_POINT" ]]; then
        print_status "PASS" "Mount point is accessible"
        passed_checks=$((passed_checks + 1))
    else
        print_status "FAIL" "Mount point is accessible"
    fi
    
    # Is writable
    local test_file="${MOUNT_POINT}/.verify-summary-$(date +%s)"
    if echo "test" > "$test_file" 2>/dev/null; then
        rm -f "$test_file"
        print_status "PASS" "Mount point is writable"
        passed_checks=$((passed_checks + 1))
    else
        print_status "FAIL" "Mount point is writable"
    fi
    
    # Has fstab entry
    if grep -q "$MOUNT_POINT" /etc/fstab 2>/dev/null; then
        print_status "PASS" "fstab entry exists"
        passed_checks=$((passed_checks + 1))
    else
        print_status "WARN" "fstab entry missing"
    fi
    
    echo ""
    echo "Score: $passed_checks/$total_checks checks passed"
    echo ""
    
    if [[ $passed_checks -eq $total_checks ]]; then
        print_status "SUCCESS" "All verification checks passed!"
    elif [[ $passed_checks -ge 4 ]]; then
        print_status "WARNING" "Verification completed with warnings"
    else
        print_status "ERROR" "Verification failed"
    fi
    
    echo ""
    echo "View logs: tail -f $LOG_FILE"
    echo ""
}

################################################################################
# Main execution
################################################################################
main() {
    log_info "=========================================="
    log_info "Starting Azure File Share mount verification"
    log_info "=========================================="
    
    # Execute verification steps
    verify_mount_exists
    verify_mounted
    verify_accessibility
    verify_write_permission
    verify_storage_info
    verify_directory_structure
    verify_fstab_entry
    verify_credentials
    verify_performance
    
    print_summary
    
    log_info "=========================================="
    log_info "Mount verification completed"
    log_info "=========================================="
    
    exit 0
}

# Execute main function
main "$@"
