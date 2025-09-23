# =============================================================================
# INFRASTRUCTURE COMMAND LOGGING STANDARD - BASH MODULE
# =============================================================================
# Based on scsm-vault-server-setup-smart.sh logging standards
# Usage: source this file at the beginning of any bash script
# =============================================================================

# Find project root by looking for script-execution.registry
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
while [[ ! -f "$PROJECT_ROOT/script-execution.registry" && "$PROJECT_ROOT" != "/" ]]; do
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done

# Ensure logs directory and registry exist
LOGS_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOGS_DIR"

# Setup logging
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SCRIPT_NAME=$(basename "$0")
LOG_FILE="$LOGS_DIR/${SCRIPT_NAME%.*}-${TIMESTAMP}.log"

# Script execution tracking function
track_script_execution() {
    local exit_code=${1:-0}
    local SCRIPT_EXECUTION_TRACKER="$PROJECT_ROOT/script-execution.registry"
    
    # Initialize registry file with headers if it doesn't exist
    if [[ ! -f "$SCRIPT_EXECUTION_TRACKER" ]]; then
        echo "TIMESTAMP|EXECUTION_ID|SCRIPT_NAME|SCRIPT_PATH|USER|WORKING_DIR|LOG_FILE|EXIT_CODE|DURATION|ORGNM|PLTNM|ENVNM" > "$SCRIPT_EXECUTION_TRACKER"
    fi
    
    # Calculate execution duration
    local SCRIPT_START_TIME=${SCRIPT_START_TIME:-$(date +%s)}
    local SCRIPT_END_TIME=$(date +%s)
    local SCRIPT_DURATION=$((SCRIPT_END_TIME - SCRIPT_START_TIME))
    local EXECUTION_ID=$(date +%Y%m%d-%H%M%S)-$$
    
    # Capture environment variables (with defaults)
    local ORG_NAME="${ORGNM:-UNKNOWN}"
    local PLATFORM_NAME="${PLTNM:-UNKNOWN}"
    local ENV_NAME="${ENVNM:-UNKNOWN}"
    
    # Log execution to registry
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$EXECUTION_ID|$(basename "$0")|$(realpath "$0")|$USER|$(pwd)|$LOG_FILE|$exit_code|${SCRIPT_DURATION}s|$ORG_NAME|$PLATFORM_NAME|$ENV_NAME" >> "$SCRIPT_EXECUTION_TRACKER"
}

# Setup logging function
setup_logging() {
    echo "============================================================================="
    echo "📜 $(basename "$0") - Infrastructure Command Logging Standard"
    echo "============================================================================="
    echo "Script: $0"
    echo "Log File: $LOG_FILE"
    echo "Timestamp: $(date)"
    echo "============================================================================="
    echo ""
    
    # Redirect output to both console and log file
    exec > >(tee -a "$LOG_FILE") 2>&1
}

# Set script start time and exit trap
SCRIPT_START_TIME=$(date +%s)
trap 'track_script_execution $?' EXIT

# Export variables
export PROJECT_ROOT LOGS_DIR LOG_FILE SCRIPT_START_TIME