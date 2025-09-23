# =============================================================================
# DATS-BEEUX-DEV VM2 - DEPLOYMENT SCRIPT (Azure CLI)
# =============================================================================
# PowerShell script to deploy VM2 (dats-beeux-dev-apps) infrastructure using Azure CLI
# =============================================================================

param(
    [string]$AdminPassword,
    [string]$SshPublicKey = "",
    [switch]$WhatIf = $false
)

# Source Infrastructure Command Logging Standard v1.1
$LoggingModule = Join-Path $PSScriptRoot "..\..\..\scripts\logging-standard-powershell.ps1"
. $LoggingModule

# Initialize logging
Setup-Logging

# Check if required parameters are provided
if (-not $AdminPassword) {
    Write-Error "AdminPassword is required. Use -AdminPassword parameter."
    exit 1
}

# Variables
$SubscriptionId = "d1f25f66-8914-4652-bcc4-8c6e0e0f1216"
$Location = "eastus"
$DeploymentName = "dats-beeux-dev-apps-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$TemplateFile = "dats-beeux-dev-vm2-main.bicep"
$ParametersFile = "dats-beeux-dev-vm2-parameters.json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DATS-BEEUX-DEV-APPS VM DEPLOYMENT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Name: $DeploymentName" -ForegroundColor Yellow
Write-Host "Location: $Location" -ForegroundColor Yellow
Write-Host "What-If Mode: $WhatIf" -ForegroundColor Yellow
Write-Host ""

# Check Azure CLI login
Write-Host "Checking Azure CLI authentication..." -ForegroundColor Green
$account = az account show --query "id" -o tsv 2>$null
if (-not $account) {
    Write-Error "Not logged into Azure CLI. Please run 'az login'"
    exit 1
}

Write-Host "Authenticated as: $(az account show --query "user.name" -o tsv)" -ForegroundColor Green

# Set subscription context
Write-Host "Setting subscription context..." -ForegroundColor Green
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set subscription context"
    exit 1
}

# Build deployment parameters for Azure CLI
$parameters = "adminPassword='$AdminPassword'"

# Add SSH public key if provided
if ($SshPublicKey) {
    $parameters += " sshPublicKey='$SshPublicKey'"
    Write-Host "SSH public key will be configured for authentication" -ForegroundColor Yellow
} else {
    Write-Host "Only password authentication will be configured" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT EXECUTION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    if ($WhatIf) {
        Write-Host "Running What-If analysis..." -ForegroundColor Yellow
        $result = az deployment sub what-if --location $Location --template-file $TemplateFile --parameters $parameters --name $DeploymentName
        if ($LASTEXITCODE -eq 0) {
            Write-Host "What-If analysis completed." -ForegroundColor Green
        } else {
            Write-Error "What-If analysis failed"
            exit 1
        }
    } else {
        Write-Host "Starting dats-beeux-dev-apps VM deployment..." -ForegroundColor Yellow
        Write-Host "This will take approximately 5-10 minutes..." -ForegroundColor Yellow
        
        $result = az deployment sub create --location $Location --template-file $TemplateFile --parameters $parameters --name $DeploymentName
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            
            # Display outputs
            $outputs = az deployment sub show --name $DeploymentName --query "properties.outputs" -o json | ConvertFrom-Json
            if ($outputs) {
                Write-Host ""
                Write-Host "Deployment Outputs:" -ForegroundColor Cyan
                foreach ($output in $outputs.PSObject.Properties) {
                    Write-Host "$($output.Name): $($output.Value.value)" -ForegroundColor Yellow
                }
            }
            
            Write-Host ""
            Write-Host "Next Steps:" -ForegroundColor Cyan
            Write-Host "1. Test SSH connection: ssh beeuser@<PUBLIC_IP>" -ForegroundColor White
            Write-Host "2. Wait for software installation to complete (~10 minutes)" -ForegroundColor White
            Write-Host "3. Check installation log: sudo tail -f /var/log/vm2-software-install.log" -ForegroundColor White
            Write-Host "4. Review installation summary: cat ~/vm2-installation-summary.txt" -ForegroundColor White
            
        } else {
            Write-Error "Deployment failed"
            $errorDetails = az deployment sub show --name $DeploymentName --query "properties.error" -o json 2>$null
            if ($errorDetails -and $errorDetails -ne "null") {
                Write-Error "Error details: $errorDetails"
            }
            exit 1
        }
    }
} catch {
    Write-Error "Deployment failed: $_"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "COST INFORMATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VM2 Monthly Cost: ~$69.46 (if running 24/7)" -ForegroundColor Yellow
Write-Host "Combined VM1+VM2: ~$138.92 (both running 24/7)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Cost Breakdown per VM:" -ForegroundColor Cyan
Write-Host "- VM Compute (Standard_B2ms): $59.67/month" -ForegroundColor White
Write-Host "- Storage (30GB Premium SSD): $6.14/month" -ForegroundColor White
Write-Host "- Public IP (Static): $3.65/month" -ForegroundColor White
Write-Host ""
Write-Host "Note: Costs shown for 24/7 operation. Actual costs depend on usage." -ForegroundColor Gray