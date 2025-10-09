#!/bin/bash
################################################################################
# Script: clone-infra-repo.sh
# Description: Clone infrastructure repository from GitHub
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
readonly SCRIPT_NAME="clone-infra-repo"
readonly LOG_FILE="/var/log/infrastructure/${SCRIPT_NAME}.log"

# Repository configuration (can be overridden by environment variables)
readonly GITHUB_PAT="${GITHUB_PAT:-}"
readonly GITHUB_REPO_URL="${GITHUB_REPO_URL:-https://github.com/prashantmdesai/infra}"
readonly CLONE_PATH="${CLONE_PATH:-/home/beeuser/plt}"
readonly REPO_OWNER="${REPO_OWNER:-beeuser}"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

################################################################################
# Function: check_prerequisites
# Description: Verify prerequisites for cloning repository
################################################################################
check_prerequisites() {
    log_info "Checking prerequisites for repository cloning..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        return 1
    fi
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        log_info "Git not found, installing..."
        apt-get update -qq
        apt-get install -y -qq git || {
            log_error "Failed to install git"
            return 1
        }
        log_info "Git installed successfully"
    fi
    
    # Verify Git version
    local git_version=$(git --version | awk '{print $3}')
    log_info "Git version: $git_version"
    
    # Check if GitHub PAT is set
    if [[ -z "$GITHUB_PAT" ]]; then
        log_warning "GITHUB_PAT not set, will try to read from config file"
    fi
    
    # Check if repository URL is set
    if [[ -z "$GITHUB_REPO_URL" ]]; then
        log_error "GITHUB_REPO_URL is not set"
        return 1
    fi
    
    # Check if clone path is set
    if [[ -z "$CLONE_PATH" ]]; then
        log_error "CLONE_PATH is not set"
        return 1
    fi
    
    log_info "Prerequisites check completed successfully"
    return 0
}

################################################################################
# Function: check_if_cloned
# Description: Check if repository is already cloned
################################################################################
check_if_cloned() {
    log_info "Checking if repository is already cloned..."
    
    if [[ -d "$CLONE_PATH" ]]; then
        # Check if it's a git repository
        if [[ -d "$CLONE_PATH/.git" ]]; then
            log_info "Repository already cloned at: $CLONE_PATH"
            
            # Get current remote URL
            local remote_url=$(cd "$CLONE_PATH" && git config --get remote.origin.url 2>/dev/null || echo "")
            
            if [[ -n "$remote_url" ]]; then
                log_info "Remote URL: $remote_url"
                return 0
            else
                log_warning "Directory exists but remote URL not found"
                return 1
            fi
        else
            log_warning "Directory exists but is not a git repository"
            return 1
        fi
    fi
    
    log_info "Repository is not cloned"
    return 1
}

################################################################################
# Function: get_github_pat
# Description: Get GitHub Personal Access Token
################################################################################
get_github_pat() {
    log_info "Getting GitHub Personal Access Token..."
    
    local pat="$GITHUB_PAT"
    
    # Try to read from credentials file
    if [[ -z "$pat" ]] && [[ -f "/home/${REPO_OWNER}/.github-credentials" ]]; then
        source "/home/${REPO_OWNER}/.github-credentials"
        pat="$GITHUB_PAT"
    fi
    
    # Try to read from environment config
    if [[ -z "$pat" ]] && [[ -f "/etc/github-credentials.conf" ]]; then
        source "/etc/github-credentials.conf"
        pat="$GITHUB_PAT"
    fi
    
    if [[ -z "$pat" ]]; then
        log_error "GitHub PAT not found"
        log_error "Please set GITHUB_PAT environment variable or create credentials file"
        return 1
    fi
    
    log_info "GitHub PAT retrieved successfully"
    echo "$pat"
    return 0
}

################################################################################
# Function: construct_auth_url
# Description: Construct authenticated GitHub URL
################################################################################
construct_auth_url() {
    local pat="$1"
    local repo_url="$2"
    
    # Remove https:// prefix if present
    local url_without_protocol="${repo_url#https://}"
    
    # Construct authenticated URL
    local auth_url="https://${pat}@${url_without_protocol}"
    
    echo "$auth_url"
    return 0
}

################################################################################
# Function: create_clone_directory
# Description: Create parent directory for clone
################################################################################
create_clone_directory() {
    log_info "Creating clone directory..."
    
    local parent_dir=$(dirname "$CLONE_PATH")
    
    # Create parent directory if it doesn't exist
    if [[ ! -d "$parent_dir" ]]; then
        mkdir -p "$parent_dir" || {
            log_error "Failed to create parent directory: $parent_dir"
            return 1
        }
        log_info "Parent directory created: $parent_dir"
    fi
    
    return 0
}

################################################################################
# Function: backup_existing_directory
# Description: Backup existing directory if present
################################################################################
backup_existing_directory() {
    log_info "Checking for existing directory..."
    
    if [[ -d "$CLONE_PATH" ]]; then
        local backup_path="${CLONE_PATH}.backup.$(date +%Y%m%d-%H%M%S)"
        
        log_info "Existing directory found, creating backup: $backup_path"
        mv "$CLONE_PATH" "$backup_path" || {
            log_error "Failed to create backup"
            return 1
        }
        
        log_info "Backup created successfully"
    fi
    
    return 0
}

