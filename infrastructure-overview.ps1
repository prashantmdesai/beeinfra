#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete infrastructure overview for Beeux Azure environments.

.DESCRIPTION
    This script provides a comprehensive overview of all available infrastructure
    scripts, Azure Bicep templates, and deployment options for the Beeux
    spelling bee application across IT, QA, and Production environments.
#>

Write-Host "🏗️  BEEUX AZURE INFRASTRUCTURE OVERVIEW" -ForegroundColor Green -BackgroundColor Black
Write-Host "=======================================" -ForegroundColor Green

Write-Host ""
Write-Host "🔒 HTTPS-ONLY SECURITY ENFORCEMENT:" -ForegroundColor Red -BackgroundColor Yellow
Write-Host "ALL web traffic is enforced to use HTTPS with TLS 1.2+ encryption" -ForegroundColor Red
Write-Host "HTTP requests are automatically redirected to HTTPS" -ForegroundColor Red
Write-Host "Security headers (HSTS, CSP) are enforced on all endpoints" -ForegroundColor Red

Write-Host ""
Write-Host "📋 ENVIRONMENT SUMMARY:" -ForegroundColor Cyan
Write-Host "IT Environment:         Cost-optimized development + HTTPS enforcement (~$0.50/hour, ~$10/month)" -ForegroundColor Yellow
Write-Host "QA Environment:         Security-focused testing + Enhanced HTTPS (~$1.10/hour, ~$20/month)" -ForegroundColor Yellow  
Write-Host "Production Environment: Enterprise-grade + Maximum HTTPS security (~$2.30/hour, ~$30/month)" -ForegroundColor Yellow

Write-Host ""
Write-Host "🔧 INFRASTRUCTURE AS CODE (IaC):" -ForegroundColor Cyan
Write-Host "📁 Main Bicep Template:  .\infra\main.bicep" -ForegroundColor Gray
Write-Host "📁 Parameters File:      .\infra\main.parameters.json" -ForegroundColor Gray
Write-Host "📁 Azure Project:        .\azure.yaml (AZD configuration)" -ForegroundColor Gray
Write-Host "📁 Bicep Modules:        .\infra\modules\ (reusable components)" -ForegroundColor Gray

Write-Host ""
Write-Host "🚀 STARTUP SCRIPTS (Create and start environments):" -ForegroundColor Green
Write-Host "IT Environment:          .\infra\scripts\startup\complete-startup-it.ps1" -ForegroundColor Gray
Write-Host "QA Environment:          .\infra\scripts\startup\complete-startup-qa.ps1" -ForegroundColor Gray
Write-Host "Production Environment:  .\infra\scripts\startup\complete-startup-prod.ps1" -ForegroundColor Gray
Write-Host "Emergency Startup All:   .\infra\scripts\emergency\emergency-startup-all.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "🛑 SHUTDOWN SCRIPTS (Stop and delete environments for $0 cost):" -ForegroundColor Red
Write-Host "IT Environment:          .\infra\scripts\shutdown\complete-shutdown-it.ps1" -ForegroundColor Gray
Write-Host "QA Environment:          .\infra\scripts\shutdown\complete-shutdown-qa.ps1" -ForegroundColor Gray
Write-Host "Production Environment:  .\infra\scripts\shutdown\complete-shutdown-prod.ps1" -ForegroundColor Gray
Write-Host "Emergency Shutdown All:  .\infra\scripts\emergency\emergency-shutdown-all.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "🔧 UTILITY SCRIPTS (Configure features):" -ForegroundColor Cyan
Write-Host "Cost Monitoring:         .\infra\scripts\utilities\setup-cost-alerts.ps1" -ForegroundColor Gray
Write-Host "Auto-Shutdown:           .\infra\scripts\utilities\setup-auto-shutdown.ps1" -ForegroundColor Gray
Write-Host "Security Features:       .\infra\scripts\utilities\setup-security-features.ps1" -ForegroundColor Gray
Write-Host "Auto-Scaling:            .\infra\scripts\utilities\setup-autoscaling.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "�️ DEVELOPER VMs (Linux VMs with pre-installed tools):" -ForegroundColor Magenta
Write-Host "VM Access Setup:         .\setup-developer-vm-access.ps1" -ForegroundColor Gray
Write-Host "IT VM Specs:             Standard_B2s (2 vCPUs, 4GB RAM) + VS Code Server" -ForegroundColor Gray
Write-Host "QA VM Specs:             Standard_D2s_v3 (2 vCPUs, 8GB RAM) + VS Code Server" -ForegroundColor Gray
Write-Host "Prod VM Specs:           Standard_D4s_v3 (4 vCPUs, 16GB RAM) + VS Code Server" -ForegroundColor Gray
Write-Host "Pre-installed Tools:     Azure CLI, GitHub CLI, Git, Docker, Node.js, Python, .NET, PowerShell, Terraform" -ForegroundColor Gray

