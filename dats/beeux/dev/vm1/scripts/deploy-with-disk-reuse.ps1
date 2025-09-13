# =============================================================================
# DATS-BEEUX-DEV VM1 - DEPLOYMENT SCRIPT WITH DISK REUSE
# =============================================================================
# This script deploys the dats-beeux-dev VM using the existing disk from dev-scsm-vault
# 
# Prerequisites:
# 1. Azure CLI installed and logged in
# 2. Access to both subscriptions (source: f82e8e5e-cf53-4ef7-b717-dacc295d4ee4, target: d1f25f66-8914-4652-bcc4-8c6e0e0f1216)
# 3. dev-scsm-vault VM must be stopped before deployment
#
# IMPORTANT: This script will:
# 1. Stop the existing dev-scsm-vault VM
# 2. Delete the dev-scsm-vault VM (disk will remain due to deleteOption: Detach)
# 3. Deploy the new dats-beeux-dev VM using the existing disk
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$SourceSubscriptionId = "f82e8e5e-cf53-4ef7-b717-dacc295d4ee4",
    
    [Parameter(Mandatory=$false)]
    [string]$TargetSubscriptionId = "d1f25f66-8914-4652-bcc4-8c6e0e0f1216",
    
    [Parameter(Mandatory=$false)]
    [string]$SourceResourceGroup = "beeinfra-dev-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$SourceVmName = "dev-scsm-vault",
    
    [Parameter(Mandatory=$false)]
    [string]$DiskName = "dev-scsm-vault_OsDisk_1_b230a675a9f34aaaa7f750e7d041b061",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "DATS-BEEUX-DEV VM1 - DEPLOYMENT WITH DISK REUSE" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ""

# Validate Azure CLI login
Write-Host "🔍 Validating Azure CLI login..." -ForegroundColor Yellow
try {
    $account = az account show --query "user.name" -o tsv
    if (-not $account) {
        throw "Not logged in to Azure CLI"
    }
    Write-Host "✅ Logged in as: $account" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Please run 'az login' first" -ForegroundColor Red
    exit 1
}

# Set source subscription context
Write-Host ""
Write-Host "🔄 Setting source subscription context..." -ForegroundColor Yellow
az account set --subscription $SourceSubscriptionId
Write-Host "✅ Source subscription set to: $SourceSubscriptionId" -ForegroundColor Green

# Check existing VM status
Write-Host ""
Write-Host "🔍 Checking existing VM status..." -ForegroundColor Yellow
$vmStatus = az vm get-instance-view --resource-group $SourceResourceGroup --name $SourceVmName --query "instanceView.statuses[?starts_with(code, 'PowerState')].displayStatus" -o tsv

if ($vmStatus) {
    Write-Host "✅ Current VM status: $vmStatus" -ForegroundColor Green
    
    if ($vmStatus -eq "VM running") {
        Write-Host ""
        Write-Host "⚠️  VM is currently running. It needs to be stopped before proceeding." -ForegroundColor Yellow
        
        if ($WhatIf) {
            Write-Host "🔍 [WHAT-IF] Would stop VM: $SourceVmName" -ForegroundColor Cyan
        } else {
            $confirm = Read-Host "Do you want to stop the VM now? (y/N)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                Write-Host "🛑 Stopping VM: $SourceVmName..." -ForegroundColor Yellow
                az vm stop --resource-group $SourceResourceGroup --name $SourceVmName
                Write-Host "✅ VM stopped successfully" -ForegroundColor Green
            } else {
                Write-Host "❌ Deployment cannot continue while VM is running" -ForegroundColor Red
                exit 1
            }
        }
    }
} else {
    Write-Host "❌ Could not retrieve VM status. Please verify VM exists." -ForegroundColor Red
    exit 1
}

# Check disk status
Write-Host ""
Write-Host "🔍 Checking disk status..." -ForegroundColor Yellow
$diskInfo = az disk show --resource-group $SourceResourceGroup --name $DiskName --query "{name:name, diskState:diskState, attachedTo:managedBy}" -o json | ConvertFrom-Json

if ($diskInfo) {
    Write-Host "✅ Disk found: $($diskInfo.name)" -ForegroundColor Green
    Write-Host "   State: $($diskInfo.diskState)" -ForegroundColor White
    Write-Host "   Attached to: $($diskInfo.attachedTo)" -ForegroundColor White
    
    if ($diskInfo.diskState -eq "Attached") {
        Write-Host ""
        Write-Host "⚠️  Disk is still attached to VM. VM must be deleted first." -ForegroundColor Yellow
        
        if ($WhatIf) {
            Write-Host "🔍 [WHAT-IF] Would delete VM: $SourceVmName (disk will remain due to deleteOption: Detach)" -ForegroundColor Cyan
        } else {
            $confirm = Read-Host "Do you want to delete the VM now? The disk will remain safe. (y/N)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                Write-Host "🗑️  Deleting VM: $SourceVmName (disk will be preserved)..." -ForegroundColor Yellow
                az vm delete --resource-group $SourceResourceGroup --name $SourceVmName --yes
                Write-Host "✅ VM deleted successfully. Disk preserved." -ForegroundColor Green
            } else {
                Write-Host "❌ Deployment cannot continue while disk is attached" -ForegroundColor Red
                exit 1
            }
        }
    }
} else {
    Write-Host "❌ Could not find disk: $DiskName" -ForegroundColor Red
    exit 1
}

# Set target subscription context
Write-Host ""
Write-Host "🔄 Setting target subscription context..." -ForegroundColor Yellow
az account set --subscription $TargetSubscriptionId
Write-Host "✅ Target subscription set to: $TargetSubscriptionId" -ForegroundColor Green

# Deploy the template
Write-Host ""
Write-Host "🚀 Deploying dats-beeux-dev VM with existing disk..." -ForegroundColor Yellow

$templateFile = "C:\dev\beeinfra\dats\beeux\dev\vm1\dats-beeux-dev-vm1-main.bicep"
$parametersFile = "C:\dev\beeinfra\dats\beeux\dev\vm1\dats-beeux-dev-vm1-parameters.json"

if ($WhatIf) {
    Write-Host "🔍 [WHAT-IF] Running deployment validation..." -ForegroundColor Cyan
    az deployment sub what-if --template-file $templateFile --parameters $parametersFile --location eastus
} else {
    Write-Host "⚡ Starting deployment..." -ForegroundColor Yellow
    $deploymentResult = az deployment sub create --template-file $templateFile --parameters $parametersFile --location eastus --name "dats-beeux-dev-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
        
        # Extract outputs
        $outputs = $deploymentResult | ConvertFrom-Json | Select-Object -ExpandProperty properties | Select-Object -ExpandProperty outputs
        
        Write-Host ""
        Write-Host "📋 Deployment Summary:" -ForegroundColor Cyan
        Write-Host "   Resource Group: $($outputs.resourceGroupName.value)" -ForegroundColor White
        Write-Host "   VM Public IP: $($outputs.vmPublicIP.value)" -ForegroundColor White
        Write-Host "   VM Private IP: $($outputs.vmPrivateIP.value)" -ForegroundColor White
        Write-Host "   SSH Command: $($outputs.sshCommand.value)" -ForegroundColor White
        
        Write-Host ""
        Write-Host "🎉 Your dats-beeux-dev VM is ready!" -ForegroundColor Green
        Write-Host "🔑 SSH Key: The existing SSH key will work since we're reusing the disk" -ForegroundColor Green
        Write-Host "💾 All data and software from dev-scsm-vault is preserved" -ForegroundColor Green
        
    } else {
        Write-Host "❌ Deployment failed. Check the error messages above." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan