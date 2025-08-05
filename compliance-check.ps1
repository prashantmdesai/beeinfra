#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verify compliance with all infrasetup.instructions.md requirements.
#>

Write-Host "Infrastructure Requirements Compliance Check" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Check budget amounts
Write-Host "1. Checking Budget Amounts..." -ForegroundColor Yellow

$itBudgetCheck = Get-Content "infra\scripts\startup\complete-startup-it.ps1" | Select-String "BudgetAmount = 10"
if ($itBudgetCheck) {
    Write-Host "   PASS: IT Budget is $10" -ForegroundColor Green
} else {
    Write-Host "   FAIL: IT Budget not set to $10" -ForegroundColor Red
}

$qaBudgetCheck = Get-Content "infra\scripts\startup\complete-startup-qa.ps1" | Select-String "BudgetAmount = 20"
if ($qaBudgetCheck) {
    Write-Host "   PASS: QA Budget is $20" -ForegroundColor Green
} else {
    Write-Host "   FAIL: QA Budget not set to $20" -ForegroundColor Red
}

$prodBudgetCheck = Get-Content "infra\scripts\startup\complete-startup-prod.ps1" | Select-String "BudgetAmount = 30"
if ($prodBudgetCheck) {
    Write-Host "   PASS: Production Budget is $30" -ForegroundColor Green
} else {
    Write-Host "   FAIL: Production Budget not set to $30" -ForegroundColor Red
}

# Check alert contacts
Write-Host ""
Write-Host "2. Checking Alert Contacts..." -ForegroundColor Yellow

$primaryEmailCheck = Get-Content "infra\scripts\utilities\setup-cost-alerts.ps1" | Select-String "prashantmdesai@yahoo.com"
if ($primaryEmailCheck) {
    Write-Host "   PASS: Primary email configured" -ForegroundColor Green
} else {
    Write-Host "   FAIL: Primary email not configured" -ForegroundColor Red
}

$secondaryEmailCheck = Get-Content "infra\scripts\utilities\setup-cost-alerts.ps1" | Select-String "prashantmdesai@hotmail.com"
if ($secondaryEmailCheck) {
    Write-Host "   PASS: Secondary email configured" -ForegroundColor Green
} else {
    Write-Host "   FAIL: Secondary email not configured" -ForegroundColor Red
}

$smsCheck = Get-Content "infra\scripts\utilities\setup-cost-alerts.ps1" | Select-String "2246564855"
if ($smsCheck) {
    Write-Host "   PASS: SMS number configured" -ForegroundColor Green
} else {
    Write-Host "   FAIL: SMS number not configured" -ForegroundColor Red
}

# Check cost-per-hour prompting
Write-Host ""
Write-Host "3. Checking Cost-per-Hour Prompting..." -ForegroundColor Yellow

$itCostCheck = Get-Content "infra\scripts\startup\complete-startup-it.ps1" | Select-String "cost.*hour.*accept"
if ($itCostCheck) {
    Write-Host "   PASS: IT cost prompting implemented" -ForegroundColor Green
} else {
    Write-Host "   FAIL: IT cost prompting missing" -ForegroundColor Red
}

$qaCostCheck = Get-Content "infra\scripts\startup\complete-startup-qa.ps1" | Select-String "cost.*hour.*accept"
if ($qaCostCheck) {
    Write-Host "   PASS: QA cost prompting implemented" -ForegroundColor Green
} else {
    Write-Host "   FAIL: QA cost prompting missing" -ForegroundColor Red
}

$prodCostCheck = Get-Content "infra\scripts\startup\complete-startup-prod.ps1" | Select-String "cost.*hour.*accept"
if ($prodCostCheck) {
    Write-Host "   PASS: Production cost prompting implemented" -ForegroundColor Green
} else {
    Write-Host "   FAIL: Production cost prompting missing" -ForegroundColor Red
}

# Check triple confirmation for production
Write-Host ""
Write-Host "4. Checking Production Triple Confirmation..." -ForegroundColor Yellow

$tripleConfirmationCheck = @()
$tripleConfirmationCheck += Get-Content "infra\scripts\shutdown\complete-shutdown-prod.ps1" | Select-String "FIRST"
$tripleConfirmationCheck += Get-Content "infra\scripts\shutdown\complete-shutdown-prod.ps1" | Select-String "SECOND"
$tripleConfirmationCheck += Get-Content "infra\scripts\shutdown\complete-shutdown-prod.ps1" | Select-String "FINAL"

if ($tripleConfirmationCheck.Count -ge 3) {
    Write-Host "   PASS: Triple confirmation implemented" -ForegroundColor Green
} else {
    Write-Host "   FAIL: Triple confirmation not properly implemented (found $($tripleConfirmationCheck.Count) confirmations)" -ForegroundColor Red
}

# Check auto-shutdown
Write-Host ""
Write-Host "5. Checking Auto-Shutdown Configuration..." -ForegroundColor Yellow

$autoShutdownCheck = Test-Path "infra\scripts\utilities\setup-auto-shutdown.ps1"
if ($autoShutdownCheck) {
    Write-Host "   PASS: Auto-shutdown utility exists" -ForegroundColor Green
} else {
    Write-Host "   FAIL: Auto-shutdown utility missing" -ForegroundColor Red
}

# Check developer VMs
Write-Host ""
Write-Host "6. Checking Developer VM Configuration..." -ForegroundColor Yellow

$devVmCheck = Test-Path "infra\modules\developer-vm.bicep"
if ($devVmCheck) {
    Write-Host "   PASS: Developer VM module exists" -ForegroundColor Green
} else {
    Write-Host "   FAIL: Developer VM module missing" -ForegroundColor Red
}

# Check HTTPS enforcement
Write-Host ""
Write-Host "7. Checking HTTPS Enforcement..." -ForegroundColor Yellow

$httpsCheck = Test-Path "validate-https-enforcement.ps1"
if ($httpsCheck) {
    Write-Host "   PASS: HTTPS validation script exists" -ForegroundColor Green
} else {
    Write-Host "   FAIL: HTTPS validation script missing" -ForegroundColor Red
}

# Check budget alerts module
Write-Host ""
Write-Host "8. Checking Budget Alerts Module..." -ForegroundColor Yellow

$budgetAlertsCheck = Test-Path "infra\modules\budget-alerts.bicep"
if ($budgetAlertsCheck) {
    Write-Host "   PASS: Budget alerts module exists" -ForegroundColor Green
} else {
    Write-Host "   FAIL: Budget alerts module missing" -ForegroundColor Red
}

# Check Azure Developer CLI integration
Write-Host ""
Write-Host "9. Checking Azure Developer CLI Integration..." -ForegroundColor Yellow

$azdCheck = Test-Path "azure.yaml"
if ($azdCheck) {
    Write-Host "   PASS: azure.yaml exists" -ForegroundColor Green
} else {
    Write-Host "   FAIL: azure.yaml missing" -ForegroundColor Red
}

Write-Host ""
Write-Host "Compliance check complete!" -ForegroundColor Cyan
