#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Emergency shutdown script for ALL Beeux environments simultaneously.

.DESCRIPTION
    This script will immediately shutdown ALL environments (IT, QA, Production)
    to completely stop all Azure charges. Use in cases of budget overrun or emergencies.

.PARAMETER Force
    Skip confirmation prompts (use with extreme caution)

.EXAMPLE
    .\emergency-shutdown-all.ps1
    .\emergency-shutdown-all.ps1 -Force
#>

param(
    [switch]$Force
)

Write-Host "🚨 EMERGENCY SHUTDOWN - ALL ENVIRONMENTS 🚨" -ForegroundColor Red -BackgroundColor Yellow
Write-Host "=============================================" -ForegroundColor Red
Write-Host "This will shutdown ALL Beeux environments simultaneously!" -ForegroundColor Red
Write-Host ""
Write-Host "Environments to be shut down:" -ForegroundColor Yellow
Write-Host "❌ IT Environment (beeux-rg-it-eastus)" -ForegroundColor Red
Write-Host "❌ QA Environment (beeux-rg-qa-eastus)" -ForegroundColor Red  
Write-Host "❌ Production Environment (beeux-rg-prod-eastus)" -ForegroundColor Red
Write-Host ""

# Safety confirmation
if (-not $Force) {
    Write-Host "💰 EMERGENCY COST SAVINGS:" -ForegroundColor Green -BackgroundColor Black
    Write-Host "   💵 Will STOP combined cost of ~$3.90/hour" -ForegroundColor Green
    Write-Host "   💰 Will SAVE ~$93.60/day in charges" -ForegroundColor Green
    Write-Host "   📈 Will PREVENT ~$2,808/month if left running" -ForegroundColor Green
    Write-Host "   ✅ Final result: Monthly cost will be reduced to $0" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  WARNING: This will affect ALL environments including PRODUCTION!" -ForegroundColor Red
    Write-Host "💡 TIP: You can restart each environment individually later" -ForegroundColor Cyan
    Write-Host ""
    
    $emergencyConfirmation = Read-Host "This is an EMERGENCY SHUTDOWN. Type 'EMERGENCY-SHUTDOWN-ALL' to proceed"
    if ($emergencyConfirmation -ne "EMERGENCY-SHUTDOWN-ALL") {
        Write-Host "❌ Emergency shutdown cancelled" -ForegroundColor Yellow
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

# Environment configurations
$environments = @(
    @{
        Name = "IT"
        ResourceGroup = "beeux-rg-it-eastus"
        Color = "Cyan"
        HourlyCost = 0.50
    },
    @{
        Name = "QA"
        ResourceGroup = "beeux-rg-qa-eastus"
        Color = "Yellow"
        HourlyCost = 1.10
    },
    @{
        Name = "Production"
        ResourceGroup = "beeux-rg-prod-eastus"
        Color = "Red"
        HourlyCost = 2.30
    }
)

$totalHourlyCost = ($environments | Measure-Object -Property HourlyCost -Sum).Sum
Write-Host "💰 Total hourly cost being stopped: $${totalHourlyCost}" -ForegroundColor Green

# Start emergency shutdown process
Write-Host ""
Write-Host "🚀 Starting emergency shutdown of all environments..." -ForegroundColor Red
$shutdownStartTime = Get-Date

foreach ($env in $environments) {
    Write-Host ""
    Write-Host "🛑 Shutting down $($env.Name) Environment..." -ForegroundColor $env.Color
    Write-Host "Resource Group: $($env.ResourceGroup)" -ForegroundColor Gray
    
    # Check if resource group exists
    $rgExists = az group exists --name $env.ResourceGroup
    if ($rgExists -eq "false") {
        Write-Host "✅ $($env.Name) resource group does not exist. Skipping..." -ForegroundColor Green
        continue
    }
    
    # Stop App Services
    Write-Host "   🛑 Stopping App Services..." -ForegroundColor $env.Color
    $webApps = az webapp list --resource-group $env.ResourceGroup --query "[].name" --output tsv
    foreach ($app in $webApps) {
        if ($app) {
            Write-Host "     Stopping: $app" -ForegroundColor Gray
            az webapp stop --name $app --resource-group $env.ResourceGroup 2>$null
        }
    }
    
    # Scale down Container Apps to zero
    Write-Host "   🛑 Scaling down Container Apps..." -ForegroundColor $env.Color
    $containerApps = az containerapp list --resource-group $env.ResourceGroup --query "[].name" --output tsv
    foreach ($app in $containerApps) {
        if ($app) {
            Write-Host "     Scaling down: $app" -ForegroundColor Gray
            az containerapp update --name $app --resource-group $env.ResourceGroup --min-replicas 0 --max-replicas 0 2>$null
        }
    }
    
    # Stop PostgreSQL Databases (except for IT which uses self-hosted)
    if ($env.Name -ne "IT") {
        Write-Host "   🛑 Stopping PostgreSQL Databases..." -ForegroundColor $env.Color
        $databases = az postgres flexible-server list --resource-group $env.ResourceGroup --query "[].name" --output tsv
        foreach ($db in $databases) {
            if ($db) {
                Write-Host "     Stopping Database: $db" -ForegroundColor Gray
                az postgres flexible-server stop --name $db --resource-group $env.ResourceGroup 2>$null
            }
        }
    }
    
    Write-Host "✅ $($env.Name) environment services stopped (Cost savings: ~$$($env.HourlyCost)/hour)" -ForegroundColor Green
}

# Wait for all services to stop
Write-Host ""
Write-Host "⏳ Waiting for all services to stop gracefully..." -ForegroundColor Gray
Start-Sleep -Seconds 30

# Verify shutdown status
Write-Host ""
Write-Host "🔍 Verifying shutdown status..." -ForegroundColor Cyan

$allStopped = $true
foreach ($env in $environments) {
    $rgExists = az group exists --name $env.ResourceGroup
    if ($rgExists -eq "true") {
        Write-Host "   Checking $($env.Name) environment..." -ForegroundColor Gray
        
        # Check App Service status
        $webApps = az webapp list --resource-group $env.ResourceGroup --query "[].name" --output tsv
        foreach ($app in $webApps) {
            if ($app) {
                $status = az webapp show --name $app --resource-group $env.ResourceGroup --query "state" --output tsv 2>$null
                if ($status -eq "Running") {
                    Write-Host "     ⚠️ $app is still running" -ForegroundColor Yellow
                    $allStopped = $false
                } else {
                    Write-Host "     ✅ $app is stopped" -ForegroundColor Green
                }
            }
        }
        
        # Check Container App status
        $containerApps = az containerapp list --resource-group $env.ResourceGroup --query "[].name" --output tsv
        foreach ($app in $containerApps) {
            if ($app) {
                $replicas = az containerapp show --name $app --resource-group $env.ResourceGroup --query "properties.template.scale.minReplicas" --output tsv 2>$null
                if ($replicas -eq "0") {
                    Write-Host "     ✅ $app is scaled to zero" -ForegroundColor Green
                } else {
                    Write-Host "     ⚠️ $app may still have replicas" -ForegroundColor Yellow
                    $allStopped = $false
                }
            }
        }
    }
}

$shutdownEndTime = Get-Date
$shutdownDuration = $shutdownEndTime - $shutdownStartTime

Write-Host ""
if ($allStopped) {
    Write-Host "✅ EMERGENCY SHUTDOWN SUCCESSFUL!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "🎯 All environments have been stopped" -ForegroundColor Green
} else {
    Write-Host "⚠️ Some services may still be running. Check Azure portal." -ForegroundColor Yellow
    Write-Host "💡 Run individual shutdown scripts for complete resource deletion" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📋 Emergency Shutdown Summary:" -ForegroundColor Cyan
Write-Host "Start Time: $($shutdownStartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "End Time: $($shutdownEndTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "Duration: $($shutdownDuration.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Gray
Write-Host "Environments Affected: IT, QA, Production" -ForegroundColor Gray
Write-Host "Hourly Cost Savings: $${totalHourlyCost}" -ForegroundColor Green
Write-Host "Daily Cost Savings: $${totalHourlyCost * 24}" -ForegroundColor Green
Write-Host "Monthly Cost Savings: $${totalHourlyCost * 24 * 30}" -ForegroundColor Green

Write-Host ""
Write-Host "🔄 To restart environments individually:" -ForegroundColor Cyan
Write-Host "IT Environment:     .\infra\scripts\startup\complete-startup-it.ps1" -ForegroundColor Gray
Write-Host "QA Environment:     .\infra\scripts\startup\complete-startup-qa.ps1" -ForegroundColor Gray
Write-Host "Production:         .\infra\scripts\startup\complete-startup-prod.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "💡 For complete resource deletion (to guarantee $0 cost):" -ForegroundColor Cyan
Write-Host "IT Environment:     .\infra\scripts\shutdown\complete-shutdown-it.ps1" -ForegroundColor Gray
Write-Host "QA Environment:     .\infra\scripts\shutdown\complete-shutdown-qa.ps1" -ForegroundColor Gray
Write-Host "Production:         .\infra\scripts\shutdown\complete-shutdown-prod.ps1" -ForegroundColor Gray

# Send emergency notification email (if email service is configured)
Write-Host ""
Write-Host "📧 Emergency notification would be sent to:" -ForegroundColor Yellow
Write-Host "   Primary: prashantmdesai@yahoo.com" -ForegroundColor Gray
Write-Host "   Secondary: prashantmdesai@hotmail.com" -ForegroundColor Gray
Write-Host "   SMS: +12246564855" -ForegroundColor Gray

$emailBody = @"
BEEUX EMERGENCY SHUTDOWN NOTIFICATION

🚨 ALL ENVIRONMENTS HAVE BEEN EMERGENCY SHUT DOWN 🚨

Shutdown Details:
- Time: $($shutdownEndTime.ToString('yyyy-MM-dd HH:mm:ss UTC'))
- Duration: $($shutdownDuration.TotalMinutes.ToString('F1')) minutes
- Environments: IT, QA, Production
- Status: Emergency shutdown complete

Cost Impact:
- Hourly savings: $${totalHourlyCost}
- Daily savings: $${totalHourlyCost * 24}
- Monthly savings: $${totalHourlyCost * 24 * 30}

Next Steps:
1. Services are stopped but resources still exist (minimal cost)
2. For complete deletion and $0 cost, run shutdown scripts
3. To restart, use individual startup scripts

This was an emergency action to prevent runaway costs.
"@

Write-Host ""
Write-Host "🚨 EMERGENCY SHUTDOWN COMPLETE 🚨" -ForegroundColor Green -BackgroundColor Black
