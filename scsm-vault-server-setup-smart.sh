#!/bin/bash

######## #    • SMART KEY RECOVERY: Auto-recovers keys from multiple backup locations:
#   2. Smart key recovery from multiple backup locations:
#      - Primary: /home/beeuser/plt/infra-cnf/${ORGNM}/${PLTNM}/${ENVNM}/scsm-vault/vault-keys.json (external to git repo)
#      - Docker volume backup: scsm_vault_config:/vault-keys-backup.json
#      - Timestamped backups: /home/beeuser/plt/backup/vault/Smart key recovery from multiple backup locations:
#      - Primary: /home/beeuser/plt/infra-cnf/${ORGNM}/${PLTNM}/${ENVNM}/scsm-vault/scsm-vault-keys.json
#      - Docker volume: scsm_vault_config:/vault-keys-backup.json#######################################################################
# SCSM Vault Smart Setup - Daily Operations & Intelligent Recovery
#################################################################################
# 
# 🎯 PURPOSE:
#    DAILY OPERATIONS script for SCSM Vault management
#    Intelligently handles vault unsealing, status checks, and key recovery
#
# 📅 WHEN TO USE:
#    ✅ Every time you start vault (daily operations)
#    ✅ When vault is sealed and needs unsealing
#    ✅ After vault container restarts
#    ✅ For routine status checks and secret verification
#    ❌ Fresh vault initialization (use production script instead)
#    ❌ After clearing vault data (use production script instead)
#
# 🔑 KEY FEATURES:
#    • INTELLIGENT DETECTION: Checks if vault is initialized/sealed
#    • SMART KEY RECOVERY: Auto-recovers keys from multiple backup locations:
#   2. Smart key recovery from multiple backup locations:
#      - Primary: /home/beeuser/plt/infra-cnf/${ORGNM}/${PLTNM}/${ENVNM}/scsm-vault/scsm-vault-keys.json
#      - Docker volume backup: scsm_vault_config:/vault-keys-backup.json
#      - Timestamped backups: /home/beeuser/plt/backup/vault/
#    • AUTO-UNSEALING: Uses recovered keys to unseal vault automatically
#    • LEGACY SUPPORT: Handles both new and old key file formats
#    • DEVELOPMENT TOKENS: Creates/verifies dev tokens for applications
#    • STATUS REPORTING: Provides comprehensive vault status summary
#
# 🔄 WORKFLOW RELATIONSHIP:
#    1. Use scsm-vault-server-setup-production.sh ONCE for initialization
#    2. Use THIS script for all daily operations and routine vault management
#
# 📦 PERSISTENCE:
#    Works with production key backup strategy - survives docker system prune
#    Leverages multiple backup locations for maximum resilience
#
# Component: SCSM Vault Server (FLA: SCSM)
# Function: smart-setup, daily-operations, key-recovery
# Updated: September 2025 for production key management integration
# Standard: Infrastructure Command Logging Standard v1.1
#################################################################################

set -e

# Source Infrastructure Command Logging Standard v1.1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/logging-standard-bash.sh"

# Initialize logging
setup_logging

VAULT_ADDR="http://localhost:8200"
KEYS_FILE="/home/beeuser/plt/infra-cnf/${ORGNM}/${PLTNM}/${ENVNM}/scsm-vault/vault-keys.json"  # Production keys location (external to git repo)
KEYS_BACKUP_DIR="/home/beeuser/plt/backup/vault"

echo "============================================================================="
echo "🔐 SCSM Vault Smart Setup - $(date)"
echo "============================================================================="
echo "Script: $0"
echo "Working Directory: $(pwd)"
echo "Log File: $LOG_FILE"
echo "User: $(whoami)"
echo "============================================================================="
echo ""

echo "🔐 SCSM Vault Smart Setup - Checking status..."
echo "📍 Vault URL: $VAULT_ADDR"
echo "🗝️  Keys Location: $KEYS_FILE"

