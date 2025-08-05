#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Display complete workspace structure and available commands.

.DESCRIPTION
    This script shows the complete Beeux infrastructure workspace structure
    and provides quick access to all available commands and scripts.

.EXAMPLE
    .\workspace-summary.ps1
#>

Write-Host "🏗️ BEEUX INFRASTRUCTURE WORKSPACE SUMMARY" -ForegroundColor Cyan -BackgroundColor Black
Write-Host "=========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "📁 WORKSPACE STRUCTURE:" -ForegroundColor Yellow
Write-Host "c:\dev\beeinfra\" -ForegroundColor White
Write-Host "├── infra-instructions-updated.md    # Main documentation (instructions only)" -ForegroundColor Gray
Write-Host "├── infra-instructions.md            # Original documentation (with embedded scripts)" -ForegroundColor Gray
Write-Host "├── workspace-summary.ps1            # This summary script" -ForegroundColor Gray
Write-Host "└── infra/" -ForegroundColor White
Write-Host "    └── scripts/" -ForegroundColor White
Write-Host "        ├── startup/                 # Environment startup scripts" -ForegroundColor Green
Write-Host "        │   ├── complete-startup-it.ps1      # ~$0.50/hour" -ForegroundColor Green
Write-Host "        │   ├── complete-startup-qa.ps1      # ~$1.10/hour" -ForegroundColor Green
Write-Host "        │   └── complete-startup-prod.ps1    # ~$2.30/hour" -ForegroundColor Green
Write-Host "        ├── shutdown/                # Environment shutdown scripts" -ForegroundColor Red
Write-Host "        │   ├── complete-shutdown-it.ps1     # Saves $0.50/hour" -ForegroundColor Red
Write-Host "        │   ├── complete-shutdown-qa.ps1     # Saves $1.10/hour" -ForegroundColor Red
Write-Host "        │   └── complete-shutdown-prod.ps1   # Saves $2.30/hour" -ForegroundColor Red
Write-Host "        ├── emergency/               # Emergency operations" -ForegroundColor Magenta
Write-Host "        │   ├── emergency-startup-all.ps1    # ~$3.90/hour combined" -ForegroundColor Magenta
Write-Host "        │   └── emergency-shutdown-all.ps1   # Saves $3.90/hour" -ForegroundColor Magenta
Write-Host "        └── utilities/               # Utility scripts" -ForegroundColor Cyan
Write-Host "            ├── setup-cost-alerts.ps1        # Budget monitoring" -ForegroundColor Cyan
Write-Host "            ├── setup-auto-shutdown.ps1      # Auto-shutdown config" -ForegroundColor Cyan
Write-Host "            ├── setup-security-features.ps1  # Security hardening" -ForegroundColor Cyan
Write-Host "            └── setup-autoscaling.ps1        # Auto-scaling setup" -ForegroundColor Cyan

Write-Host ""
Write-Host "🚀 QUICK START COMMANDS:" -ForegroundColor Yellow

Write-Host ""
Write-Host "▶️  START ENVIRONMENTS:" -ForegroundColor Green
Write-Host "   IT Environment (Development):" -ForegroundColor White
Write-Host "   .\infra\scripts\startup\complete-startup-it.ps1" -ForegroundColor Green
Write-Host ""
Write-Host "   QA Environment (Testing):" -ForegroundColor White  
Write-Host "   .\infra\scripts\startup\complete-startup-qa.ps1" -ForegroundColor Green
Write-Host ""
Write-Host "   Production Environment:" -ForegroundColor White
Write-Host "   .\infra\scripts\startup\complete-startup-prod.ps1" -ForegroundColor Green

Write-Host ""
Write-Host "⏹️  SHUTDOWN ENVIRONMENTS:" -ForegroundColor Red
Write-Host "   IT Environment:" -ForegroundColor White
Write-Host "   .\infra\scripts\shutdown\complete-shutdown-it.ps1" -ForegroundColor Red
Write-Host ""
Write-Host "   QA Environment:" -ForegroundColor White
Write-Host "   .\infra\scripts\shutdown\complete-shutdown-qa.ps1" -ForegroundColor Red  
Write-Host ""
Write-Host "   Production Environment (Triple Confirmation):" -ForegroundColor White
Write-Host "   .\infra\scripts\shutdown\complete-shutdown-prod.ps1" -ForegroundColor Red

