# =============================================================================
# DATS-BEEUX-DEV VM1 - DEPLOYMENT SCRIPT
# =============================================================================
# This script deploys the dats-beeux-dev VM1 Ubuntu VM with Standard_B2ms sizing
# and comprehensive software installation automation
# =============================================================================

# Source Infrastructure Command Logging Standard v1.1
$LoggingModule = Join-Path $PSScriptRoot "..\..\..\..\scripts\logging-standard-powershell.ps1"
. $LoggingModule

# Initialize logging
Setup-Logging

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$SshPublicKey,
    
    [Parameter(Mandatory=$false)]
    [string]$AdminUsername = "beeuser",
    
    [Parameter(Mandatory=$false)]
    [SecureString]$AdminPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName = "dev"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Level) {
        "ERROR" { Write-Host "[$timestamp] ERROR: $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "[$timestamp] WARNING: $Message" -ForegroundColor Yellow }
        "SUCCESS" { Write-Host "[$timestamp] SUCCESS: $Message" -ForegroundColor Green }
        default { Write-Host "[$timestamp] INFO: $Message" -ForegroundColor Cyan }
    }
}

try {
    Write-Log "Starting dats-beeux-dev VM1 deployment for $EnvironmentName environment..."
    
    # Validate Azure CLI is installed and logged in
    Write-Log "Checking Azure CLI authentication..."
    $azAccount = az account show --output json 2>$null | ConvertFrom-Json
    if (-not $azAccount) {
        Write-Log "Please run 'az login' first" "ERROR"
        exit 1
    }
    
    Write-Log "Currently logged in as: $($azAccount.user.name)"
    Write-Log "Current subscription: $($azAccount.name) ($($azAccount.id))"
    
    # Set the subscription
    Write-Log "Setting subscription to: $SubscriptionId"
    az account set --subscription $SubscriptionId
    
    # Generate a secure password if not provided
    if (-not $AdminPassword) {
        Write-Log "Generating secure admin password..."
        $securePassword = -join ((65..90) + (97..122) + (48..57) + 33,35,36,37,38,42,43,61,63,64 | Get-Random -Count 16 | ForEach-Object {[char]$_})
        $AdminPassword = ConvertTo-SecureString $securePassword -AsPlainText -Force
        Write-Log "Generated admin password (save this): $securePassword" "WARNING"
    }
    
    # Convert secure string to plain text for deployment
    $plainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword))
    
    # Prepare deployment parameters
    $deploymentName = "dats-beeux-dev-vm1-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $templateFile = ".\dats\beeux\dev\vm1\dats-beeux-dev-vm1-main.bicep"
    $parametersFile = ".\dats\beeux\dev\vm1\dats-beeux-dev-vm1-parameters.json"
    
    # Check if template files exist
    if (-not (Test-Path $templateFile)) {
        Write-Log "Template file not found: $templateFile" "ERROR"
        exit 1
    }
    
    if (-not (Test-Path $parametersFile)) {
        Write-Log "Parameters file not found: $parametersFile" "ERROR"
        exit 1
    }
    
    # Display estimated costs
    Write-Log "ESTIMATED MONTHLY COSTS (24/7 operation):" "WARNING"
    Write-Log "- VM Compute (Standard_B2ms): $59.47/month" "WARNING"
    Write-Log "- Storage (30GB Premium SSD): $6.14/month" "WARNING"
    Write-Log "- Public IP (Static): $3.65/month" "WARNING"
    Write-Log "- TOTAL: $69.26/month" "WARNING"
    Write-Log "Actual costs depend on usage patterns and auto-shutdown configuration." "WARNING"
    
    # Confirm deployment
    $confirmation = Read-Host "Do you want to proceed with the dats-beeux-dev VM1 deployment? (y/N)"
    if ($confirmation -ne "y" -and $confirmation -ne "Y") {
        Write-Log "Deployment cancelled by user."
        exit 0
    }
    
    # Start deployment
    Write-Log "Starting dats-beeux-dev VM1 Bicep deployment..."
    Write-Log "Deployment name: $deploymentName"
    
    $deploymentResult = az deployment sub create `
        --location $Location `
        --name $deploymentName `
        --template-file $templateFile `
        --parameters $parametersFile `
        --parameters `
            sshPublicKey=$SshPublicKey `
            adminPassword=$plainTextPassword `
        --output json | ConvertFrom-Json
    
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Deployment failed!" "ERROR"
        exit 1
    }
    
    Write-Log "Deployment completed successfully!" "SUCCESS"
    
    # Extract outputs
    $outputs = $deploymentResult.properties.outputs
    $resourceGroupName = $outputs.resourceGroupName.value
    $vmPublicIP = $outputs.vmPublicIP.value
    $sshCommand = $outputs.sshCommand.value
    
    Write-Log "DEPLOYMENT RESULTS:" "SUCCESS"
    Write-Log "Resource Group: $resourceGroupName" "SUCCESS"
    Write-Log "VM Public IP: $vmPublicIP" "SUCCESS"
    Write-Log "SSH Command: $sshCommand" "SUCCESS"
    
    # Create SSH config entry
    $sshConfigEntry = @"

# Dats-Beeux-Dev VM1
Host dats-beeux-dev-vm1
    HostName $vmPublicIP
    User $AdminUsername
    Port 22
    IdentityFile ~/.ssh/dev-scsm-vault_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
"@
    
    Write-Log "SSH Config Entry (add to ~/.ssh/config):" "INFO"
    Write-Host $sshConfigEntry -ForegroundColor Gray
    
    # Test SSH connectivity
    Write-Log "Testing SSH connectivity in 30 seconds (allowing VM to boot)..."
    Start-Sleep -Seconds 30
    
    try {
        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i ~/.ssh/dev-scsm-vault_key $AdminUsername@$vmPublicIP "echo 'SSH connection successful'"
        if ($LASTEXITCODE -eq 0) {
            Write-Log "SSH connectivity test: PASSED" "SUCCESS"
        } else {
            Write-Log "SSH connectivity test: FAILED (VM may still be starting up)" "WARNING"
        }
    } catch {
        Write-Log "SSH connectivity test: FAILED (VM may still be starting up)" "WARNING"
    }
    
    Write-Log "dats-beeux-dev VM1 deployment completed! The software installation script will run automatically." "SUCCESS"
    Write-Log "It may take 10-15 minutes for all software to be installed." "INFO"
    
} catch {
    Write-Log "Deployment failed with error: $($_.Exception.Message)" "ERROR"
    exit 1
}