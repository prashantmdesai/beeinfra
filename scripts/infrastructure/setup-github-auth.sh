#!/bin/bash
################################################################################
# Script: setup-github-auth.sh
# Description: Configure GitHub authentication using Personal Access Token
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
readonly SCRIPT_NAME="setup-github-auth"
readonly LOG_FILE="/var/log/infrastructure/${SCRIPT_NAME}.log"

# GitHub configuration (can be overridden by environment variables)
readonly GITHUB_PAT="${GITHUB_PAT:-}"
readonly TARGET_USER="${TARGET_USER:-beeuser}"
readonly GITHUB_USERNAME="${GITHUB_USERNAME:-prashantmdesai}"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

################################################################################
# Function: check_prerequisites
# Description: Verify prerequisites for GitHub authentication setup
################################################################################
check_prerequisites() {
    log_info "Checking prerequisites for GitHub authentication setup..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        return 1
    fi
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        log_error "Git not found. Please install git first"
        return 1
    fi
    
    # Check if target user exists
    if ! id "$TARGET_USER" &>/dev/null; then
        log_error "Target user not found: $TARGET_USER"
        return 1
    fi
    
    # Get user home directory
    local user_home=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    if [[ -z "$user_home" ]]; then
        log_error "Failed to get home directory for user: $TARGET_USER"
        return 1
    fi
    
    log_info "User home directory: $user_home"
    log_info "Prerequisites check completed successfully"
    return 0
}

################################################################################
# Function: check_if_configured
# Description: Check if GitHub authentication is already configured
################################################################################
check_if_configured() {
    log_info "Checking if GitHub authentication is already configured..."
    
    local user_home=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    local git_config="${user_home}/.gitconfig"
    local credentials_file="${user_home}/.github-credentials"
    
    # Check if .gitconfig exists with credential helper
    if [[ -f "$git_config" ]]; then
        if grep -q "credential" "$git_config" 2>/dev/null; then
            log_info "Git credential helper is configured"
            return 0
        fi
    fi
    
    # Check if credentials file exists
    if [[ -f "$credentials_file" ]]; then
        log_info "GitHub credentials file exists"
        return 0
    fi
    
    log_info "GitHub authentication is not configured"
    return 1
}

################################################################################
# Function: get_github_pat
# Description: Get GitHub Personal Access Token
################################################################################
get_github_pat() {
    log_info "Getting GitHub Personal Access Token..."
    
    local pat="$GITHUB_PAT"
    
    # Try to read from environment config
    if [[ -z "$pat" ]] && [[ -f "/etc/github-credentials.conf" ]]; then
        source "/etc/github-credentials.conf"
        pat="$GITHUB_PAT"
    fi
    
    if [[ -z "$pat" ]]; then
        log_error "GitHub PAT not found"
        log_error "Please set GITHUB_PAT environment variable"
        return 1
    fi
    
    # Validate PAT format (should start with ghp_ or github_pat_)
    if [[ ! "$pat" =~ ^(ghp_|github_pat_) ]]; then
        log_warning "PAT does not match expected format (should start with ghp_ or github_pat_)"
    fi
    
    log_info "GitHub PAT retrieved successfully"
    echo "$pat"
    return 0
}

################################################################################
# Function: create_credentials_file
# Description: Create GitHub credentials file
################################################################################
create_credentials_file() {
    log_info "Creating GitHub credentials file..."
    
    local user_home=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    local credentials_file="${user_home}/.github-credentials"
    
    # Get GitHub PAT
    local pat
    pat=$(get_github_pat) || return 1
    
    # Create credentials file
    cat > "$credentials_file" <<EOF
# GitHub Credentials
# Generated: $(date)

# GitHub Personal Access Token
GITHUB_PAT=${pat}

# GitHub Repository Configuration
GITHUB_INFRA_REPO=https://github.com/prashantmdesai/infra
GITHUB_INFRA_PATH=/home/${TARGET_USER}/plt

# GitHub Username
GITHUB_USERNAME=${GITHUB_USERNAME}
EOF
    
    # Set ownership and permissions
    chown "${TARGET_USER}:${TARGET_USER}" "$credentials_file"
    chmod 600 "$credentials_file"
    
    log_info "Credentials file created: $credentials_file"
    return 0
}