Write-Host ""
Write-Host "�📚 DOCUMENTATION:" -ForegroundColor Cyan
Write-Host "Infrastructure Guide:    .\infra-instructions-updated.md" -ForegroundColor Gray
Write-Host "Original Instructions:   .\infra-instructions.md" -ForegroundColor Gray

Write-Host ""
Write-Host "🎯 QUICK START EXAMPLES:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1️⃣ Deploy IT Environment (Development):" -ForegroundColor Green
Write-Host "   azd env select it" -ForegroundColor Gray
Write-Host "   azd up" -ForegroundColor Gray
Write-Host "   💰 Cost: ~$10/month with auto-shutdown" -ForegroundColor Green
Write-Host ""

Write-Host "2️⃣ Deploy QA Environment (Testing):" -ForegroundColor Green
Write-Host "   azd env select qa" -ForegroundColor Gray
Write-Host "   azd up" -ForegroundColor Gray
Write-Host "   💰 Cost: ~$20/month with security features" -ForegroundColor Green
Write-Host ""

Write-Host "3️⃣ Deploy Production Environment:" -ForegroundColor Green
Write-Host "   azd env select prod" -ForegroundColor Gray
Write-Host "   azd up" -ForegroundColor Gray
Write-Host "   💰 Cost: ~$30/month with enterprise features" -ForegroundColor Green
Write-Host ""

Write-Host "4️⃣ Emergency Shutdown (All Environments):" -ForegroundColor Red
Write-Host "   .\infra\scripts\emergency\emergency-shutdown-all.ps1" -ForegroundColor Gray
Write-Host "   💰 Savings: Stop ~$3.90/hour charges immediately" -ForegroundColor Green
Write-Host ""

Write-Host "💡 COST MANAGEMENT FEATURES:" -ForegroundColor Yellow
Write-Host "✅ Automatic budget alerts at 50%, 80%, 100% thresholds" -ForegroundColor Green
Write-Host "✅ Auto-shutdown after 1 hour of inactivity" -ForegroundColor Green
Write-Host "✅ Complete resource deletion scripts for $0 monthly cost" -ForegroundColor Green
Write-Host "✅ SMS and email notifications for cost overruns" -ForegroundColor Green
Write-Host "✅ Hourly cost estimation and tracking" -ForegroundColor Green

Write-Host ""
Write-Host "🔒 SECURITY FEATURES BY ENVIRONMENT:" -ForegroundColor Yellow
Write-Host ""
Write-Host "IT (Basic Security):" -ForegroundColor Cyan
Write-Host "  ✅ Key Vault for secrets" -ForegroundColor Green
Write-Host "  ✅ Managed Identity" -ForegroundColor Green
Write-Host "  ✅ HTTPS enforcement" -ForegroundColor Green
Write-Host "  ✅ API Management (Developer tier)" -ForegroundColor Green
Write-Host ""

Write-Host "QA (Enhanced Security):" -ForegroundColor Cyan
Write-Host "  ✅ All IT features plus:" -ForegroundColor Green
Write-Host "  ✅ Private endpoints" -ForegroundColor Green
Write-Host "  ✅ Web Application Firewall" -ForegroundColor Green
Write-Host "  ✅ Network Security Groups" -ForegroundColor Green
Write-Host "  ✅ API Management (Standard tier)" -ForegroundColor Green
Write-Host "  ✅ Advanced threat protection" -ForegroundColor Green
Write-Host ""

