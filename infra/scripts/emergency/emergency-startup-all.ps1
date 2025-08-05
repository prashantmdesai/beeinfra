#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Emergency startup of ALL environments (IT, QA, Production) from zero state.

.DESCRIPTION
    This script provides an emergency startup option to provision all environments
    quickly in parallel. Use for disaster recovery or rapid environment recreation.

.PARAMETER Force
    Skip confirmation prompts

.EXAMPLE
    .\emergency-startup-all.ps1
#>

param(
    [switch]$Force
)

Write-Host "🚨🚨🚨 EMERGENCY STARTUP - ALL ENVIRONMENTS 🚨🚨🚨" -ForegroundColor Green -BackgroundColor Black
Write-Host "===================================================" -ForegroundColor Green
Write-Host "This will start ALL environments: IT, QA, and PRODUCTION" -ForegroundColor Green
Write-Host "⚡ Starting environments in parallel for fastest startup" -ForegroundColor Yellow

if (-not $Force) {
    Write-Host ""
    Write-Host "💰 COMBINED COST ESTIMATE FOR ALL ENVIRONMENTS:" -ForegroundColor Red -BackgroundColor Yellow
    Write-Host "   📊 Combined cost per HOUR: ~$3.90/hour (IT: $0.50 + QA: $1.10 + Prod: $2.30)" -ForegroundColor Red
    Write-Host "   📅 Combined cost per DAY: ~$93.60/day" -ForegroundColor Red
    Write-Host "   📆 Combined cost per MONTH: ~$2,800/month (if left running 24/7)" -ForegroundColor Red
    Write-Host "   ⏰ With auto-shutdown after 1 hour idle: ~$75/month" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⚠️ ⚠️ ⚠️  EMERGENCY STARTUP WILL INCUR SIGNIFICANT COSTS! ⚠️ ⚠️ ⚠️" -ForegroundColor Red -BackgroundColor White
    Write-Host "💡 CRITICAL: Monitor costs and use auto-shutdown to prevent runaway charges" -ForegroundColor Cyan
    Write-Host ""
    
    $costConfirmation = Read-Host "Do you accept the estimated cost of ~$3.90/hour for ALL environments? Type 'Yes' to accept"
    if ($costConfirmation -ne "Yes") {
        Write-Host "❌ Emergency startup cancelled - cost not accepted" -ForegroundColor Red
        exit 0
    }
    
    Write-Host "Are you performing disaster recovery or emergency startup? (yes/no)"
    $emergency = Read-Host
    if ($emergency -ne "yes") {
        Write-Host "❌ Emergency startup cancelled" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "Type 'EMERGENCY-START-ALL-ENVIRONMENTS' to confirm:"
    $confirmation = Read-Host
    if ($confirmation -ne "EMERGENCY-START-ALL-ENVIRONMENTS") {
        Write-Host "❌ Emergency startup cancelled" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "🚀 Starting emergency startup of all environments..." -ForegroundColor Green

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "❌ Not logged into Azure CLI. Please run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Azure CLI authenticated" -ForegroundColor Green

$azdVersion = azd version 2>$null
if (-not $azdVersion) {
    Write-Host "❌ Azure Developer CLI not found. Please install azd first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Azure Developer CLI available" -ForegroundColor Green

# Start all environment startups in parallel for fastest recovery
Write-Host "⚡ Executing all environment startup scripts in parallel..." -ForegroundColor Green

$jobs = @()

# Start IT environment startup
$jobs += Start-Job -ScriptBlock {
    param($Force)
    & ".\infra\scripts\startup\complete-startup-it.ps1" $(if($Force) { "-Force" })
} -ArgumentList $Force

# Start QA environment startup  
$jobs += Start-Job -ScriptBlock {
    param($Force)
    & ".\infra\scripts\startup\complete-startup-qa.ps1" $(if($Force) { "-Force" })
} -ArgumentList $Force

# Start Production environment startup
$jobs += Start-Job -ScriptBlock {
    param($Force)
    & ".\infra\scripts\startup\complete-startup-prod.ps1" $(if($Force) { "-Force" })
} -ArgumentList $Force

Write-Host "⚡ All startup jobs initiated. Waiting for completion..." -ForegroundColor Green
Write-Host "   📊 Job 1: IT Environment Startup" -ForegroundColor Cyan
Write-Host "   📊 Job 2: QA Environment Startup" -ForegroundColor Cyan  
Write-Host "   📊 Job 3: Production Environment Startup" -ForegroundColor Cyan

# Monitor job progress
$completedJobs = 0
$totalJobs = $jobs.Count

do {
    Start-Sleep -Seconds 30
    $runningJobs = $jobs | Where-Object { $_.State -eq "Running" }
    $finishedJobs = $jobs | Where-Object { $_.State -eq "Completed" -or $_.State -eq "Failed" }
    
    $completedJobs = $finishedJobs.Count
    $runningCount = $runningJobs.Count
    
    Write-Host "⏳ Progress: $completedJobs/$totalJobs environments completed, $runningCount still running..." -ForegroundColor Yellow
    
} while ($runningJobs.Count -gt 0)

Write-Host "🏁 All startup jobs completed! Collecting results..." -ForegroundColor Green

# Collect and display job results
$successCount = 0
$failureCount = 0

for ($i = 0; $i -lt $jobs.Count; $i++) {
    $job = $jobs[$i]
    $jobOutput = Receive-Job -Job $job
    
    $envName = switch ($i) {
        0 { "IT Environment" }
        1 { "QA Environment" }
        2 { "Production Environment" }
    }
    
    if ($job.State -eq "Completed") {
        Write-Host "✅ $envName: SUCCESSFUL" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "❌ $envName: FAILED" -ForegroundColor Red
        $failureCount++
        Write-Host "Error details:" -ForegroundColor Red
        Write-Host $jobOutput -ForegroundColor Red
    }
    
    Remove-Job -Job $job
}

# Final summary
Write-Host ""
Write-Host "📋 Emergency Startup Summary:" -ForegroundColor Green
Write-Host "✅ Successful environments: $successCount/$totalJobs" -ForegroundColor Green
Write-Host "❌ Failed environments: $failureCount/$totalJobs" -ForegroundColor Red
Write-Host "💰 Combined hourly cost: ~$3.90/hour" -ForegroundColor Yellow
Write-Host "⏰ Auto-shutdown enabled on all environments (1 hour idle)" -ForegroundColor Cyan

if ($successCount -eq $totalJobs) {
    Write-Host ""
    Write-Host "🎉 EMERGENCY STARTUP COMPLETE - ALL ENVIRONMENTS RUNNING! 🎉" -ForegroundColor Green -BackgroundColor Black
    Write-Host "💡 Monitor Azure costs and use shutdown scripts when environments not needed" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "⚠️  Some environments failed to start. Check individual logs and retry if needed." -ForegroundColor Yellow
    Write-Host "💡 You can run individual startup scripts for failed environments" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🚨 EMERGENCY STARTUP PROCESS COMPLETE 🚨" -ForegroundColor Green -BackgroundColor Black
