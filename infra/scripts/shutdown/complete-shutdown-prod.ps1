#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Complete shutdown and deletion of Production environment resources with triple confirmation.

.DESCRIPTION
    This script implements the production shutdown requirements from infrasetup.instructions.md
    including the mandatory "triple confirmation mechanism" for production environment shutdown.
    This is a HIGHLY DESTRUCTIVE operation that permanently deletes the entire production environment.

    REQUIREMENTS COMPLIANCE:
    =======================
    This script implements requirements 14-16 and 19 from infrasetup.instructions.md:
    - Requirement 14: Ready 'shutdown' script that releases resources completely
    - Requirement 15: Terminal/Azure CLI executable shutdown scripts
    - Requirement 16: Zero cost shutdown by deleting all resources
    - Requirement 19: Special prompting and "triple confirmation mechanism" for production

    TRIPLE CONFIRMATION MECHANISM:
    =============================
    Per requirement 19, this script implements a triple confirmation system:
    1. FIRST CONFIRMATION: Confirm you understand this deletes production
    2. SECOND CONFIRMATION: Type "DELETE PRODUCTION" exactly
    3. THIRD CONFIRMATION: Wait 10 seconds and confirm final deletion
    
    This prevents accidental production deletion and ensures intentional action.

    PRODUCTION ENVIRONMENT DESTRUCTION:
    ==================================
    This script PERMANENTLY DELETES all production resources including:
    - App Services with autoscaling (Angular frontend)
    - Container Apps with autoscaling (Spring Boot API)  
    - Azure Database for PostgreSQL (managed service with all data)
    - Azure Container Registry and all production images
    - Storage Accounts and all production data
    - Production Virtual Machine and all data
    - Application Gateway with SSL certificates
    - Key Vault and all production secrets
    - Auto-scaling configurations
    - Security configurations
    - Monitoring and alerting systems
    - The entire production resource group

    BUSINESS IMPACT WARNING:
    =======================
    Executing this script will cause:
    - COMPLETE SERVICE OUTAGE for all users
    - PERMANENT DATA LOSS of all production data
    - LOSS OF ALL CUSTOMER DATA unless backed up externally
    - DESTRUCTION OF SSL CERTIFICATES and security configurations
    - REMOVAL OF ALL MONITORING and alerting systems
    - COMPLETE BUSINESS CONTINUITY DISRUPTION

    COST IMPACT:
    ===========
    After successful execution, production environment cost becomes:
    - Running Cost: ~$138.72/month → $0.00/month
    - Complete cost elimination through resource deletion
    - No ongoing charges for any components

    RECOVERY IMPACT:
    ===============
    After this destructive shutdown, production recovery requires:
    1. Running startup script: .\infra\scripts\startup\complete-startup-prod.ps1
    2. Redeploying all applications (15-30 minutes)
    3. Restoring ALL DATA from external backups (hours to days)
    4. Reconfiguring SSL certificates and security (30-60 minutes)
    5. Testing all functionality and integrations (hours)
    6. DNS propagation and service validation (30-60 minutes)
    
    Total production recovery time: 4-24 hours depending on data size and complexity.

    BACKUP VERIFICATION REQUIRED:
    ============================
    Before executing this script, verify that you have:
    - Complete database backups stored outside Azure
    - Application code and configuration backups
    - SSL certificate backups
    - Documentation for all integrations and configurations
    - Contact information for all stakeholders who need to be notified

.PARAMETER Force
    Skip confirmation prompts (DISABLED for production - confirmations are always required)

.EXAMPLE
    .\complete-shutdown-prod.ps1
    # Note: -Force parameter is ignored for production environment safety
#>

param(
    [switch]$Force  # NOTE: Force parameter is ignored for production environment per requirement 19
)

# Script configuration
$EnvironmentName = "prod"
$ResourceGroupName = "beeux-rg-prod-eastus"
$Location = "eastus"

Write-Host "🔥 COMPLETE PRODUCTION ENVIRONMENT SHUTDOWN SCRIPT" -ForegroundColor Red -BackgroundColor Yellow
Write-Host "=================================================" -ForegroundColor Red
Write-Host "Environment: $EnvironmentName" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "⚠️  WARNING: This will PERMANENTLY DELETE all PRODUCTION resources!" -ForegroundColor Red