################################################################################
# Function: configure_git_global
# Description: Configure Git global settings
################################################################################
configure_git_global() {
    log_info "Configuring Git global settings..."
    
    local user_home=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    
    # Configure as target user
    su - "$TARGET_USER" -c "git config --global user.name '${GITHUB_USERNAME}'" || {
        log_error "Failed to set git user name"
        return 1
    }
    
    su - "$TARGET_USER" -c "git config --global user.email '${GITHUB_USERNAME}@users.noreply.github.com'" || {
        log_error "Failed to set git user email"
        return 1
    }
    
    # Set default branch name
    su - "$TARGET_USER" -c "git config --global init.defaultBranch main" || log_warning "Failed to set default branch"
    
    # Configure credential helper
    su - "$TARGET_USER" -c "git config --global credential.helper store" || {
        log_error "Failed to configure credential helper"
        return 1
    }
    
    log_info "Git global settings configured successfully"
    return 0
}

################################################################################
# Function: setup_credential_store
# Description: Set up Git credential store
################################################################################
setup_credential_store() {
    log_info "Setting up Git credential store..."
    
    local user_home=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    local git_credentials="${user_home}/.git-credentials"
    
    # Get GitHub PAT
    local pat
    pat=$(get_github_pat) || return 1
    
    # Create credentials store file
    cat > "$git_credentials" <<EOF
https://${GITHUB_USERNAME}:${pat}@github.com
EOF
    
    # Set ownership and permissions
    chown "${TARGET_USER}:${TARGET_USER}" "$git_credentials"
    chmod 600 "$git_credentials"
    
    log_info "Git credential store configured: $git_credentials"
    return 0
}

################################################################################
# Function: configure_ssh_known_hosts
# Description: Add GitHub to SSH known hosts
################################################################################
configure_ssh_known_hosts() {
    log_info "Configuring SSH known hosts for GitHub..."
    
    local user_home=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    local ssh_dir="${user_home}/.ssh"
    local known_hosts="${ssh_dir}/known_hosts"
    
    # Create .ssh directory if it doesn't exist
    if [[ ! -d "$ssh_dir" ]]; then
        mkdir -p "$ssh_dir"
        chown "${TARGET_USER}:${TARGET_USER}" "$ssh_dir"
        chmod 700 "$ssh_dir"
    fi
    
    # Add GitHub host keys if not already present
    if [[ ! -f "$known_hosts" ]] || ! grep -q "github.com" "$known_hosts" 2>/dev/null; then
        log_info "Adding GitHub host keys..."
        
        # Get GitHub SSH keys
        su - "$TARGET_USER" -c "ssh-keyscan github.com >> ${known_hosts} 2>/dev/null" || {
            log_warning "Failed to add GitHub SSH keys"
            return 0
        }
        
        log_info "GitHub host keys added"
    else
        log_info "GitHub host keys already present"
    fi
    
    return 0
}

################################################################################
# Function: test_authentication
# Description: Test GitHub authentication
################################################################################
test_authentication() {
    log_info "Testing GitHub authentication..."
    
    # Test HTTPS authentication
    log_info "Testing HTTPS authentication..."
    
    local test_result
    test_result=$(su - "$TARGET_USER" -c "git ls-remote https://github.com/prashantmdesai/infra.git HEAD 2>&1")
    
    if [[ $? -eq 0 ]]; then
        log_info "HTTPS authentication successful"
        return 0
    else
        log_error "HTTPS authentication failed"
        log_error "Output: $test_result"
        return 1
    fi
}

################################################################################
# Function: create_helper_scripts
# Description: Create helper scripts for GitHub operations
################################################################################
create_helper_scripts() {
    log_info "Creating helper scripts..."
    
    local user_home=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    local scripts_dir="${user_home}/.local/bin"
    
    # Create scripts directory
    mkdir -p "$scripts_dir"
    chown "${TARGET_USER}:${TARGET_USER}" "$scripts_dir"
    
    # Create git-push helper
    cat > "${scripts_dir}/git-push-infra" <<'EOF'
#!/bin/bash
# Helper script to push to infrastructure repository

cd ~/plt || exit 1
git add -A
git commit -m "${1:-Update infrastructure}"
git push origin main
EOF
    
    chmod +x "${scripts_dir}/git-push-infra"
    chown "${TARGET_USER}:${TARGET_USER}" "${scripts_dir}/git-push-infra"
    
    # Create git-pull helper
    cat > "${scripts_dir}/git-pull-infra" <<'EOF'
#!/bin/bash
# Helper script to pull from infrastructure repository

cd ~/plt || exit 1
git pull origin main
EOF
    
    chmod +x "${scripts_dir}/git-pull-infra"
    chown "${TARGET_USER}:${TARGET_USER}" "${scripts_dir}/git-pull-infra"
    
    # Add scripts directory to PATH
    local bashrc="${user_home}/.bashrc"
    if ! grep -q ".local/bin" "$bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$bashrc"
        chown "${TARGET_USER}:${TARGET_USER}" "$bashrc"
    fi
    
    log_info "Helper scripts created in: $scripts_dir"
    return 0
}

