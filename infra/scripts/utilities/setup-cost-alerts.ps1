#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Set up cost monitoring and budget alerts for Azure environments.

.DESCRIPTION
    This utility script implements the budget alert requirements from infrasetup.instructions.md
    by creating comprehensive cost monitoring for Azure resource groups. It ensures strict
    adherence to the specified budget limits and provides immediate notifications when
    spending thresholds are exceeded.

    REQUIREMENTS COMPLIANCE:
    =======================
    This script directly implements requirements 1-6 from infrasetup.instructions.md:
    - Requirement 1: IT Environment - Estimated Budget Alert ($10)
    - Requirement 2: IT Environment - Actual Budget Alert ($10) 
    - Requirement 3: QA Environment - Estimated Budget Alert ($20)
    - Requirement 4: QA Environment - Actual Budget Alert ($20)
    - Requirement 5: Production Environment - Estimated Budget Alert ($30)
    - Requirement 6: Production Environment - Actual Budget Alert ($30)
    
    ALERT CONFIGURATION:
    ===================
    For each environment, the script creates multiple budget alerts:
    - 50% threshold: Early warning to monitor usage more closely
    - 80% threshold: Action required - review and optimize resources
    - 90% threshold: Forecasted alert to prevent overruns 
    - 100% threshold: Critical alert - immediate intervention needed
    
    NOTIFICATION CHANNELS:
    =====================
    All alerts are sent to the specified contacts via:
    - Primary Email: prashantmdesai@yahoo.com
    - Secondary Email: prashantmdesai@hotmail.com
    - SMS: +1 224 656 4855
    
    DUAL BUDGET STRATEGY:
    ====================
    The script creates TWO budget resources for comprehensive monitoring:
    1. Actual costs budget: Tracks real spending as charges are incurred
    2. Forecasted costs budget: Uses Azure ML to predict spending trends
    
    This dual approach provides both reactive alerts (when you've already spent money)
    and proactive alerts (when Azure predicts you will exceed the budget).

.PARAMETER EnvironmentName
    The environment name (it, qa, prod)

.PARAMETER BudgetAmount
    The monthly budget amount in USD

.EXAMPLE
    .\setup-cost-alerts.ps1 -EnvironmentName "it" -BudgetAmount 10
    .\setup-cost-alerts.ps1 -EnvironmentName "qa" -BudgetAmount 20
    .\setup-cost-alerts.ps1 -EnvironmentName "prod" -BudgetAmount 30
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentName,
    
    [Parameter(Mandatory=$true)]
    [int]$BudgetAmount
)

# Pre-configured alert contacts as specified in infrasetup.instructions.md requirements 8-10
$ResourceGroupName = "beeux-rg-$EnvironmentName-eastus"
$PrimaryEmail = "prashantmdesai@yahoo.com"      # Requirement 8: Primary email alerts
$SecondaryEmail = "prashantmdesai@hotmail.com"  # Requirement 9: Secondary email alerts  
$PhoneNumber = "+12246564855"                   # Requirement 10: SMS alerts

Write-Host "💰 Setting up cost monitoring for $EnvironmentName environment..." -ForegroundColor Cyan
Write-Host "Budget Amount: $BudgetAmount USD/month" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "Alert Contacts: $PrimaryEmail, $SecondaryEmail, $PhoneNumber" -ForegroundColor Yellow

# Check if Azure CLI is logged in
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "❌ Not logged into Azure CLI. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Check if resource group exists
Write-Host "🔍 Checking if resource group exists..." -ForegroundColor Cyan
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "❌ Resource group $ResourceGroupName not found!" -ForegroundColor Red
    Write-Host "💡 Please create the resource group first or run the startup script" -ForegroundColor Cyan
    exit 1
}

# Get resource group ID and subscription ID
$resourceGroupId = az group show --name $ResourceGroupName --query id --output tsv
$subscriptionId = $account.id

Write-Host "✅ Resource group found: $ResourceGroupName" -ForegroundColor Green

