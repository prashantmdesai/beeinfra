#!/bin/bash
# =============================================================================
# ERROR HANDLERS
# =============================================================================
# Standardized error handling functions for infrastructure scripts
# Usage: source terraform/scripts/common/error-handlers.sh
# =============================================================================

# Source logging if not already loaded
if [[ -z "$PROJECT_ROOT" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/logging-standard.sh"
fi

# Enable strict error handling
set_strict_mode() {
    set -euo pipefail
    IFS=$'\n\t'
    log_debug "Strict mode enabled (set -euo pipefail)"
}

# Disable strict error handling (use with caution)
unset_strict_mode() {
    set +euo pipefail
    log_debug "Strict mode disabled"
}

# Error exit function
error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    
    log_error "$message"
    log_error "Script failed with exit code: $exit_code"
    
    exit "$exit_code"
}

# Warn but continue
warn_continue() {
    local message="$1"
    
    log_warn "$message"
    log_warn "Continuing execution..."
}

# Check command exit code and handle error
check_exit_code() {
    local exit_code=$?
    local command="$1"
    local error_message="${2:-Command failed}"
    
    if [[ $exit_code -ne 0 ]]; then
        error_exit "${error_message}: ${command} (exit code: ${exit_code})" "$exit_code"
    fi
    
    return 0
}

# Run command with error handling
run_with_error_handling() {
    local command="$1"
    local error_message="${2:-Command execution failed}"
    
    log_info "Executing: ${command}"
    
    if eval "$command"; then
        log_success "Command succeeded: ${command}"
        return 0
    else
        local exit_code=$?
        error_exit "${error_message}" "$exit_code"
    fi
}

# Run command and continue on error
run_and_continue() {
    local command="$1"
    local warn_message="${2:-Command failed but continuing}"
    
    log_info "Executing: ${command}"
    
    if eval "$command"; then
        log_success "Command succeeded: ${command}"
        return 0
    else
        local exit_code=$?
        warn_continue "${warn_message} (exit code: ${exit_code})"
        return "$exit_code"
    fi
}

# Retry function with exponential backoff
retry_with_backoff() {
    local max_attempts="${1:-3}"
    local initial_delay="${2:-5}"
    local max_delay="${3:-60}"
    shift 3
    local command="$*"
    
    local attempt=1
    local delay="$initial_delay"
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Attempt ${attempt}/${max_attempts}: ${command}"
        
        if eval "$command"; then
            log_success "Command succeeded on attempt ${attempt}"
            return 0
        else
            local exit_code=$?
            
            if [[ $attempt -eq $max_attempts ]]; then
                error_exit "Command failed after ${max_attempts} attempts" "$exit_code"
            fi
            
            log_warn "Attempt ${attempt} failed (exit code: ${exit_code}). Retrying in ${delay}s..."
            sleep "$delay"
            
            # Exponential backoff
            delay=$((delay * 2))
            if [[ $delay -gt $max_delay ]]; then
                delay=$max_delay
            fi
            
            ((attempt++))
        fi
    done
    
    return 1
}

# Cleanup function to be called on error
cleanup_on_error() {
    log_error "Error detected! Running cleanup..."
    
    # Override this function in your script with specific cleanup logic
    # Example:
    # cleanup_on_error() {
    #     log_info "Cleaning up temporary files..."
    #     rm -f /tmp/myfile
    # }
}

# Rollback function
rollback_changes() {
    local rollback_message="${1:-Rolling back changes due to error}"
    
    log_warn "$rollback_message"
    
    # Override this function in your script with specific rollback logic
    # Example:
    # rollback_changes() {
    #     log_info "Destroying partial infrastructure..."
    #     terraform destroy -auto-approve
    # }
}

# Trap error and call cleanup
trap_error() {
    local exit_code=$?
    local line_number="${1:-unknown}"
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "Error on line ${line_number} (exit code: ${exit_code})"
        cleanup_on_error
        
        # Ask if rollback is needed (only in interactive mode)
        if [[ -t 0 ]] && [[ "${AUTO_ROLLBACK:-false}" != "true" ]]; then
            read -p "Do you want to rollback changes? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rollback_changes
            fi
        elif [[ "${AUTO_ROLLBACK:-false}" == "true" ]]; then
            rollback_changes "Auto-rollback enabled"
        fi
    fi
}

# Set up error trap
setup_error_trap() {
    trap 'trap_error ${LINENO}' ERR
    log_debug "Error trap enabled"
}

# Validate prerequisites before proceeding
validate_or_exit() {
    local validation_function="$1"
    local error_message="${2:-Validation failed}"
    
    if ! "$validation_function"; then
        error_exit "$error_message"
    fi
}

# Prompt for confirmation
confirm_or_exit() {
    local prompt="$1"
    local default="${2:-N}"
    
    if [[ "${AUTO_CONFIRM:-false}" == "true" ]]; then
        log_info "Auto-confirm enabled. Proceeding with: ${prompt}"
        return 0
    fi
    
    local reply
    read -p "${prompt} (y/N): " -n 1 -r reply
    echo
    
    if [[ ! $reply =~ ^[Yy]$ ]]; then
        log_warn "Operation cancelled by user"
        exit 0
    fi
    
    log_info "User confirmed. Proceeding..."
    return 0
}

# Export functions
export -f set_strict_mode unset_strict_mode error_exit warn_continue check_exit_code
export -f run_with_error_handling run_and_continue retry_with_backoff
export -f cleanup_on_error rollback_changes trap_error setup_error_trap
export -f validate_or_exit confirm_or_exit