# Check if Vault is accessible
if ! curl -s $VAULT_ADDR/v1/sys/health > /dev/null 2>&1; then
    echo "❌ SCSM Vault is not accessible at $VAULT_ADDR"
    echo "🔧 Start SCSM Vault first: docker compose -f infra/docker/docker-compose.scsm-vault.yml up -d scsm-vault"
    exit 1
fi

# Check initialization status
INIT_STATUS=$(curl -s $VAULT_ADDR/v1/sys/init)
IS_INITIALIZED=$(echo $INIT_STATUS | jq -r '.initialized')

if [ "$IS_INITIALIZED" = "false" ]; then
    echo "🆕 SCSM Vault has never been initialized - doing FIRST TIME setup..."
    
    # Ensure keys directory exists
    mkdir -p "$(dirname "$KEYS_FILE")"
    
    # Initialize Vault
    echo "🚀 Initializing SCSM Vault..."
    INIT_RESPONSE=$(curl -s -X POST -d '{"secret_shares":5,"secret_threshold":3}' $VAULT_ADDR/v1/sys/init)
    
    if [ $? -eq 0 ]; then
        # Save keys to secure location
        echo "$INIT_RESPONSE" > "$KEYS_FILE"
        chmod 600 "$KEYS_FILE"
        
        # Extract keys
        UNSEAL_KEY1=$(echo "$INIT_RESPONSE" | jq -r '.keys[0]')
        UNSEAL_KEY2=$(echo "$INIT_RESPONSE" | jq -r '.keys[1]')
        UNSEAL_KEY3=$(echo "$INIT_RESPONSE" | jq -r '.keys[2]')
        ROOT_TOKEN=$(echo "$INIT_RESPONSE" | jq -r '.root_token')
        
        echo "✅ SCSM Vault initialized for the FIRST TIME!"
        echo ""
        echo "🔑 KEYS SAVED SECURELY TO: $KEYS_FILE"
        echo "=============================================="
        echo "Root Token: $ROOT_TOKEN"
        echo "=============================================="
        
        # Auto-unseal with 3 keys
        curl -s -X POST -d "{\"key\":\"$UNSEAL_KEY1\"}" $VAULT_ADDR/v1/sys/unseal > /dev/null
        curl -s -X POST -d "{\"key\":\"$UNSEAL_KEY2\"}" $VAULT_ADDR/v1/sys/unseal > /dev/null
        curl -s -X POST -d "{\"key\":\"$UNSEAL_KEY3\"}" $VAULT_ADDR/v1/sys/unseal > /dev/null
        echo "🔓 SCSM Vault unsealed automatically"
        
    else
        echo "❌ Failed to initialize SCSM Vault"
        echo "$INIT_RESPONSE"
        exit 1
    fi
else
    echo "✅ SCSM Vault was already initialized (persistent storage working!)"
    
    # Check if keys file exists
    if [ ! -f "$KEYS_FILE" ]; then
        echo "⚠️  Keys file not found at $KEYS_FILE"
        echo "🔍 Checking for backup keys in docker volume..."
        
        # Try to restore from docker volume backup
        if docker run --rm -v scsm_vault_config:/config alpine test -f /config/vault-keys-backup.json; then
            echo "📦 Found backup keys in docker volume, restoring..."
            docker run --rm -v scsm_vault_config:/config alpine cat /config/vault-keys-backup.json > "$KEYS_FILE"
            chmod 600 "$KEYS_FILE"
            echo "✅ Keys restored from docker volume backup"
        elif [ -d "$KEYS_BACKUP_DIR" ] && [ "$(ls -A "$KEYS_BACKUP_DIR")" ]; then
            echo "📁 Checking timestamped backups in $KEYS_BACKUP_DIR..."
            LATEST_BACKUP=$(ls -t "$KEYS_BACKUP_DIR"/scsm-vault-keys-*.json 2>/dev/null | head -1)
            if [ -n "$LATEST_BACKUP" ]; then
                echo "📂 Found latest backup: $LATEST_BACKUP"
                cp "$LATEST_BACKUP" "$KEYS_FILE"
                chmod 600 "$KEYS_FILE"
                echo "✅ Keys restored from timestamped backup"
            else
                echo "❌ No backup keys found"
                echo "🔧 You may need to run the production setup script to reinitialize"
                exit 1
            fi
        else
            echo "❌ No backup keys found in any location"
            echo "🔧 You may need to run the production setup script to reinitialize"
            exit 1
        fi
    else
        # Extract keys from saved file
        UNSEAL_KEY1=$(cat "$KEYS_FILE" | jq -r '.unseal_keys_b64[0] // .keys[0]')
        UNSEAL_KEY2=$(cat "$KEYS_FILE" | jq -r '.unseal_keys_b64[1] // .keys[1]')
        UNSEAL_KEY3=$(cat "$KEYS_FILE" | jq -r '.unseal_keys_b64[2] // .keys[2]')
        ROOT_TOKEN=$(cat "$KEYS_FILE" | jq -r '.root_token')
        echo "🔑 Keys loaded from $KEYS_FILE"
    fi