################################################################################
# Function: verify_configuration
# Description: Verify GitHub authentication configuration
################################################################################
verify_configuration() {
    log_info "Verifying GitHub authentication configuration..."
    
    local user_home=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    
    # Check credentials file
    if [[ -f "${user_home}/.github-credentials" ]]; then
        log_info "✓ GitHub credentials file exists"
    else
        log_error "✗ GitHub credentials file missing"
        return 1
    fi
    
    # Check git-credentials
    if [[ -f "${user_home}/.git-credentials" ]]; then
        log_info "✓ Git credentials store exists"
    else
        log_error "✗ Git credentials store missing"
        return 1
    fi
    
    # Check git config
    if su - "$TARGET_USER" -c "git config --global user.name" &>/dev/null; then
        log_info "✓ Git user name configured"
    else
        log_error "✗ Git user name not configured"
        return 1
    fi
    
    # Check credential helper
    if su - "$TARGET_USER" -c "git config --global credential.helper" | grep -q "store"; then
        log_info "✓ Git credential helper configured"
    else
        log_error "✗ Git credential helper not configured"
        return 1
    fi
    
    log_info "Configuration verification completed successfully"
    return 0
}

################################################################################
# Function: print_summary
# Description: Print configuration summary
################################################################################
print_summary() {
    local user_home=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    local git_user=$(su - "$TARGET_USER" -c "git config --global user.name" 2>/dev/null || echo "not set")
    local git_email=$(su - "$TARGET_USER" -c "git config --global user.email" 2>/dev/null || echo "not set")
    
    echo ""
    echo "=========================================="
    echo "GitHub Authentication Setup Summary"
    echo "=========================================="
    echo "Status: SUCCESS"
    echo "User: $TARGET_USER"
    echo "Home Directory: $user_home"
    echo ""
    echo "Git Configuration:"
    echo "  - User Name: $git_user"
    echo "  - User Email: $git_email"
    echo "  - Credential Helper: store"
    echo ""
    echo "Configuration Files:"
    echo "  - Credentials: ${user_home}/.github-credentials"
    echo "  - Git Credentials: ${user_home}/.git-credentials"
    echo "  - Git Config: ${user_home}/.gitconfig"
    echo ""
    echo "Helper Scripts:"
    echo "  - Push: git-push-infra \"commit message\""
    echo "  - Pull: git-pull-infra"
    echo ""
    echo "Authentication Test:"
    if test_authentication &>/dev/null; then
        echo "  - HTTPS: ✓ Working"
    else
        echo "  - HTTPS: ✗ Failed"
    fi
    echo ""
    echo "View logs: tail -f $LOG_FILE"
    echo "=========================================="
}

################################################################################
# Main execution
################################################################################
main() {
    log_info "=========================================="
    log_info "Starting GitHub authentication setup"
    log_info "=========================================="
    
    # Check if already configured (idempotency)
    if check_if_configured; then
        log_info "GitHub authentication is already configured"
        verify_configuration
        print_summary
        exit 0
    fi
    
    # Execute setup steps
    check_prerequisites || exit 1
    create_credentials_file || exit 1
    configure_git_global || exit 1
    setup_credential_store || exit 1
    configure_ssh_known_hosts || exit 1
    create_helper_scripts || exit 1
    verify_configuration || exit 1
    test_authentication || log_warning "Authentication test failed, but configuration is complete"
    
    log_info "=========================================="
    log_info "GitHub authentication setup completed"
    log_info "=========================================="
    
    print_summary
    exit 0
}

# Execute main function
main "$@"
