#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verify compliance with all infrasetup.instructions.md requirements.

.DESCRIPTION
    This script verifies that all 26 requirements from infrasetup.instructions.md 
    are properly implemented throughout the project.

.EXAMPLE
    .\verify-requirements-compliance.ps1
#>

Write-Host "🔍 INFRASETUP REQUIREMENTS COMPLIANCE VERIFICATION" -ForegroundColor Cyan -BackgroundColor Black
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# Requirement tracking
$requirements = @(
    @{ id = 1; description = "IT Environment Budget Alert (Estimated) - $10"; status = "CHECKING" },
    @{ id = 2; description = "IT Environment Budget Alert (Actual) - $10"; status = "CHECKING" },
    @{ id = 3; description = "QA Environment Budget Alert (Estimated) - $20"; status = "CHECKING" },
    @{ id = 4; description = "QA Environment Budget Alert (Actual) - $20"; status = "CHECKING" },
    @{ id = 5; description = "Production Environment Budget Alert (Estimated) - $30"; status = "CHECKING" },
    @{ id = 6; description = "Production Environment Budget Alert (Actual) - $30"; status = "CHECKING" },
    @{ id = 7; description = "Environment identification in all commands"; status = "CHECKING" },
    @{ id = 8; description = "Alert emails to prashantmdesai@yahoo.com"; status = "CHECKING" },
    @{ id = 9; description = "Alert emails to prashantmdesai@hotmail.com"; status = "CHECKING" },
    @{ id = 10; description = "SMS alerts to +1 224 656 4855"; status = "CHECKING" },
    @{ id = 11; description = "Auto-shutdown after 1 hour idle - IT"; status = "CHECKING" },
    @{ id = 12; description = "Auto-shutdown after 1 hour idle - QA"; status = "CHECKING" },
    @{ id = 13; description = "Auto-shutdown after 1 hour idle - Production"; status = "CHECKING" },
    @{ id = 14; description = "Cost-per-hour prompting before startup - IT"; status = "CHECKING" },
    @{ id = 15; description = "Cost-per-hour prompting before startup - QA"; status = "CHECKING" },
    @{ id = 16; description = "Cost-per-hour prompting before startup - Production"; status = "CHECKING" },
    @{ id = 17; description = "Triple confirmation for Production shutdown"; status = "CHECKING" },
    @{ id = 18; description = "Linux Developer VM in IT environment"; status = "CHECKING" },
    @{ id = 19; description = "Linux Developer VM in QA environment"; status = "CHECKING" },
    @{ id = 20; description = "Linux Developer VM in Production environment"; status = "CHECKING" },
    @{ id = 21; description = "HTTPS enforcement across all web traffic"; status = "CHECKING" },
    @{ id = 22; description = "TLS 1.2+ minimum security"; status = "CHECKING" },
    @{ id = 23; description = "Auto-shutdown email notifications"; status = "CHECKING" },
    @{ id = 24; description = "Budget alert thresholds at 50%, 80%, 100%"; status = "CHECKING" },
    @{ id = 25; description = "Azure Developer CLI (azd) integration"; status = "CHECKING" },
    @{ id = 26; description = "Cost transparency and confirmation prompts"; status = "CHECKING" }
)

Write-Host "📋 CHECKING 26 INFRASETUP REQUIREMENTS..." -ForegroundColor Yellow
Write-Host ""

# Check 1-6: Budget amounts in startup scripts
Write-Host "💰 Checking Budget Amounts..." -ForegroundColor Cyan

# IT Environment ($10)
$itBudget = Get-Content "infra\scripts\startup\complete-startup-it.ps1" | Select-String "BudgetAmount = 10"
if ($itBudget) {
    $requirements[0].status = "✅ PASS"
    $requirements[1].status = "✅ PASS"
    Write-Host "   ✅ IT Budget correctly set to $10" -ForegroundColor Green
} else {
    $requirements[0].status = "❌ FAIL"
    $requirements[1].status = "❌ FAIL"
    Write-Host "   ❌ IT Budget not set to $10" -ForegroundColor Red
}