fi

# Check seal status
SEAL_STATUS=$(curl -s $VAULT_ADDR/v1/sys/seal-status)
IS_SEALED=$(echo $SEAL_STATUS | jq -r '.sealed')
THRESHOLD=$(echo $SEAL_STATUS | jq -r '.t')

if [ "$IS_SEALED" = "true" ]; then
    if [ -n "$UNSEAL_KEY1" ] && [ -n "$UNSEAL_KEY2" ] && [ -n "$UNSEAL_KEY3" ]; then
        echo "🔒 SCSM Vault is sealed - unsealing automatically..."
        echo "🔍 Threshold required: $THRESHOLD keys"
        
        # Apply first unseal key and check response
        echo "🔑 Applying unseal key 1/$THRESHOLD..."
        UNSEAL_RESPONSE1=$(curl -s -X POST -d "{\"key\":\"$UNSEAL_KEY1\"}" $VAULT_ADDR/v1/sys/unseal)
        if ! echo "$UNSEAL_RESPONSE1" | jq -e '.sealed' > /dev/null 2>&1; then
            echo "❌ Failed to apply first unseal key - invalid response"
            echo "Response:"
            echo "$UNSEAL_RESPONSE1" | jq . 2>/dev/null || echo "$UNSEAL_RESPONSE1"
            exit 1
        fi
        
        # Check if vault is unsealed after first key (unlikely but possible)
        IS_SEALED_AFTER_1=$(echo "$UNSEAL_RESPONSE1" | jq -r '.sealed')
        if [ "$IS_SEALED_AFTER_1" = "false" ]; then
            echo "🔓 SCSM Vault unsealed successfully with 1 key"
        else
            # Apply second unseal key
            echo "🔑 Applying unseal key 2/$THRESHOLD..."
            UNSEAL_RESPONSE2=$(curl -s -X POST -d "{\"key\":\"$UNSEAL_KEY2\"}" $VAULT_ADDR/v1/sys/unseal)
            if ! echo "$UNSEAL_RESPONSE2" | jq -e '.sealed' > /dev/null 2>&1; then
                echo "❌ Failed to apply second unseal key - invalid response"
                echo "Response:"
                echo "$UNSEAL_RESPONSE2" | jq . 2>/dev/null || echo "$UNSEAL_RESPONSE2"
                exit 1
            fi
            
            # Check if vault is unsealed after second key
            IS_SEALED_AFTER_2=$(echo "$UNSEAL_RESPONSE2" | jq -r '.sealed')
            if [ "$IS_SEALED_AFTER_2" = "false" ]; then
                echo "🔓 SCSM Vault unsealed successfully with 2 keys"
            else
                # Only apply third key if threshold is 3 or higher AND vault is still sealed
                if [ "$THRESHOLD" -ge 3 ]; then
                    echo "🔑 Applying unseal key 3/$THRESHOLD..."
                    UNSEAL_RESPONSE3=$(curl -s -X POST -d "{\"key\":\"$UNSEAL_KEY3\"}" $VAULT_ADDR/v1/sys/unseal)
                    
                    # Check if the response is valid (either sealed or unsealed state)
                    if echo "$UNSEAL_RESPONSE3" | jq -e '.sealed' > /dev/null 2>&1; then
                        IS_SEALED_AFTER_3=$(echo "$UNSEAL_RESPONSE3" | jq -r '.sealed')
                        if [ "$IS_SEALED_AFTER_3" = "false" ]; then
                            echo "🔓 SCSM Vault unsealed successfully with 3 keys"
                        else
                            echo "❌ Vault still sealed after applying 3 keys (threshold: $THRESHOLD)"
                            echo "Response:"
                            echo "$UNSEAL_RESPONSE3" | jq . 2>/dev/null || echo "$UNSEAL_RESPONSE3"
                            exit 1
                        fi
                    else
                        # Invalid response - could be an error or vault issue
                        echo "❌ Invalid response when applying third unseal key"
                        echo "Response:"
                        echo "$UNSEAL_RESPONSE3" | jq . 2>/dev/null || echo "$UNSEAL_RESPONSE3"
                        # Check if vault might already be unsealed
                        CHECK_STATUS=$(curl -s $VAULT_ADDR/v1/sys/seal-status)
                        CHECK_SEALED=$(echo $CHECK_STATUS | jq -r '.sealed')
                        if [ "$CHECK_SEALED" = "false" ]; then
                            echo "🔓 Vault was already unsealed - third key not needed"
                        else
                            echo "❌ Vault still sealed and third key failed"
                            exit 1
                        fi
                    fi
                else
                    echo "❌ Vault still sealed after 2 keys but threshold is only $THRESHOLD"
                    echo "This shouldn't happen - check vault configuration"
                    exit 1
                fi
            fi
        fi
        
        # Final verification
        echo "🔍 Verifying vault status..."
        FINAL_STATUS=$(curl -s $VAULT_ADDR/v1/sys/seal-status)
        FINAL_SEALED=$(echo $FINAL_STATUS | jq -r '.sealed')
        if [ "$FINAL_SEALED" = "true" ]; then
            echo "❌ CRITICAL: Vault verification failed - still showing as sealed"
            echo "Status:"
            echo "$FINAL_STATUS" | jq . 2>/dev/null || echo "$FINAL_STATUS"
            exit 1
        fi
        echo "✅ Vault unsealing verified - ready for operations"
        
    else
        echo "🔒 SCSM Vault is sealed but no unseal keys available"
        echo "🔑 Please provide the unseal keys manually"
        exit 1
    fi