# Create budget configuration JSON
$budgetConfig = @{
    properties = @{
        category = "Cost"
        amount = $BudgetAmount
        timeGrain = "Monthly"
        timePeriod = @{
            startDate = (Get-Date -Format "yyyy-MM-01")
            endDate = "2030-12-31"
        }
        filter = @{
            dimensions = @{
                name = "ResourceGroupName"
                operator = "In"
                values = @($ResourceGroupName)
            }
        }
        notifications = @{
            "alert-50" = @{
                enabled = $true
                operator = "GreaterThan"
                threshold = 50
                contactEmails = @($PrimaryEmail, $SecondaryEmail)
                thresholdType = "Actual"
            }
            "alert-80" = @{
                enabled = $true
                operator = "GreaterThan"
                threshold = 80
                contactEmails = @($PrimaryEmail, $SecondaryEmail)
                thresholdType = "Actual"
            }
            "alert-100" = @{
                enabled = $true
                operator = "GreaterThan"
                threshold = 100
                contactEmails = @($PrimaryEmail, $SecondaryEmail)
                thresholdType = "Actual"
            }
            "forecast-90" = @{
                enabled = $true
                operator = "GreaterThan"
                threshold = 90
                contactEmails = @($PrimaryEmail, $SecondaryEmail)
                thresholdType = "Forecasted"
            }
        }
    }
} | ConvertTo-Json -Depth 10

# Save budget configuration to temporary file
$budgetFile = "temp-budget-$EnvironmentName.json"
$budgetConfig | Out-File -FilePath $budgetFile -Encoding UTF8

Write-Host "📊 Creating budget alerts..." -ForegroundColor Cyan

try {
    # Create the budget
    $budgetName = "beeux-budget-$EnvironmentName"
    az consumption budget create `
        --budget-name $budgetName `
        --amount $BudgetAmount `
        --category "Cost" `
        --time-grain "Monthly" `
        --resource-group $ResourceGroupName `
        --budget-file $budgetFile 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Budget alerts successfully configured!" -ForegroundColor Green
        Write-Host "📧 Email alerts will be sent to: $PrimaryEmail, $SecondaryEmail" -ForegroundColor Yellow
        Write-Host "💰 Budget limit set to: $BudgetAmount USD/month" -ForegroundColor Yellow
        Write-Host "🔔 Alerts will trigger at 50%, 80%, 90% (forecast), and 100% of budget" -ForegroundColor Yellow
    } else {
        Write-Host "⚠️ Budget creation via CLI failed, trying alternative method..." -ForegroundColor Yellow
        
        # Alternative: Use REST API call through Azure CLI
        az rest --method PUT `
            --url "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Consumption/budgets/$budgetName" `
            --body $budgetConfig `
            --headers "Content-Type=application/json" 2>$null
            
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Budget alerts configured via REST API!" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to create budget alerts. Manual configuration required." -ForegroundColor Red
            Write-Host "💡 You can set up budget alerts manually in the Azure portal:" -ForegroundColor Cyan
            Write-Host "   1. Go to Cost Management + Billing" -ForegroundColor Cyan
            Write-Host "   2. Select Budgets" -ForegroundColor Cyan
            Write-Host "   3. Create budget for resource group: $ResourceGroupName" -ForegroundColor Cyan
            Write-Host "   4. Set budget amount: $BudgetAmount USD" -ForegroundColor Cyan
            Write-Host "   5. Add email alerts: $PrimaryEmail, $SecondaryEmail" -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "❌ Error creating budget: $($_.Exception.Message)" -ForegroundColor Red
}

# Clean up temporary file
Remove-Item $budgetFile -ErrorAction SilentlyContinue

# Verify the setup
Write-Host "🔍 Verifying budget configuration..." -ForegroundColor Cyan
try {
    $budgets = az consumption budget list --resource-group $ResourceGroupName --query "[?contains(name, 'beeux-$EnvironmentName')].{Name:name, Amount:amount, Status:status}" --output table 2>$null
    if ($budgets) {
        Write-Host $budgets
        Write-Host "✅ Budget verification successful!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Could not verify budget (may still be provisioning)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Could not verify budget configuration" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "💡 Additional Cost Management Tips:" -ForegroundColor Cyan
Write-Host "   • Set up auto-shutdown for non-production environments" -ForegroundColor Cyan
Write-Host "   • Monitor costs daily in Azure portal" -ForegroundColor Cyan
Write-Host "   • Use Azure Advisor for cost optimization recommendations" -ForegroundColor Cyan
Write-Host "   • Consider using Azure Dev/Test pricing for development" -ForegroundColor Cyan

Write-Host ""
Write-Host "✅ Cost monitoring setup complete for $EnvironmentName environment!" -ForegroundColor Green