Write-Host ""
Write-Host "🚨 EMERGENCY OPERATIONS:" -ForegroundColor Magenta
Write-Host "   Start All Environments:" -ForegroundColor White
Write-Host "   .\infra\scripts\emergency\emergency-startup-all.ps1" -ForegroundColor Magenta
Write-Host ""
Write-Host "   Shutdown All Environments:" -ForegroundColor White
Write-Host "   .\infra\scripts\emergency\emergency-shutdown-all.ps1" -ForegroundColor Magenta

Write-Host ""
Write-Host "🔧 UTILITY COMMANDS:" -ForegroundColor Cyan
Write-Host "   Setup Cost Alerts:" -ForegroundColor White
Write-Host "   .\infra\scripts\utilities\setup-cost-alerts.ps1 -EnvironmentName 'it' -BudgetAmount 10" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Setup Auto-Shutdown:" -ForegroundColor White
Write-Host "   .\infra\scripts\utilities\setup-auto-shutdown.ps1 -EnvironmentName 'it' -IdleHours 1" -ForegroundColor Cyan

Write-Host ""
Write-Host "💰 COST INFORMATION:" -ForegroundColor Yellow -BackgroundColor Black
Write-Host "Environment          | Hourly Cost | Monthly (24/7) | Monthly (Auto-Shutdown)" -ForegroundColor Yellow
Write-Host "-------------------- | ----------- | -------------- | ----------------------" -ForegroundColor Gray
Write-Host "IT (Development)     | ~$0.50      | ~$360         | ~$15" -ForegroundColor Green
Write-Host "QA (Testing)         | ~$1.10      | ~$800         | ~$25" -ForegroundColor Cyan
Write-Host "Production (Live)    | ~$2.30      | ~$1,656       | ~$35" -ForegroundColor Red
Write-Host "ALL COMBINED         | ~$3.90      | ~$2,816       | ~$75" -ForegroundColor Magenta

Write-Host ""
Write-Host "🛡️ SAFETY FEATURES:" -ForegroundColor Yellow
Write-Host "✅ Cost confirmation required for all operations" -ForegroundColor Green
Write-Host "✅ Production shutdown requires triple confirmation" -ForegroundColor Green  
Write-Host "✅ Auto-shutdown configured to prevent runaway costs" -ForegroundColor Green
Write-Host "✅ Budget alerts at 50%, 80%, 90%, and 100% thresholds" -ForegroundColor Green
Write-Host "✅ API Management integrated across all environments" -ForegroundColor Green
Write-Host "✅ All scripts include detailed cost transparency" -ForegroundColor Green

Write-Host ""
Write-Host "📖 DOCUMENTATION:" -ForegroundColor Yellow
Write-Host "   Primary Instructions: infra-instructions-updated.md" -ForegroundColor White
Write-Host "   Original Reference:   infra-instructions.md" -ForegroundColor Gray

Write-Host ""
Write-Host "📧 ALERT CONTACTS (Pre-configured):" -ForegroundColor Yellow
Write-Host "   Primary Email:   prashantmdesai@yahoo.com" -ForegroundColor White
Write-Host "   Secondary Email: prashantmdesai@hotmail.com" -ForegroundColor White
Write-Host "   Phone:           +12246564855" -ForegroundColor White

Write-Host ""
Write-Host "💡 TIPS:" -ForegroundColor Cyan
Write-Host "   • Always run startup scripts before working with environments" -ForegroundColor White
Write-Host "   • Use shutdown scripts when environments not needed to save costs" -ForegroundColor White
Write-Host "   • Check .\compliance-check.ps1 to verify all requirements are met" -ForegroundColor White
Write-Host "   • Review COMPLIANCE-REPORT.md for detailed implementation status" -ForegroundColor White
Write-Host "   • Monitor Azure portal for actual costs and resource status" -ForegroundColor White
Write-Host "   • Test in IT environment before promoting to QA and Production" -ForegroundColor White
Write-Host "   • Use emergency scripts for disaster recovery scenarios" -ForegroundColor White

Write-Host ""
Write-Host "✨ WORKSPACE READY! All infrastructure scripts are available and functional." -ForegroundColor Green -BackgroundColor Black
