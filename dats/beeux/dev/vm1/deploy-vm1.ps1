# =============================================================================
# DATS-BEEUX-DEV VM1 - DEPLOYMENT SCRIPT (Azure CLI)
# =============================================================================
# PowerShell script to deploy VM1 (dats-beeux-dev-data) infrastructure using Azure CLI
# =============================================================================

param(
    [string]$AdminPassword,
    [string]$SshPublicKey = "",
    [switch]$WhatIf = $false
)

# Source Infrastructure Command Logging Standard v1.1
$LoggingModule = Join-Path $PSScriptRoot "..\..\..\..\scripts\logging-standard-powershell.ps1"
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
$DeploymentName = "dats-beeux-dev-data-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$TemplateFile = "dats-beeux-dev-vm1-main.bicep"
$ParametersFile = "dats-beeux-dev-vm1-parameters.json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DATS-BEEUX-DEV-DATA VM DEPLOYMENT" -ForegroundColor Cyan
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

# Validate template
Write-Host "Validating Bicep template..." -ForegroundColor Green
$validationResult = az deployment sub validate `
    --location $Location `
    --template-file $TemplateFile `
    --parameters $ParametersFile `
    --query "error" -o json

if ($validationResult -ne "null") {
    Write-Error "Template validation failed: $validationResult"
    exit 1
}

Write-Host "Template validation successful!" -ForegroundColor Green

# Build deployment parameters
$deploymentParams = @(
    "--location", $Location
    "--template-file", $TemplateFile
    "--parameters", $ParametersFile
    "--name", $DeploymentName
)

if ($SshPublicKey) {
    $deploymentParams += "--parameters"
    $deploymentParams += "sshPublicKey=$SshPublicKey"
    Write-Host "SSH public key will be configured for authentication" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT EXECUTION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    if ($WhatIf) {
        Write-Host "Running What-If analysis..." -ForegroundColor Yellow
        az deployment sub what-if @deploymentParams
        Write-Host "What-If analysis completed." -ForegroundColor Green
    } else {
        Write-Host "Starting dats-beeux-dev-data VM deployment..." -ForegroundColor Yellow
        Write-Host "This will take approximately 5-10 minutes..." -ForegroundColor Yellow
        
        $result = az deployment sub create @deploymentParams --query "properties" -o json | ConvertFrom-Json
        
        if ($LASTEXITCODE -eq 0 -and $result.provisioningState -eq "Succeeded") {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            
            # Display outputs
            if ($result.outputs) {
                Write-Host ""
                Write-Host "Deployment Outputs:" -ForegroundColor Cyan
                foreach ($output in $result.outputs.PSObject.Properties) {
                    Write-Host "$($output.Name): $($output.Value.value)" -ForegroundColor Yellow
                }
            }
            
            Write-Host ""
            Write-Host "Next Steps:" -ForegroundColor Cyan
            Write-Host "1. Test SSH connection: ssh beeuser@<PUBLIC_IP>" -ForegroundColor White
            Write-Host "2. Install software: Use dats-beeux-dev-vm1-software-installer.sh" -ForegroundColor White
            Write-Host "3. Configure services as needed" -ForegroundColor White
            
        } else {
            Write-Error "Deployment failed with state: $($result.provisioningState)"
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
Write-Host "VM1 Monthly Cost: ~$69.46 (if running 24/7)" -ForegroundColor Yellow
Write-Host "Combined VM1+VM2: ~$138.92 (both running 24/7)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Cost Breakdown per VM:" -ForegroundColor Cyan
Write-Host "- VM Compute (Standard_B2ms): $59.67/month" -ForegroundColor White
Write-Host "- Storage (30GB Premium SSD): $6.14/month" -ForegroundColor White
Write-Host "- Public IP (Static): $3.65/month" -ForegroundColor White
Write-Host ""
Write-Host "Note: Costs shown for 24/7 operation. Actual costs depend on usage." -ForegroundColor Gray