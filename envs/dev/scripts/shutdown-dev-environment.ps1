# =============================================================================
# SHUTDOWN DEV ENVIRONMENT - PowerShell Script
# =============================================================================
# This script safely shuts down and deallocates all resources in the Dev environment
# to minimize costs when the environment is not in use
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName = "dev",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
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
    Write-Log "Starting $EnvironmentName environment shutdown process..."
    
    # Validate Azure CLI is installed and logged in
    Write-Log "Checking Azure CLI authentication..."
    $azAccount = az account show --output json 2>$null | ConvertFrom-Json
    if (-not $azAccount) {
        Write-Log "Please run 'az login' first" "ERROR"
        exit 1
    }
    
    Write-Log "Currently logged in as: $($azAccount.user.name)"
    
    # Set the subscription
    Write-Log "Setting subscription to: $SubscriptionId"
    az account set --subscription $SubscriptionId
    
    # Define resource group name
    $resourceGroupName = "rg-$EnvironmentName-eastus"
    
    # Check if resource group exists
    $resourceGroup = az group show --name $resourceGroupName --output json 2>$null | ConvertFrom-Json
    if (-not $resourceGroup) {
        Write-Log "Resource group '$resourceGroupName' not found. Nothing to shutdown." "WARNING"
        exit 0
    }
    
    Write-Log "Found resource group: $resourceGroupName"
    
    # Get all VMs in the resource group
    $vms = az vm list --resource-group $resourceGroupName --output json | ConvertFrom-Json
    
    if ($vms.Count -eq 0) {
        Write-Log "No VMs found in resource group '$resourceGroupName'" "INFO"
    } else {
        Write-Log "Found $($vms.Count) VM(s) in the resource group"
        
        # Display estimated savings
        Write-Log "ESTIMATED MONTHLY SAVINGS FROM SHUTDOWN:" "SUCCESS"
        Write-Log "- VM Compute savings: ~$59.47/month (Standard_B2ms when deallocated)" "SUCCESS"
        Write-Log "- Storage costs continue: $6.14/month (30GB Premium SSD)" "WARNING"
        Write-Log "- Public IP costs continue: $3.65/month (Static IP)" "WARNING"
        Write-Log "- Total monthly savings: ~$59.47/month" "SUCCESS"
        
        if (-not $Force) {
            # Extra confirmation for production safety
            if ($EnvironmentName -eq "prod") {
                Write-Log "⚠️  PRODUCTION ENVIRONMENT SHUTDOWN REQUESTED ⚠️" "ERROR"
                Write-Log "This will shut down the PRODUCTION environment!" "ERROR"
                
                $confirm1 = Read-Host "Type 'SHUTDOWN-PROD' to confirm production shutdown"
                if ($confirm1 -ne "SHUTDOWN-PROD") {
                    Write-Log "Production shutdown cancelled - confirmation failed."
                    exit 0
                }
                
                $confirm2 = Read-Host "Are you absolutely sure? Type 'YES-SHUTDOWN-PRODUCTION'"
                if ($confirm2 -ne "YES-SHUTDOWN-PRODUCTION") {
                    Write-Log "Production shutdown cancelled - second confirmation failed."
                    exit 0
                }
                
                $confirm3 = Read-Host "Final confirmation - this will stop production services. Type 'CONFIRMED'"
                if ($confirm3 -ne "CONFIRMED") {
                    Write-Log "Production shutdown cancelled - final confirmation failed."
                    exit 0
                }
                
                Write-Log "Production shutdown confirmed with triple verification." "WARNING"
            } else {
                # Regular confirmation for non-production
                $confirmation = Read-Host "Do you want to shut down all VMs in the '$EnvironmentName' environment? (y/N)"
                if ($confirmation -ne "y" -and $confirmation -ne "Y") {
                    Write-Log "Shutdown cancelled by user."
                    exit 0
                }
            }
        }
        
        # Shutdown each VM
        foreach ($vm in $vms) {
            Write-Log "Shutting down VM: $($vm.name)"
            
            # Check current power state
            $vmStatus = az vm get-instance-view --name $vm.name --resource-group $resourceGroupName --query "instanceView.statuses[?code=='PowerState/running']" --output json | ConvertFrom-Json
            
            if ($vmStatus.Count -gt 0) {
                Write-Log "VM $($vm.name) is running - deallocating..."
                az vm deallocate --name $vm.name --resource-group $resourceGroupName --no-wait
                Write-Log "Deallocation started for VM: $($vm.name)" "SUCCESS"
            } else {
                Write-Log "VM $($vm.name) is already stopped/deallocated" "INFO"
            }
        }
        
        # Wait for all deallocations to complete
        Write-Log "Waiting for all VMs to be deallocated..."
        
        $maxWaitMinutes = 10
        $waitStartTime = Get-Date
        
        do {
            Start-Sleep -Seconds 30
            $runningVMs = 0
            
            foreach ($vm in $vms) {
                $vmStatus = az vm get-instance-view --name $vm.name --resource-group $resourceGroupName --query "instanceView.statuses[?code=='PowerState/running']" --output json | ConvertFrom-Json
                if ($vmStatus.Count -gt 0) {
                    $runningVMs++
                }
            }
            
            $elapsedMinutes = [math]::Round(((Get-Date) - $waitStartTime).TotalMinutes, 1)
            Write-Log "Still waiting... $runningVMs VM(s) still running (elapsed: $elapsedMinutes minutes)"
            
        } while ($runningVMs -gt 0 -and $elapsedMinutes -lt $maxWaitMinutes)
        
        if ($runningVMs -eq 0) {
            Write-Log "All VMs have been successfully deallocated!" "SUCCESS"
        } else {
            Write-Log "$runningVMs VM(s) still running after $maxWaitMinutes minutes. Check Azure portal for status." "WARNING"
        }
    }
    
    # Display final status
    Write-Log "SHUTDOWN SUMMARY:" "SUCCESS"
    Write-Log "Environment: $EnvironmentName" "SUCCESS"
    Write-Log "Resource Group: $resourceGroupName" "SUCCESS"
    Write-Log "VMs processed: $($vms.Count)" "SUCCESS"
    Write-Log "Estimated monthly savings: ~$59.47" "SUCCESS"
    
    Write-Log "Environment shutdown completed!" "SUCCESS"
    Write-Log "To restart the environment, run the deploy-ubuntu-vm.ps1 script." "INFO"
    
} catch {
    Write-Log "Shutdown failed with error: $($_.Exception.Message)" "ERROR"
    exit 1
}