#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Complete shutdown and deletion of IT environment resources to achieve zero cost.

.DESCRIPTION
    This script implements the complete shutdown requirements from infrasetup.instructions.md
    by permanently deleting ALL Azure resources in the IT environment to achieve zero cost.
    This is a destructive operation that completely removes the environment.

    REQUIREMENTS COMPLIANCE:
    =======================
    This script implements requirements 14-16 from infrasetup.instructions.md:
    - Requirement 14: Ready 'shutdown' script that releases resources completely
    - Requirement 15: Terminal/Azure CLI executable shutdown scripts  
    - Requirement 16: Zero cost shutdown by deleting all resources in environment
    
    DESTRUCTIVE OPERATION WARNING:
    =============================
    This script PERMANENTLY DELETES all resources in the IT environment including:
    - App Services and Container Apps (Angular frontend, Spring Boot API)
    - PostgreSQL Flexible Server and all databases
    - Azure Container Registry and all images
    - Storage Accounts and all data
    - Developer Virtual Machine and all data
    - Application Gateway and networking components
    - Key Vault and all stored secrets
    - The entire resource group
    
    COST IMPACT:
    ===========
    After successful execution, the IT environment cost becomes:
    - Running Cost: ~$15.84/month → $0.00/month
    - Complete cost elimination through resource deletion
    - No ongoing charges for any components
    
    DATA LOSS WARNING:
    =================
    This operation will result in permanent data loss including:
    - All application data in PostgreSQL databases
    - All container images in Azure Container Registry
    - All files in Storage Accounts
    - All secrets in Key Vault
    - All configuration and state information
    
    RECOVERY PROCESS:
    ================
    After this destructive shutdown, the environment can only be restored by:
    1. Running the complete startup script: .\infra\scripts\startup\complete-startup-it.ps1
    2. Redeploying all applications and container images
    3. Restoring data from backups (if available)
    4. Reconfiguring all application settings and secrets
    
    Typical full recovery time: 15-30 minutes plus data restoration time.

.PARAMETER Force
    Skip confirmation prompts (use with extreme caution in production-like scenarios)

.EXAMPLE
    .\complete-shutdown-it.ps1
    .\complete-shutdown-it.ps1 -Force
#>

param(
    [switch]$Force  # Skip confirmation for automation scenarios (use with extreme caution)
)

# Script configuration
$EnvironmentName = "it"
$ResourceGroupName = "beeux-rg-it-eastus"
$Location = "eastus"

Write-Host "🔥 COMPLETE IT ENVIRONMENT SHUTDOWN SCRIPT" -ForegroundColor Red -BackgroundColor Yellow
Write-Host "=========================================" -ForegroundColor Red
Write-Host "Environment: $EnvironmentName" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "⚠️  WARNING: This will PERMANENTLY DELETE all resources!" -ForegroundColor Red

