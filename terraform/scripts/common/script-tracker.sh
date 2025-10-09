#!/bin/bash
# =============================================================================
# SCRIPT EXECUTION TRACKER
# =============================================================================
# Provides functions to track and query script execution history
# Usage: source terraform/scripts/common/script-tracker.sh
# =============================================================================

# Source logging standard if not already loaded
if [[ -z "$PROJECT_ROOT" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/logging-standard.sh"
fi

# Get last execution of a script
get_last_execution() {
    local script_name="$1"
    local registry="${PROJECT_ROOT}/script-execution.registry"
    
    if [[ ! -f "$registry" ]]; then
        echo "Registry not found"
        return 1
    fi
    
    grep "|${script_name}|" "$registry" | tail -1
}

# Check if script succeeded in last execution
check_last_success() {
    local script_name="$1"
    local last_exec=$(get_last_execution "$script_name")
    
    if [[ -z "$last_exec" ]]; then
        return 1  # Never executed
    fi
    
    local exit_code=$(echo "$last_exec" | cut -d'|' -f8)
    [[ "$exit_code" == "0" ]]
}

# Get execution count for a script
get_execution_count() {
    local script_name="$1"
    local registry="${PROJECT_ROOT}/script-execution.registry"
    
    if [[ ! -f "$registry" ]]; then
        echo "0"
        return
    fi
    
    grep -c "|${script_name}|" "$registry" || echo "0"
}

# Display execution history for a script
show_execution_history() {
    local script_name="$1"
    local registry="${PROJECT_ROOT}/script-execution.registry"
    
    if [[ ! -f "$registry" ]]; then
        echo "No execution history found"
        return 1
    fi
    
    echo "=== Execution History for ${script_name} ==="
    echo "TIMESTAMP | EXIT_CODE | DURATION | ENVIRONMENT"
    echo "-------------------------------------------"
    
    grep "|${script_name}|" "$registry" | while IFS='|' read -r timestamp exec_id name path user workdir logfile exitcode duration org plat env; do
        echo "${timestamp} | ${exitcode} | ${duration} | ${org}/${plat}/${env}"
    done
}

# Check if any scripts are currently running
check_running_scripts() {
    local registry="${PROJECT_ROOT}/script-execution.registry"
    
    if [[ ! -f "$registry" ]]; then
        return 1
    fi
    
    # Get list of execution IDs from last hour
    local cutoff=$(date -d '1 hour ago' '+%Y%m%d-%H%M%S' 2>/dev/null || date -v-1H '+%Y%m%d-%H%M%S')
    
    # Check for processes matching execution IDs
    # This is a simplified check - in practice, would need more sophisticated logic
    return 0
}

# Export functions
export -f get_last_execution check_last_success get_execution_count show_execution_history check_running_scripts