Write-Host "Production (Enterprise Security):" -ForegroundColor Cyan
Write-Host "  ✅ All QA features plus:" -ForegroundColor Green
Write-Host "  ✅ Premium Key Vault with HSM" -ForegroundColor Green
Write-Host "  ✅ DDoS Protection" -ForegroundColor Green
Write-Host "  ✅ Premium WAF with custom rules" -ForegroundColor Green
Write-Host "  ✅ API Management (Premium tier)" -ForegroundColor Green
Write-Host "  ✅ Content trust and integrity" -ForegroundColor Green
Write-Host "  ✅ Advanced monitoring and alerting" -ForegroundColor Green

Write-Host ""
Write-Host "📈 AUTO-SCALING CONFIGURATION:" -ForegroundColor Yellow
Write-Host "IT:          Fixed resources (cost optimization)" -ForegroundColor Gray
Write-Host "QA:          1-5 instances based on CPU/memory/requests" -ForegroundColor Gray
Write-Host "Production:  2-10 instances with advanced metrics and business hours scaling" -ForegroundColor Gray

Write-Host ""
Write-Host "🌐 AZURE SERVICES INCLUDED:" -ForegroundColor Yellow
Write-Host "✅ Azure App Service (Angular frontend)" -ForegroundColor Green
Write-Host "✅ Azure Container Apps (Spring Boot API)" -ForegroundColor Green
Write-Host "✅ Azure Database for PostgreSQL (QA/Prod) or Self-hosted (IT)" -ForegroundColor Green
Write-Host "✅ Azure Blob Storage (audio files)" -ForegroundColor Green
Write-Host "✅ Azure Container Registry (Docker images)" -ForegroundColor Green
Write-Host "✅ Azure Key Vault (secrets management)" -ForegroundColor Green
Write-Host "✅ Azure API Management (REST API gateway)" -ForegroundColor Green
Write-Host "✅ Azure Application Insights (monitoring)" -ForegroundColor Green
Write-Host "✅ Azure Log Analytics (logging)" -ForegroundColor Green
Write-Host "✅ Azure Application Gateway + WAF (security)" -ForegroundColor Green
Write-Host "✅ Azure CDN (Production performance)" -ForegroundColor Green
Write-Host "✅ Azure Automation (auto-shutdown)" -ForegroundColor Green
Write-Host "✅ Linux Developer VMs (Ubuntu 22.04 with development tools)" -ForegroundColor Green
Write-Host "🔒 HTTPS-ONLY ENFORCEMENT: All services configured for HTTPS with TLS 1.2+" -ForegroundColor Red

Write-Host ""
Write-Host "⚡ NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Set up SSH access: .\setup-developer-vm-access.ps1" -ForegroundColor Cyan
Write-Host "2. Choose an environment to deploy (it/qa/prod)" -ForegroundColor Cyan
Write-Host "3. Run 'azd auth login' to authenticate with Azure" -ForegroundColor Cyan
Write-Host "4. Run 'azd env select <environment>' to choose environment" -ForegroundColor Cyan
Write-Host "5. Run 'azd up' to deploy HTTPS-only infrastructure and applications" -ForegroundColor Cyan
Write-Host "6. Connect to your Developer VM using HTTPS: https://VM_IP:8080" -ForegroundColor Cyan
Write-Host "7. All web services will be accessible via HTTPS URLs only" -ForegroundColor Cyan
Write-Host "8. Monitor costs and use shutdown scripts when needed" -ForegroundColor Cyan

Write-Host ""
Write-Host "📞 COST EMERGENCY CONTACTS:" -ForegroundColor Red
Write-Host "Primary Email:   prashantmdesai@yahoo.com" -ForegroundColor Gray
Write-Host "Secondary Email: prashantmdesai@hotmail.com" -ForegroundColor Gray
Write-Host "SMS Alerts:      +12246564855" -ForegroundColor Gray

Write-Host ""
Write-Host "🏗️  INFRASTRUCTURE READY FOR DEPLOYMENT! 🏗️" -ForegroundColor Green -BackgroundColor Black
