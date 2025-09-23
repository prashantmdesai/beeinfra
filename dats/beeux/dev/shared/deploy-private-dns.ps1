# =============================================================================
# DATS-BEEUX-DEV - PRIVATE DNS DEPLOYMENT SCRIPT (Azure CLI)
# =============================================================================
# PowerShell script to deploy Private DNS infrastructure for VM-to-VM communication
# Cost: ~$0.51/month for enterprise-grade internal DNS resolution
# =============================================================================

param(
    [switch]$WhatIf = $false
)

# Source Infrastructure Command Logging Standard v1.1
$LoggingModule = Join-Path $PSScriptRoot "..\..\..\scripts\logging-standard-powershell.ps1"
. $LoggingModule

# Initialize logging
Setup-Logging

# Variables
$SubscriptionId = "d1f25f66-8914-4652-bcc4-8c6e0e0f1216"
$Location = "eastus"
$ResourceGroup = "rg-dev-eastus"
$DeploymentName = "dats-beeux-dev-private-dns-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$TemplateFile = "dats-beeux-dev-private-dns.bicep"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DATS-BEEUX-DEV PRIVATE DNS DEPLOYMENT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Name: $DeploymentName" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Yellow
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

# Get current VNet ID
Write-Host "Getting existing VNet information..." -ForegroundColor Green
$vnetId = az network vnet show --resource-group $ResourceGroup --name "vnet-dev-eastus" --query "id" -o tsv
if (-not $vnetId) {
    Write-Error "Could not find existing VNet. Please ensure VM1 is deployed first."
    exit 1
}

Write-Host "Found VNet: $vnetId" -ForegroundColor Yellow

# Get current VM private IPs using Azure CLI
Write-Host "Getting VM private IP addresses..." -ForegroundColor Green
$dataVmPrivateIp = az vm list-ip-addresses --resource-group $ResourceGroup --name "dats-beeux-dev-data" --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv
$appsVmPrivateIp = az vm list-ip-addresses --resource-group $ResourceGroup --name "dats-beeux-dev-apps" --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv

if (-not $dataVmPrivateIp) {
    Write-Warning "Could not get VM1 private IP, using default: 10.0.1.4"
    $dataVmPrivateIp = "10.0.1.4"
}

if (-not $appsVmPrivateIp) {
    Write-Warning "Could not get VM2 private IP, using default: 10.0.1.5"
    $appsVmPrivateIp = "10.0.1.5"
}

Write-Host "Data VM Private IP: $dataVmPrivateIp" -ForegroundColor Yellow
Write-Host "Apps VM Private IP: $appsVmPrivateIp" -ForegroundColor Yellow

# Build deployment parameters
$parameters = "environmentName='dev' virtualNetworkId='$vnetId' dataVmPrivateIp='$dataVmPrivateIp' appsVmPrivateIp='$appsVmPrivateIp'"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT EXECUTION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    if ($WhatIf) {
        Write-Host "Running What-If analysis..." -ForegroundColor Yellow
        $result = az deployment group what-if --resource-group $ResourceGroup --template-file $TemplateFile --parameters $parameters --name $DeploymentName
        if ($LASTEXITCODE -eq 0) {
            Write-Host "What-If analysis completed." -ForegroundColor Green
        } else {
            Write-Error "What-If analysis failed"
            exit 1
        }
    } else {
        Write-Host "Starting Private DNS deployment..." -ForegroundColor Yellow
        Write-Host "This will take approximately 2-3 minutes..." -ForegroundColor Yellow
        
        $result = az deployment group create --resource-group $ResourceGroup --template-file $TemplateFile --parameters $parameters --name $DeploymentName
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            
            # Display outputs
            $outputs = az deployment group show --resource-group $ResourceGroup --name $DeploymentName --query "properties.outputs" -o json | ConvertFrom-Json
            if ($outputs) {
                Write-Host ""
                Write-Host "Private DNS Configuration:" -ForegroundColor Cyan
                foreach ($output in $outputs.PSObject.Properties) {
                    Write-Host "$($output.Name): $($output.Value.value)" -ForegroundColor Yellow
                }
            }
            
            Write-Host ""
            Write-Host "Next Steps:" -ForegroundColor Cyan
            Write-Host "1. Test DNS resolution: ssh dats-beeux-dev-data 'nslookup apps.dats-beeux-dev.internal'" -ForegroundColor White
            Write-Host "2. Test VM communication: ssh dats-beeux-dev-data 'ping apps.dats-beeux-dev.internal'" -ForegroundColor White
            Write-Host "3. Update your applications to use DNS names instead of IP addresses" -ForegroundColor White
            Write-Host "   - PostgreSQL: postgresql.dats-beeux-dev.internal:5432" -ForegroundColor White
            Write-Host "   - Redis: redis.dats-beeux-dev.internal:6379" -ForegroundColor White
            Write-Host "   - Vault: vault.dats-beeux-dev.internal:8200" -ForegroundColor White
            
        } else {
            Write-Error "Deployment failed"
            $errorDetails = az deployment group show --resource-group $ResourceGroup --name $DeploymentName --query "properties.error" -o json 2>$null
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
Write-Host "Private DNS Zone: $0.50/month" -ForegroundColor Yellow
Write-Host "DNS Queries: ~$0.01/month (typical VM-to-VM usage)" -ForegroundColor Yellow
Write-Host "Total Additional Cost: ~$0.51/month" -ForegroundColor Green
Write-Host ""
Write-Host "Benefits:" -ForegroundColor Cyan
Write-Host "- Reliable VM-to-VM communication even if IPs change" -ForegroundColor White
Write-Host "- Enterprise-grade service discovery" -ForegroundColor White
Write-Host "- Improved application maintainability" -ForegroundColor White
Write-Host "- No performance impact (DNS caching)" -ForegroundColor White