else
    echo "🔓 SCSM Vault is already unsealed and ready!"
fi

# One-time setup: Enable KV engine and create initial secrets (only if ROOT_TOKEN available)
if [ -n "$ROOT_TOKEN" ]; then
    echo ""
    echo "🗂️  Setting up KV secret engine and initial secrets..."
    
    # Check if KV engine is already enabled
    KV_ENABLED=$(curl -s -H "X-Vault-Token: $ROOT_TOKEN" $VAULT_ADDR/v1/sys/mounts | jq -r '.data | has("kv/")')
    
    if [ "$KV_ENABLED" = "false" ]; then
        echo "📂 Enabling KV v2 secret engine at kv/..."
        curl -s -H "X-Vault-Token: $ROOT_TOKEN" -X POST \
            -d '{"type":"kv","options":{"version":"2"}}' \
            $VAULT_ADDR/v1/sys/mounts/kv > /dev/null
        echo "✅ KV engine enabled"
        
        # Create initial secrets for SCSM agents
        echo "🔧 Creating initial secrets for SCSM services..."
        
        # PostgreSQL secrets
        curl -s -H "X-Vault-Token: $ROOT_TOKEN" -X POST \
            -d '{"data":{"POSTGRES_USER":"app_user","POSTGRES_PASSWORD":"app_user_secure_pass_2025","POSTGRES_DB":"beeux_main"}}' \
            $VAULT_ADDR/v1/kv/data/beeux/postgres/cluster > /dev/null
            
        curl -s -H "X-Vault-Token: $ROOT_TOKEN" -X POST \
            -d '{"data":{"PGPOOL_USER":"pgpool_user","PGPOOL_PASSWORD":"pgpool_secure_2025","PGPOOL_ENABLE_POOL_HBA":"yes"}}' \
            $VAULT_ADDR/v1/kv/data/beeux/postgres/pgpool > /dev/null
            
        # Redis secrets  
        curl -s -H "X-Vault-Token: $ROOT_TOKEN" -X POST \
            -d '{"data":{"REDIS_PASSWORD":"redis_secure_pass_2025","REDIS_MAXMEMORY":"256mb"}}' \
            $VAULT_ADDR/v1/kv/data/beeux/redis > /dev/null
            
        # Redis Commander (Web UI) secrets
        curl -s -H "X-Vault-Token: $ROOT_TOKEN" -X POST \
            -d '{"data":{"REDIS_COMMANDER_USER":"redis_admin","REDIS_COMMANDER_PASSWORD":"redis_web_secure_2025","HTTP_USER":"redis_web","HTTP_PASSWORD":"redis_http_2025"}}' \
            $VAULT_ADDR/v1/kv/data/beeux/redis-commander > /dev/null
            
        # Config Server secrets
        curl -s -H "X-Vault-Token: $ROOT_TOKEN" -X POST \
            -d '{"data":{"CONFIG_SERVER_USERNAME":"config_admin","CONFIG_SERVER_PASSWORD":"config_secure_2025","GIT_URI":"https://github.com/beeux/spring-config-repo.git"}}' \
            $VAULT_ADDR/v1/kv/data/beeux/config-server > /dev/null
            
        # Config Server Security secrets
        curl -s -H "X-Vault-Token: $ROOT_TOKEN" -X POST \
            -d '{"data":{"ENCRYPT_KEY":"AES256_config_encrypt_key_2025","JWT_SIGNING_KEY":"jwt_config_server_signing_key_2025","OAUTH_CLIENT_SECRET":"oauth_config_client_secret_2025"}}' \
            $VAULT_ADDR/v1/kv/data/beeux/config-server/security > /dev/null
            
        # Config Server Authentication secrets  
        curl -s -H "X-Vault-Token: $ROOT_TOKEN" -X POST \
            -d '{"data":{"BASIC_AUTH_USER":"config_user","BASIC_AUTH_PASSWORD":"config_basic_auth_2025","LDAP_USER":"config_ldap","LDAP_PASSWORD":"config_ldap_pass_2025"}}' \
            $VAULT_ADDR/v1/kv/data/beeux/config-server/auth > /dev/null
            
        # Config Server Vault Integration secrets
        curl -s -H "X-Vault-Token: $ROOT_TOKEN" -X POST \
            -d '{"data":{"VAULT_TOKEN":"scsm-vault-dev-token","VAULT_SCHEME":"http","VAULT_HOST":"scsm-vault","VAULT_PORT":"8200","VAULT_KV_VERSION":"2"}}' \
            $VAULT_ADDR/v1/kv/data/beeux/config-server/vault > /dev/null
            
        # Monitoring secrets
        curl -s -H "X-Vault-Token: $ROOT_TOKEN" -X POST \
            -d '{"data":{"GRAFANA_ADMIN_PASSWORD":"grafana_secure_2025","PROMETHEUS_USER":"prometheus","PROMETHEUS_PASSWORD":"prom_secure_2025"}}' \
            $VAULT_ADDR/v1/kv/data/beeux/monitoring > /dev/null
            
        echo "✅ Initial secrets created for all SCSM services"
    else
        echo "✅ KV engine already enabled with existing secrets"
    fi