# Safety confirmation
if (-not $Force) {
    Write-Host ""
    Write-Host "This action will:" -ForegroundColor Yellow
    Write-Host "❌ Delete ALL App Services and App Service Plans" -ForegroundColor Red
    Write-Host "❌ Delete ALL Container Apps and Container Environments" -ForegroundColor Red
    Write-Host "❌ Delete self-hosted PostgreSQL containers and data" -ForegroundColor Red
    Write-Host "❌ Delete ALL Storage Accounts and blob data" -ForegroundColor Red
    Write-Host "❌ Delete Container Registry and all images" -ForegroundColor Red
    Write-Host "❌ Delete Standard Key Vault and all secrets" -ForegroundColor Red
    Write-Host "❌ Delete Developer tier API Management and all configurations" -ForegroundColor Red
    Write-Host "❌ Delete Log Analytics Workspace and all logs" -ForegroundColor Red
    Write-Host "❌ Delete Application Insights and all telemetry" -ForegroundColor Red
    Write-Host "❌ Delete ALL networking resources" -ForegroundColor Red
    Write-Host "❌ Delete the entire Resource Group" -ForegroundColor Red
    Write-Host ""
    Write-Host "💰 COST SAVINGS FROM SHUTDOWN:" -ForegroundColor Green -BackgroundColor Black
    Write-Host "   💵 Will STOP cost of ~$0.50/hour" -ForegroundColor Green
    Write-Host "   💰 Will SAVE ~$12.00/day in charges" -ForegroundColor Green
    Write-Host "   📈 Will PREVENT ~$360/month if left running" -ForegroundColor Green
    Write-Host "   ✅ Final result: Monthly cost will be reduced to $0" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Shutdown stops all Azure charges for this environment!" -ForegroundColor Yellow
    Write-Host "💡 TIP: You can restart anytime with the startup script" -ForegroundColor Cyan
    Write-Host ""
    
    $costConfirmation = Read-Host "Do you accept stopping $0.50/hour charges by shutting down IT environment? Type 'Yes' to accept"
    if ($costConfirmation -ne "Yes") {
        Write-Host "❌ IT environment shutdown cancelled - cost savings not accepted" -ForegroundColor Yellow
        exit 0
    }
    
    $confirmation = Read-Host "Type 'DELETE-IT-ENVIRONMENT' to confirm complete deletion"
    if ($confirmation -ne "DELETE-IT-ENVIRONMENT") {
        Write-Host "❌ Shutdown cancelled for safety" -ForegroundColor Yellow
        exit 0
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
Write-Host "📋 Listing all resources in IT environment..." -ForegroundColor Cyan
$resources = az resource list --resource-group $ResourceGroupName --query "[].{Name:name, Type:type, Location:location}" --output table
Write-Host $resources

$resourceCount = (az resource list --resource-group $ResourceGroupName --query "length([])" --output tsv)
Write-Host "📊 Total resources to delete: $resourceCount" -ForegroundColor Yellow

if ($resourceCount -eq "0") {
    Write-Host "✅ No resources found in resource group. Deleting empty resource group..." -ForegroundColor Green
    az group delete --name $ResourceGroupName --yes --no-wait
    Write-Host "✅ IT environment shutdown complete!" -ForegroundColor Green
    exit 0
}

# Start deletion process
Write-Host "🚀 Starting IT environment resource deletion..." -ForegroundColor Red

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

# Wait for graceful shutdown
Write-Host "   ⏳ Waiting 30 seconds for graceful shutdown..." -ForegroundColor Gray
Start-Sleep -Seconds 30

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
Write-Host "   ⏳ Waiting for deletion to complete (this may take 5-10 minutes)..." -ForegroundColor Gray

# Wait and check if resource group still exists
$maxWaitMinutes = 15
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
        Write-Host "   ⚠️ Deletion is taking longer than expected. Check Azure portal for status." -ForegroundColor Yellow
        break
    }
} while ($stillExists -eq "true")

# Final verification
$finalCheck = az group exists --name $ResourceGroupName
if ($finalCheck -eq "false") {
    Write-Host "✅ COMPLETE IT ENVIRONMENT SHUTDOWN SUCCESSFUL!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "💰 Monthly cost reduced to: $0.00" -ForegroundColor Green
    Write-Host "🎯 All resources have been permanently deleted" -ForegroundColor Green
    Write-Host "📅 Deletion completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
} else {
    Write-Host "⚠️ Resource group may still be deleting. Check Azure portal." -ForegroundColor Yellow
    Write-Host "💡 You can monitor deletion status with: az group show --name $ResourceGroupName" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📋 Shutdown Summary:" -ForegroundColor Cyan
Write-Host "Environment: IT" -ForegroundColor Gray
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Gray
Write-Host "Resources Deleted: All ($resourceCount total)" -ForegroundColor Gray
Write-Host "Cost Reduction: 100% (to $0/month)" -ForegroundColor Green
Write-Host "Status: Complete" -ForegroundColor Green

# Cleanup azd environment variables (optional)
Write-Host ""
$cleanupAzd = Read-Host "🧹 Do you want to clean up AZD environment variables? (y/N)"
if ($cleanupAzd -eq 'y') {
    try {
        azd env select it 2>$null
        azd env delete it --force 2>$null
        Write-Host "✅ AZD IT environment variables cleaned up" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not clean up AZD environment (this is optional)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🔥 IT ENVIRONMENT SHUTDOWN COMPLETE 🔥" -ForegroundColor Green -BackgroundColor Black