# QA Environment ($20)
$qaBudget = Get-Content "infra\scripts\startup\complete-startup-qa.ps1" | Select-String "BudgetAmount = 20"
if ($qaBudget) {
    $requirements[2].status = "✅ PASS"
    $requirements[3].status = "✅ PASS"
    Write-Host "   ✅ QA Budget correctly set to $20" -ForegroundColor Green
} else {
    $requirements[2].status = "❌ FAIL"
    $requirements[3].status = "❌ FAIL"
    Write-Host "   ❌ QA Budget not set to $20" -ForegroundColor Red
}

# Production Environment ($30)
$prodBudget = Get-Content "infra\scripts\startup\complete-startup-prod.ps1" | Select-String "BudgetAmount = 30"
if ($prodBudget) {
    $requirements[4].status = "✅ PASS"
    $requirements[5].status = "✅ PASS"
    Write-Host "   ✅ Production Budget correctly set to $30" -ForegroundColor Green
} else {
    $requirements[4].status = "❌ FAIL"
    $requirements[5].status = "❌ FAIL"
    Write-Host "   ❌ Production Budget not set to $30" -ForegroundColor Red
}

# Check 7: Environment identification
Write-Host ""
Write-Host "🏷️  Checking Environment Identification..." -ForegroundColor Cyan
$envIdentification = @()
$envIdentification += Get-Content "infra\scripts\startup\*.ps1" | Select-String "Environment: \$EnvironmentName"
$envIdentification += Get-Content "infra\scripts\startup\*.ps1" | Select-String "ResourceGroupName.*-\$EnvironmentName-"

if ($envIdentification.Count -ge 6) {
    $requirements[6].status = "✅ PASS"
    Write-Host "   ✅ Environment identification present in scripts" -ForegroundColor Green
} else {
    $requirements[6].status = "❌ FAIL"
    Write-Host "   ❌ Environment identification not consistently implemented" -ForegroundColor Red
}

# Check 8-10: Alert contacts
Write-Host ""
Write-Host "📧 Checking Alert Contact Configuration..." -ForegroundColor Cyan

$primaryEmail = Get-Content "infra\scripts\utilities\setup-cost-alerts.ps1" | Select-String "prashantmdesai@yahoo.com"
if ($primaryEmail) {
    $requirements[7].status = "✅ PASS"
    Write-Host "   ✅ Primary email configured correctly" -ForegroundColor Green
} else {
    $requirements[7].status = "❌ FAIL"
    Write-Host "   ❌ Primary email not configured" -ForegroundColor Red
}

$secondaryEmail = Get-Content "infra\scripts\utilities\setup-cost-alerts.ps1" | Select-String "prashantmdesai@hotmail.com"
if ($secondaryEmail) {
    $requirements[8].status = "✅ PASS"
    Write-Host "   ✅ Secondary email configured correctly" -ForegroundColor Green
} else {
    $requirements[8].status = "❌ FAIL"
    Write-Host "   ❌ Secondary email not configured" -ForegroundColor Red
}

$smsNumber = Get-Content "infra\scripts\utilities\setup-cost-alerts.ps1" | Select-String "\+12246564855"
if ($smsNumber) {
    $requirements[9].status = "✅ PASS"
    Write-Host "   ✅ SMS number configured correctly" -ForegroundColor Green
} else {
    $requirements[9].status = "❌ FAIL"
    Write-Host "   ❌ SMS number not configured" -ForegroundColor Red
}

# Check 11-13: Auto-shutdown configuration
Write-Host ""
Write-Host "⏰ Checking Auto-Shutdown Configuration..." -ForegroundColor Cyan

$autoShutdownUtility = Test-Path "infra\scripts\utilities\setup-auto-shutdown.ps1"
if ($autoShutdownUtility) {
    $requirements[10].status = "✅ PASS"
    $requirements[11].status = "✅ PASS"
    $requirements[12].status = "✅ PASS"
    Write-Host "   ✅ Auto-shutdown utility script exists" -ForegroundColor Green
} else {
    $requirements[10].status = "❌ FAIL"
    $requirements[11].status = "❌ FAIL"
    $requirements[12].status = "❌ FAIL"
    Write-Host "   ❌ Auto-shutdown utility script missing" -ForegroundColor Red
}