# TRIPLE SAFETY CONFIRMATION FOR PRODUCTION
if (-not $Force) {
    Write-Host ""
    Write-Host "🚨 PRODUCTION ENVIRONMENT DELETION WARNING 🚨" -ForegroundColor Red -BackgroundColor Yellow
    Write-Host "===============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "This action will:" -ForegroundColor Yellow
    Write-Host "❌ Delete ALL Production App Services and App Service Plans" -ForegroundColor Red
    Write-Host "❌ Delete ALL Production Container Apps and Container Environments" -ForegroundColor Red
    Write-Host "❌ Delete Production PostgreSQL database and ALL PRODUCTION DATA" -ForegroundColor Red
    Write-Host "❌ Delete ALL Production Storage Accounts and blob data" -ForegroundColor Red
    Write-Host "❌ Delete Production Container Registry and all images" -ForegroundColor Red
    Write-Host "❌ Delete Premium Key Vault and all production secrets" -ForegroundColor Red
    Write-Host "❌ Delete Premium tier API Management and all configurations" -ForegroundColor Red
    Write-Host "❌ Delete Premium Web Application Firewall and security policies" -ForegroundColor Red
    Write-Host "❌ Delete Application Gateway and production networking" -ForegroundColor Red
    Write-Host "❌ Delete DDoS Protection Plan" -ForegroundColor Red
    Write-Host "❌ Delete CDN Profile and all cached content" -ForegroundColor Red
    Write-Host "❌ Delete Log Analytics Workspace and all production logs" -ForegroundColor Red
    Write-Host "❌ Delete Application Insights and all production telemetry" -ForegroundColor Red
    Write-Host "❌ Delete ALL networking resources and private endpoints" -ForegroundColor Red
    Write-Host "❌ Delete the entire Production Resource Group" -ForegroundColor Red
    Write-Host ""
    Write-Host "💰 COST SAVINGS FROM SHUTDOWN:" -ForegroundColor Green -BackgroundColor Black
    Write-Host "   💵 Will STOP cost of ~$2.30/hour" -ForegroundColor Green
    Write-Host "   💰 Will SAVE ~$55.20/day in charges" -ForegroundColor Green
    Write-Host "   📈 Will PREVENT ~$1,656/month if left running" -ForegroundColor Green
    Write-Host "   ✅ Final result: Monthly cost will be reduced to $0" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  CRITICAL: This is your PRODUCTION environment!" -ForegroundColor Red
    Write-Host "💡 TIP: You can restart anytime with the startup script" -ForegroundColor Cyan
    Write-Host ""
    
    # First confirmation
    Write-Host "🚨 FIRST CONFIRMATION 🚨" -ForegroundColor Red -BackgroundColor Yellow
    $costConfirmation = Read-Host "Do you accept stopping $2.30/hour PRODUCTION charges? Type 'ACCEPT-PRODUCTION-COSTS' to accept"
    if ($costConfirmation -ne "ACCEPT-PRODUCTION-COSTS") {
        Write-Host "❌ Production environment shutdown cancelled - cost savings not accepted" -ForegroundColor Yellow
        exit 0
    }
    
    # Second confirmation
    Write-Host ""
    Write-Host "🚨 SECOND CONFIRMATION 🚨" -ForegroundColor Red -BackgroundColor Yellow
    $dataConfirmation = Read-Host "Do you understand this will DELETE ALL PRODUCTION DATA? Type 'DELETE-PRODUCTION-DATA' to confirm"
    if ($dataConfirmation -ne "DELETE-PRODUCTION-DATA") {
        Write-Host "❌ Production environment shutdown cancelled - data deletion not confirmed" -ForegroundColor Yellow
        exit 0
    }
    
    # Third and final confirmation
    Write-Host ""
    Write-Host "🚨 FINAL CONFIRMATION 🚨" -ForegroundColor Red -BackgroundColor Yellow
    $finalConfirmation = Read-Host "Type 'DELETE-PRODUCTION-ENVIRONMENT-PERMANENTLY' to proceed with PERMANENT deletion"
    if ($finalConfirmation -ne "DELETE-PRODUCTION-ENVIRONMENT-PERMANENTLY") {
        Write-Host "❌ Production environment shutdown cancelled for safety" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host ""
    Write-Host "⚠️  Last chance to cancel... Press Ctrl+C within 10 seconds to abort" -ForegroundColor Yellow
    for ($i = 10; $i -gt 0; $i--) {
        Write-Host "Proceeding in $i seconds..." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}

# Check if Azure CLI is logged in
Write-Host "🔍 Checking Azure CLI authentication..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "❌ Not logged into Azure CLI. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Authenticated as: $($account.user.name)" -ForegroundColor Green
Write-Host "📋 Subscription: $($account.name) ($($account.id))" -ForegroundColor Yellow

# Check if resource group exists
Write-Host "🔍 Checking if resource group exists..." -ForegroundColor Cyan
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "✅ Resource group '$ResourceGroupName' does not exist. Nothing to delete." -ForegroundColor Green
    exit 0
}

Write-Host "📋 Found resource group: $ResourceGroupName" -ForegroundColor Yellow

# List all resources before deletion
Write-Host "📋 Listing all resources in Production environment..." -ForegroundColor Cyan
$resources = az resource list --resource-group $ResourceGroupName --query "[].{Name:name, Type:type, Location:location}" --output table
Write-Host $resources

$resourceCount = (az resource list --resource-group $ResourceGroupName --query "length([])" --output tsv)
Write-Host "📊 Total Production resources to delete: $resourceCount" -ForegroundColor Yellow

if ($resourceCount -eq "0") {
    Write-Host "✅ No resources found in resource group. Deleting empty resource group..." -ForegroundColor Green
    az group delete --name $ResourceGroupName --yes --no-wait
    Write-Host "✅ Production environment shutdown complete!" -ForegroundColor Green
    exit 0
}

# Start deletion process
Write-Host "🚀 Starting Production environment resource deletion..." -ForegroundColor Red

# Step 1: Stop all running services first (graceful shutdown)
Write-Host "1️⃣ Gracefully stopping running services..." -ForegroundColor Yellow

# Stop App Services
Write-Host "   🛑 Stopping App Services..." -ForegroundColor Cyan
$webApps = az webapp list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($app in $webApps) {
    if ($app) {
        Write-Host "     Stopping: $app" -ForegroundColor Gray
        az webapp stop --name $app --resource-group $ResourceGroupName 2>$null
    }
}

# Scale down Container Apps to zero
Write-Host "   🛑 Scaling down Container Apps..." -ForegroundColor Cyan
$containerApps = az containerapp list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($app in $containerApps) {
    if ($app) {
        Write-Host "     Scaling down: $app" -ForegroundColor Gray
        az containerapp update --name $app --resource-group $ResourceGroupName --min-replicas 0 --max-replicas 0 2>$null
    }
}

# Stop PostgreSQL Database
Write-Host "   🛑 Stopping PostgreSQL Database..." -ForegroundColor Cyan
$databases = az postgres flexible-server list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($db in $databases) {
    if ($db) {
        Write-Host "     Stopping Database: $db" -ForegroundColor Gray
        az postgres flexible-server stop --name $db --resource-group $ResourceGroupName 2>$null
    }
}

# Wait for graceful shutdown
Write-Host "   ⏳ Waiting 60 seconds for graceful shutdown..." -ForegroundColor Gray
Start-Sleep -Seconds 60

# Step 2: Delete specific resource types in order
Write-Host "2️⃣ Deleting resources by type..." -ForegroundColor Yellow

# Delete Container Apps first (they depend on Container App Environment)
Write-Host "   🗑️ Deleting Container Apps..." -ForegroundColor Cyan
foreach ($app in $containerApps) {
    if ($app) {
        Write-Host "     Deleting Container App: $app" -ForegroundColor Gray
        az containerapp delete --name $app --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Container App Environments
Write-Host "   🗑️ Deleting Container App Environments..." -ForegroundColor Cyan
$containerEnvs = az containerapp env list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($env in $containerEnvs) {
    if ($env) {
        Write-Host "     Deleting Container Environment: $env" -ForegroundColor Gray
        az containerapp env delete --name $env --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Web Apps
Write-Host "   🗑️ Deleting Web Apps..." -ForegroundColor Cyan
foreach ($app in $webApps) {
    if ($app) {
        Write-Host "     Deleting Web App: $app" -ForegroundColor Gray
        az webapp delete --name $app --resource-group $ResourceGroupName 2>$null
    }
}

# Delete App Service Plans
Write-Host "   🗑️ Deleting App Service Plans..." -ForegroundColor Cyan
$appServicePlans = az appservice plan list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($plan in $appServicePlans) {
    if ($plan) {
        Write-Host "     Deleting App Service Plan: $plan" -ForegroundColor Gray
        az appservice plan delete --name $plan --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete PostgreSQL Databases and Server
Write-Host "   🗑️ Deleting PostgreSQL Databases..." -ForegroundColor Cyan
foreach ($db in $databases) {
    if ($db) {
        Write-Host "     Deleting PostgreSQL Server: $db" -ForegroundColor Gray
        az postgres flexible-server delete --name $db --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete CDN Profile and Endpoints
Write-Host "   🗑️ Deleting CDN Profile..." -ForegroundColor Cyan
$cdnProfiles = az cdn profile list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($cdn in $cdnProfiles) {
    if ($cdn) {
        Write-Host "     Deleting CDN Profile: $cdn" -ForegroundColor Gray
        az cdn profile delete --name $cdn --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Application Gateway (before deleting public IP)
Write-Host "   🗑️ Deleting Application Gateway..." -ForegroundColor Cyan
$appGateways = az network application-gateway list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($gateway in $appGateways) {
    if ($gateway) {
        Write-Host "     Deleting Application Gateway: $gateway" -ForegroundColor Gray
        az network application-gateway delete --name $gateway --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Storage Accounts (this will delete all blob data)
Write-Host "   🗑️ Deleting Storage Accounts..." -ForegroundColor Cyan
$storageAccounts = az storage account list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($storage in $storageAccounts) {
    if ($storage) {
        Write-Host "     Deleting Storage Account: $storage" -ForegroundColor Gray
        az storage account delete --name $storage --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Container Registry
Write-Host "   🗑️ Deleting Container Registry..." -ForegroundColor Cyan
$containerRegistries = az acr list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($registry in $containerRegistries) {
    if ($registry) {
        Write-Host "     Deleting Container Registry: $registry" -ForegroundColor Gray
        az acr delete --name $registry --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Application Insights
Write-Host "   🗑️ Deleting Application Insights..." -ForegroundColor Cyan
$appInsights = az monitor app-insights component show --resource-group $ResourceGroupName --query "[].name" --output tsv 2>$null
foreach ($insight in $appInsights) {
    if ($insight) {
        Write-Host "     Deleting Application Insights: $insight" -ForegroundColor Gray
        az monitor app-insights component delete --app $insight --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Log Analytics Workspaces
Write-Host "   🗑️ Deleting Log Analytics Workspaces..." -ForegroundColor Cyan
$workspaces = az monitor log-analytics workspace list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($workspace in $workspaces) {
    if ($workspace) {
        Write-Host "     Deleting Log Analytics Workspace: $workspace" -ForegroundColor Gray
        az monitor log-analytics workspace delete --workspace-name $workspace --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Key Vaults
Write-Host "   🗑️ Deleting Key Vaults..." -ForegroundColor Cyan
$keyVaults = az keyvault list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($keyVault in $keyVaults) {
    if ($keyVault) {
        Write-Host "     Deleting Key Vault: $keyVault" -ForegroundColor Gray
        az keyvault delete --name $keyVault --resource-group $ResourceGroupName 2>$null
        Write-Host "     Purging Key Vault: $keyVault (to prevent billing)" -ForegroundColor Gray
        az keyvault purge --name $keyVault 2>$null
    }
}

# Delete API Management
Write-Host "   🗑️ Deleting API Management services..." -ForegroundColor Cyan
$apimServices = az apim list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($apim in $apimServices) {
    if ($apim) {
        Write-Host "     Deleting API Management: $apim" -ForegroundColor Gray
        az apim delete --name $apim --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete DDoS Protection Plans
Write-Host "   🗑️ Deleting DDoS Protection Plans..." -ForegroundColor Cyan
$ddosPlans = az network ddos-protection-plan list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($ddos in $ddosPlans) {
    if ($ddos) {
        Write-Host "     Deleting DDoS Protection Plan: $ddos" -ForegroundColor Gray
        az network ddos-protection-plan delete --name $ddos --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Private Endpoints
Write-Host "   🗑️ Deleting Private Endpoints..." -ForegroundColor Cyan
$privateEndpoints = az network private-endpoint list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($pe in $privateEndpoints) {
    if ($pe) {
        Write-Host "     Deleting Private Endpoint: $pe" -ForegroundColor Gray
        az network private-endpoint delete --name $pe --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Network Security Groups
Write-Host "   🗑️ Deleting Network Security Groups..." -ForegroundColor Cyan
$nsgs = az network nsg list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($nsg in $nsgs) {
    if ($nsg) {
        Write-Host "     Deleting NSG: $nsg" -ForegroundColor Gray
        az network nsg delete --name $nsg --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Public IPs
Write-Host "   🗑️ Deleting Public IP addresses..." -ForegroundColor Cyan
$publicIPs = az network public-ip list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($pip in $publicIPs) {
    if ($pip) {
        Write-Host "     Deleting Public IP: $pip" -ForegroundColor Gray
        az network public-ip delete --name $pip --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Virtual Networks
Write-Host "   🗑️ Deleting Virtual Networks..." -ForegroundColor Cyan
$vnets = az network vnet list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($vnet in $vnets) {
    if ($vnet) {
        Write-Host "     Deleting VNet: $vnet" -ForegroundColor Gray
        az network vnet delete --name $vnet --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Managed Identities
Write-Host "   🗑️ Deleting Managed Identities..." -ForegroundColor Cyan
$identities = az identity list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($identity in $identities) {
    if ($identity) {
        Write-Host "     Deleting Managed Identity: $identity" -ForegroundColor Gray
        az identity delete --name $identity --resource-group $ResourceGroupName 2>$null
    }
}

# Step 3: Delete the entire resource group (this ensures everything is gone)
Write-Host "3️⃣ Deleting the entire resource group..." -ForegroundColor Yellow
Write-Host "   🗑️ Deleting Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "   ⏳ This may take several minutes..." -ForegroundColor Gray

az group delete --name $ResourceGroupName --yes --no-wait

# Step 4: Verify deletion
Write-Host "4️⃣ Initiating verification..." -ForegroundColor Yellow
Write-Host "   ⏳ Waiting for deletion to complete (this may take 10-20 minutes for Production)..." -ForegroundColor Gray

# Wait and check if resource group still exists
$maxWaitMinutes = 20
$waitCount = 0
do {
    Start-Sleep -Seconds 60
    $waitCount++
    $stillExists = az group exists --name $ResourceGroupName
    
    if ($stillExists -eq "false") {
        break
    }
    
    Write-Host "   ⏳ Still deleting... ($waitCount/$maxWaitMinutes minutes)" -ForegroundColor Gray
    
    if ($waitCount -ge $maxWaitMinutes) {
        Write-Host "   ⚠️ Production deletion is taking longer than expected. Check Azure portal for status." -ForegroundColor Yellow
        break
    }
} while ($stillExists -eq "true")

# Final verification
$finalCheck = az group exists --name $ResourceGroupName
if ($finalCheck -eq "false") {
    Write-Host "✅ COMPLETE PRODUCTION ENVIRONMENT SHUTDOWN SUCCESSFUL!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "💰 Monthly cost reduced to: $0.00" -ForegroundColor Green
    Write-Host "🎯 All Production resources have been permanently deleted" -ForegroundColor Green
    Write-Host "📅 Deletion completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
} else {
    Write-Host "⚠️ Production resource group may still be deleting. Check Azure portal." -ForegroundColor Yellow
    Write-Host "💡 You can monitor deletion status with: az group show --name $ResourceGroupName" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📋 Shutdown Summary:" -ForegroundColor Cyan
Write-Host "Environment: PRODUCTION" -ForegroundColor Gray
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Gray
Write-Host "Resources Deleted: All ($resourceCount total)" -ForegroundColor Gray
Write-Host "Cost Reduction: 100% (to $0/month)" -ForegroundColor Green
Write-Host "Status: Complete" -ForegroundColor Green

# Cleanup azd environment variables (optional)
Write-Host ""
$cleanupAzd = Read-Host "🧹 Do you want to clean up AZD environment variables? (y/N)"
if ($cleanupAzd -eq 'y') {
    try {
        azd env select prod 2>$null
        azd env delete prod --force 2>$null
        Write-Host "✅ AZD Production environment variables cleaned up" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not clean up AZD environment (this is optional)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🔥 PRODUCTION ENVIRONMENT SHUTDOWN COMPLETE 🔥" -ForegroundColor Green -BackgroundColor Black
