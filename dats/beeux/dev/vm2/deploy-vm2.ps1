# =============================================================================
# DATS-BEEUX-DEV VM2 - DEPLOYMENT SCRIPT
# =============================================================================
# PowerShell script to deploy VM2 infrastructure
# =============================================================================

param(
    [string]$AdminPassword,
    [string]$SshPublicKey = "",
    [switch]$WhatIf = $false
)

# Check if required parameters are provided
if (-not $AdminPassword) {
    Write-Error "AdminPassword is required. Use -AdminPassword parameter."
    exit 1
}

# Variables
$SubscriptionId = "f82e8e5e-cf53-4ef7-b717-dacc295d4ee4"
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

# Login to Azure (if not already logged in)
Write-Host "Checking Azure authentication..." -ForegroundColor Green
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Please login to Azure..."
        Connect-AzAccount
    }
    Write-Host "Authenticated as: $($context.Account.Id)" -ForegroundColor Green
} catch {
    Write-Error "Failed to authenticate to Azure: $_"
    exit 1
}

# Set subscription context
Write-Host "Setting subscription context..." -ForegroundColor Green
Set-AzContext -SubscriptionId $SubscriptionId

# Create secure password
$SecurePassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force

# Build deployment parameters
$DeploymentParameters = @{
    Name = $DeploymentName
    Location = $Location
    TemplateFile = $TemplateFile
    adminPassword = $SecurePassword
}

# Add SSH public key if provided
if ($SshPublicKey) {
    $DeploymentParameters.sshPublicKey = $SshPublicKey
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
        $result = New-AzSubscriptionDeployment @DeploymentParameters -WhatIf
        Write-Host "What-If analysis completed." -ForegroundColor Green
    } else {
        Write-Host "Starting dats-beeux-dev-apps VM deployment..." -ForegroundColor Yellow
        Write-Host "This will take approximately 5-10 minutes..." -ForegroundColor Yellow
        
        $result = New-AzSubscriptionDeployment @DeploymentParameters
        
        if ($result.ProvisioningState -eq "Succeeded") {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            
            # Display outputs
            if ($result.Outputs) {
                Write-Host ""
                Write-Host "Deployment Outputs:" -ForegroundColor Cyan
                foreach ($output in $result.Outputs.GetEnumerator()) {
                    Write-Host "$($output.Key): $($output.Value.Value)" -ForegroundColor Yellow
                }
            }
            
            Write-Host ""
            Write-Host "Next Steps:" -ForegroundColor Cyan
            Write-Host "1. Test SSH connection: ssh beeuser@<PUBLIC_IP>" -ForegroundColor White
            Write-Host "2. Wait for software installation to complete (~10 minutes)" -ForegroundColor White
            Write-Host "3. Check installation log: sudo tail -f /var/log/vm2-software-install.log" -ForegroundColor White
            Write-Host "4. Review installation summary: cat ~/vm2-installation-summary.txt" -ForegroundColor White
            
        } else {
            Write-Error "Deployment failed with state: $($result.ProvisioningState)"
            if ($result.Error) {
                Write-Error "Error details: $($result.Error.Message)"
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