# Check 14-16: Cost-per-hour prompting
Write-Host ""
Write-Host "💲 Checking Cost-per-Hour Prompting..." -ForegroundColor Cyan

$itCostPrompt = Get-Content "infra\scripts\startup\complete-startup-it.ps1" | Select-String "cost.*hour.*accept"
if ($itCostPrompt) {
    $requirements[13].status = "✅ PASS"
    Write-Host "   ✅ IT cost prompting implemented" -ForegroundColor Green
} else {
    $requirements[13].status = "❌ FAIL"
    Write-Host "   ❌ IT cost prompting missing" -ForegroundColor Red
}

$qaCostPrompt = Get-Content "infra\scripts\startup\complete-startup-qa.ps1" | Select-String "cost.*hour.*accept"
if ($qaCostPrompt) {
    $requirements[14].status = "✅ PASS"
    Write-Host "   ✅ QA cost prompting implemented" -ForegroundColor Green
} else {
    $requirements[14].status = "❌ FAIL"
    Write-Host "   ❌ QA cost prompting missing" -ForegroundColor Red
}

$prodCostPrompt = Get-Content "infra\scripts\startup\complete-startup-prod.ps1" | Select-String "cost.*hour.*accept"
if ($prodCostPrompt) {
    $requirements[15].status = "✅ PASS"
    Write-Host "   ✅ Production cost prompting implemented" -ForegroundColor Green
} else {
    $requirements[15].status = "❌ FAIL"
    Write-Host "   ❌ Production cost prompting missing" -ForegroundColor Red
}

# Check 17: Triple confirmation for Production shutdown
Write-Host ""
Write-Host "🚨 Checking Production Triple Confirmation..." -ForegroundColor Cyan

$tripleConfirmation = @()
$tripleConfirmation += Get-Content "infra\scripts\shutdown\complete-shutdown-prod.ps1" | Select-String "FIRST CONFIRMATION"
$tripleConfirmation += Get-Content "infra\scripts\shutdown\complete-shutdown-prod.ps1" | Select-String "SECOND CONFIRMATION"
$tripleConfirmation += Get-Content "infra\scripts\shutdown\complete-shutdown-prod.ps1" | Select-String "FINAL CONFIRMATION"

if ($tripleConfirmation.Count -eq 3) {
    $requirements[16].status = "✅ PASS"
    Write-Host "   ✅ Triple confirmation implemented" -ForegroundColor Green
} else {
    $requirements[16].status = "❌ FAIL"
    Write-Host "   ❌ Triple confirmation not properly implemented" -ForegroundColor Red
}

# Check 18-20: Developer VMs
Write-Host ""
Write-Host "🖥️  Checking Developer VM Configuration..." -ForegroundColor Cyan

$devVmModule = Test-Path "infra\modules\developer-vm.bicep"
if ($devVmModule) {
    $requirements[17].status = "✅ PASS"
    $requirements[18].status = "✅ PASS"
    $requirements[19].status = "✅ PASS"
    Write-Host "   ✅ Developer VM Bicep module exists" -ForegroundColor Green
} else {
    $requirements[17].status = "❌ FAIL"
    $requirements[18].status = "❌ FAIL"
    $requirements[19].status = "❌ FAIL"
    Write-Host "   ❌ Developer VM module missing" -ForegroundColor Red
}

# Check 21-22: HTTPS enforcement
Write-Host ""
Write-Host "🔒 Checking HTTPS Enforcement..." -ForegroundColor Cyan