################################################################################
# Function: clone_repository
# Description: Clone the repository from GitHub
################################################################################
clone_repository() {
    log_info "Cloning repository..."
    log_info "Repository: $GITHUB_REPO_URL"
    log_info "Destination: $CLONE_PATH"
    
    # Get GitHub PAT
    local pat
    pat=$(get_github_pat) || return 1
    
    # Construct authenticated URL
    local auth_url
    auth_url=$(construct_auth_url "$pat" "$GITHUB_REPO_URL")
    
    # Clone repository
    log_info "Cloning from GitHub (this may take a few minutes)..."
    
    git clone "$auth_url" "$CLONE_PATH" 2>&1 | tee -a "$LOG_FILE" || {
        log_error "Failed to clone repository"
        log_error "Please verify:"
        log_error "  1. GitHub PAT is valid and has repo access"
        log_error "  2. Repository URL is correct: $GITHUB_REPO_URL"
        log_error "  3. Network connectivity to GitHub"
        return 1
    }
    
    log_info "Repository cloned successfully"
    return 0
}

################################################################################
# Function: configure_repository
# Description: Configure cloned repository
################################################################################
configure_repository() {
    log_info "Configuring repository..."
    
    cd "$CLONE_PATH" || {
        log_error "Failed to change to repository directory"
        return 1
    }
    
    # Get current branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    log_info "Current branch: $current_branch"
    
    # Get latest commit
    local latest_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    log_info "Latest commit: $latest_commit"
    
    # Configure Git user (for potential commits)
    git config user.name "${REPO_OWNER}" || log_warning "Failed to set git user name"
    git config user.email "${REPO_OWNER}@localhost" || log_warning "Failed to set git user email"
    
    log_info "Repository configuration completed"
    return 0
}

################################################################################
# Function: set_permissions
# Description: Set proper ownership and permissions
################################################################################
set_permissions() {
    log_info "Setting ownership and permissions..."
    
    # Check if owner user exists
    if ! id "$REPO_OWNER" &>/dev/null; then
        log_warning "User $REPO_OWNER not found, skipping ownership change"
        return 0
    fi
    
    # Change ownership
    chown -R "${REPO_OWNER}:${REPO_OWNER}" "$CLONE_PATH" || {
        log_error "Failed to change ownership"
        return 1
    }
    
    # Set directory permissions
    find "$CLONE_PATH" -type d -exec chmod 755 {} \; || log_warning "Failed to set directory permissions"
    
    # Set file permissions
    find "$CLONE_PATH" -type f -exec chmod 644 {} \; || log_warning "Failed to set file permissions"
    
    # Make scripts executable
    find "$CLONE_PATH" -name "*.sh" -exec chmod 755 {} \; || log_warning "Failed to set script permissions"
    
    log_info "Ownership and permissions set successfully"
    return 0
}

################################################################################
# Function: verify_clone
# Description: Verify repository was cloned successfully
################################################################################
verify_clone() {
    log_info "Verifying repository clone..."
    
    # Check if directory exists
    if [[ ! -d "$CLONE_PATH" ]]; then
        log_error "Clone directory does not exist"
        return 1
    fi
    
    # Check if it's a git repository
    if [[ ! -d "$CLONE_PATH/.git" ]]; then
        log_error "Directory is not a git repository"
        return 1
    fi
    
    # Check if we can get repository info
    cd "$CLONE_PATH" || return 1
    
    local repo_status=$(git status --porcelain 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        log_info "Repository status verified"
    else
        log_error "Failed to get repository status"
        return 1
    fi
    
    # List repository contents
    log_info "Repository contents:"
    ls -la "$CLONE_PATH" | tee -a "$LOG_FILE"
    
    log_info "Repository verification completed successfully"
    return 0
}

################################################################################
# Function: print_summary
# Description: Print clone summary
################################################################################
print_summary() {
    cd "$CLONE_PATH" || return 1
    
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    local commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    local commit_msg=$(git log -1 --pretty=%B 2>/dev/null | head -n1 || echo "unknown")
    local commit_date=$(git log -1 --pretty=%cd 2>/dev/null || echo "unknown")
    local file_count=$(find . -type f | wc -l)
    local dir_count=$(find . -type d | wc -l)
    
    echo ""
    echo "=========================================="
    echo "Infrastructure Repository Clone Summary"
    echo "=========================================="
    echo "Status: SUCCESS"
    echo "Repository: $GITHUB_REPO_URL"
    echo "Clone Path: $CLONE_PATH"
    echo "Owner: $REPO_OWNER"
    echo ""
    echo "Git Information:"
    echo "  - Branch: $branch"
    echo "  - Commit: $commit"
    echo "  - Message: $commit_msg"
    echo "  - Date: $commit_date"
    echo ""
    echo "Repository Statistics:"
    echo "  - Files: $file_count"
    echo "  - Directories: $dir_count"
    echo ""
    echo "Next Steps:"
    echo "  1. Review repository contents: cd $CLONE_PATH"
    echo "  2. Pull latest changes: git pull"
    echo "  3. Check status: git status"
    echo ""
    echo "View logs: tail -f $LOG_FILE"
    echo "=========================================="
}

################################################################################
# Main execution
################################################################################
main() {
    log_info "=========================================="
    log_info "Starting infrastructure repository clone"
    log_info "=========================================="
    
    # Check if already cloned (idempotency)
    if check_if_cloned; then
        log_info "Repository is already cloned"
        
        # Update repository
        log_info "Pulling latest changes..."
        cd "$CLONE_PATH" && git pull 2>&1 | tee -a "$LOG_FILE" || log_warning "Failed to pull latest changes"
        
        print_summary
        exit 0
    fi
    
    # Execute clone steps
    check_prerequisites || exit 1
    create_clone_directory || exit 1
    backup_existing_directory || exit 1
    clone_repository || exit 1
    configure_repository || exit 1
    set_permissions || exit 1
    verify_clone || exit 1
    
    log_info "=========================================="
    log_info "Repository cloned successfully"
    log_info "=========================================="
    
    print_summary
    exit 0
}

# Execute main function
main "$@"