fi

# Create development token for applications
if [ -n "$ROOT_TOKEN" ]; then
    echo ""
    echo "🔧 Setting up development token for SCSM applications..."
    
    # Create dev policy if it doesn't exist
    echo "📋 Creating/updating development policy..."
    DEV_POLICY='
# Development Policy for scsm-vault-dev-token
# Allows read access to all KV secrets for development/testing

path "kv/data/beeux/*" {
  capabilities = ["read"]
}

path "kv/metadata/beeux/*" {
  capabilities = ["read"]
}

# Allow token self-renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow token self-lookup
path "auth/token/lookup-self" {
  capabilities = ["read"]
}'

    # Write the policy to Vault
    echo "📝 Writing development policy to Vault..."
    POLICY_RESPONSE=$(echo "$DEV_POLICY" | docker exec -i -e VAULT_TOKEN="$ROOT_TOKEN" scsm-vault vault policy write scsm-dev - 2>&1)
    POLICY_EXIT_CODE=$?
    
    if [ $POLICY_EXIT_CODE -eq 0 ] && echo "$POLICY_RESPONSE" | grep -q "Success"; then
        echo "✅ Development policy created/updated successfully"
    else
        echo "❌ Policy creation failed (exit code: $POLICY_EXIT_CODE)"
        echo "Response: $POLICY_RESPONSE"
        echo "🔍 Checking if Vault is accessible..."
        
        # Test basic vault status via docker exec
        VAULT_STATUS_TEST=$(docker exec scsm-vault vault status 2>&1)
        VAULT_STATUS_EXIT=$?
        if [ $VAULT_STATUS_EXIT -ne 0 ]; then
            echo "❌ Vault not accessible via docker exec"
            echo "Status test output: $VAULT_STATUS_TEST"
            exit 1
        else
            echo "✅ Vault is accessible, but policy creation failed"
            echo "This may be due to token permissions or vault configuration"
            exit 1
        fi
    fi
    
    # Create/recreate development token with scsm-dev policy
    echo "🔧 Creating/updating development token with scsm-dev policy..."
    
    # First, try to revoke the existing token if it exists (ignore errors)
    curl -s -H "X-Vault-Token: $ROOT_TOKEN" -X POST \
        -d '{"token":"scsm-vault-dev-token"}' \
        $VAULT_ADDR/v1/auth/token/revoke > /dev/null 2>&1 || true
    
    # Now create the token (should work whether it existed or not)
    DEV_TOKEN_RESPONSE=$(curl -s -H "X-Vault-Token: $ROOT_TOKEN" -X POST \
        -d '{"id":"scsm-vault-dev-token","renewable":true,"ttl":"168h","policies":["scsm-dev"]}' \
        $VAULT_ADDR/v1/auth/token/create)
    
    # Check if token creation was successful
    DEV_TOKEN_EXISTS=false
    if echo "$DEV_TOKEN_RESPONSE" | jq -e '.auth.client_token' > /dev/null 2>&1; then
        echo "✅ Development token created/updated successfully"
        
        # Verify the token actually works by testing secret access
        if curl -s -H "X-Vault-Token: scsm-vault-dev-token" $VAULT_ADDR/v1/kv/data/beeux/database > /dev/null 2>&1; then
            DEV_TOKEN_EXISTS=true
            echo "✅ Development token verified - secret access working"
        else
            echo "⚠️  Development token created but secret access test failed"
            echo "⚠️  This may be due to missing secrets or policy issues"
        fi
    else
        echo "⚠️  Development token creation failed"
        echo "Response: $DEV_TOKEN_RESPONSE"
    fi
fi

# Final status
echo ""
echo "🎯 SCSM Vault Status Summary:"
echo "========================"
echo "Initialized: $IS_INITIALIZED"
echo "Sealed: $(curl -s $VAULT_ADDR/v1/sys/seal-status | jq -r '.sealed')"
echo "Dev Token: $([ "$DEV_TOKEN_EXISTS" = "true" ] && echo "✅ Ready" || echo "⚠️  Check needed")"
echo "Ready for use: ✅"

if [ -n "$ROOT_TOKEN" ]; then
    echo ""
    echo "🚀 Ready to use SCSM Vault!"
    echo "💡 Root token: export VAULT_TOKEN=$ROOT_TOKEN"
    echo "🔧 Dev token:  scsm-vault-dev-token (for applications)"
    echo "🔧 Or use: export VAULT_ADDR=$VAULT_ADDR && vault auth -method=token token=$ROOT_TOKEN"
    echo "🗝️  Keys stored: $KEYS_FILE"
fi

echo ""
echo "💾 Remember: Your data persists in Docker volumes - no more repeated setup!"

# Script execution tracking is handled automatically by the standardized logging module