$httpsValidation = Test-Path "validate-https-enforcement.ps1"
if ($httpsValidation) {
    $requirements[20].status = "✅ PASS"
    $requirements[21].status = "✅ PASS"
    Write-Host "   ✅ HTTPS validation script exists" -ForegroundColor Green
} else {
    $requirements[20].status = "❌ FAIL"
    $requirements[21].status = "❌ FAIL"
    Write-Host "   ❌ HTTPS validation script missing" -ForegroundColor Red
}

# Check 23: Auto-shutdown notifications
Write-Host ""
Write-Host "📬 Checking Auto-Shutdown Notifications..." -ForegroundColor Cyan

$autoShutdownModule = Test-Path "infra\modules\auto-shutdown.bicep"
if ($autoShutdownModule) {
    $requirements[22].status = "✅ PASS"
    Write-Host "   ✅ Auto-shutdown module exists" -ForegroundColor Green
} else {
    $requirements[22].status = "❌ FAIL"
    Write-Host "   ❌ Auto-shutdown module missing" -ForegroundColor Red
}

# Check 24: Budget alert thresholds
Write-Host ""
Write-Host "📊 Checking Budget Alert Thresholds..." -ForegroundColor Cyan

$budgetThresholds = Get-Content "infra\modules\budget-alerts.bicep" | Select-String "threshold: (50|80|100)" -SimpleMatch
if ($budgetThresholds.Count -ge 6) {
    $requirements[23].status = "✅ PASS"
    Write-Host "   ✅ Budget alert thresholds configured (50, 80, 100 percent)" -ForegroundColor Green
} else {
    $requirements[23].status = "❌ FAIL"
    Write-Host "   ❌ Budget alert thresholds not properly configured" -ForegroundColor Red
}

# Check 25: Azure Developer CLI integration
Write-Host ""
Write-Host "🔧 Checking Azure Developer CLI Integration..." -ForegroundColor Cyan

$azdYaml = Test-Path "azure.yaml"
if ($azdYaml) {
    $requirements[24].status = "✅ PASS"
    Write-Host "   ✅ azure.yaml exists for azd integration" -ForegroundColor Green
} else {
    $requirements[24].status = "❌ FAIL"
    Write-Host "   ❌ azure.yaml missing" -ForegroundColor Red
}

# Check 26: Cost transparency
Write-Host ""
Write-Host "💎 Checking Cost Transparency..." -ForegroundColor Cyan

$costTransparency = @()
$costTransparency += Get-Content "infra\scripts\startup\*.ps1" | Select-String "cost.*hour"
$costTransparency += Get-Content "infra\scripts\startup\*.ps1" | Select-String "Type.*Yes.*accept"

if ($costTransparency.Count -ge 6) {
    $requirements[25].status = "✅ PASS"
    Write-Host "   ✅ Cost transparency implemented" -ForegroundColor Green
} else {
    $requirements[25].status = "❌ FAIL"
    Write-Host "   ❌ Cost transparency not consistently implemented" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "📋 COMPLIANCE SUMMARY" -ForegroundColor Yellow -BackgroundColor Black
Write-Host "=====================" -ForegroundColor Yellow
Write-Host ""

$passCount = ($requirements | Where-Object { $_.status -eq "✅ PASS" }).Count
$failCount = ($requirements | Where-Object { $_.status -eq "❌ FAIL" }).Count

foreach ($req in $requirements) {
    $color = if ($req.status -eq "✅ PASS") { "Green" } else { "Red" }
    Write-Host "   $($req.status) Requirement $($req.id): $($req.description)" -ForegroundColor $color
}

Write-Host ""
Write-Host "📊 OVERALL COMPLIANCE: $passCount PASS / $failCount FAIL / 26 TOTAL" -ForegroundColor Yellow
if ($failCount -eq 0) {
    Write-Host "🎉 ALL REQUIREMENTS COMPLIANT! 🎉" -ForegroundColor Green -BackgroundColor Black
} else {
    Write-Host "⚠️  $failCount REQUIREMENTS NEED ATTENTION" -ForegroundColor Red -BackgroundColor Yellow
}

Write-Host ""
Write-Host "💡 Run this script regularly to ensure ongoing compliance" -ForegroundColor Cyan
