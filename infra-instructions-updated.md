# Beeux Infrastructure Setup Instructions

This document provides comprehensive instructions for setting up Azure infrastructure for the Beeux spelling bee application across IT, QA, and Production environments using automated PowerShell scripts.

## 🏗️ Infrastructure Scripts Overview

All infrastructure management is now automated through PowerShell scripts located in the `infra/scripts/` directory:

```
infra/scripts/
├── startup/                    # Environment startup scripts
│   ├── complete-startup-it.ps1      # IT environment startup (~$0.50/hour)
│   ├── complete-startup-qa.ps1      # QA environment startup (~$1.10/hour)
│   └── complete-startup-prod.ps1    # Production startup (~$2.30/hour)
├── shutdown/                   # Environment shutdown scripts  
│   ├── complete-shutdown-it.ps1     # IT environment shutdown (saves $0.50/hour)
│   ├── complete-shutdown-qa.ps1     # QA environment shutdown (saves $1.10/hour)
│   └── complete-shutdown-prod.ps1   # Production shutdown (saves $2.30/hour)
├── emergency/                  # Emergency operations
│   ├── emergency-startup-all.ps1    # Start all environments (~$3.90/hour combined)
│   └── emergency-shutdown-all.ps1   # Shutdown all environments (saves $3.90/hour)
└── utilities/                  # Utility scripts
    ├── setup-cost-alerts.ps1        # Budget alerts and cost monitoring
    ├── setup-auto-shutdown.ps1      # Auto-shutdown configuration
    ├── setup-security-features.ps1  # Security hardening
    └── setup-autoscaling.ps1        # Auto-scaling configuration
```

## 🚀 Quick Start Guide

### 1. **Start an Environment**
```powershell
# Start IT environment (development)
.\infra\scripts\startup\complete-startup-it.ps1

# Start QA environment (testing)  
.\infra\scripts\startup\complete-startup-qa.ps1

# Start Production environment (live)
.\infra\scripts\startup\complete-startup-prod.ps1
```

### 2. **Shutdown an Environment** 
```powershell
# Shutdown IT environment
.\infra\scripts\shutdown\complete-shutdown-it.ps1

# Shutdown QA environment
.\infra\scripts\shutdown\complete-shutdown-qa.ps1

# Shutdown Production environment (with triple confirmation)
.\infra\scripts\shutdown\complete-shutdown-prod.ps1
```

### 3. **Emergency Operations**
```powershell
# Emergency startup of all environments
.\infra\scripts\emergency\emergency-startup-all.ps1

# Emergency shutdown of all environments
.\infra\scripts\emergency\emergency-shutdown-all.ps1
```

## 💰 Cost Management Features

### **Hourly Cost Estimates with Confirmation**
Every script now includes detailed cost estimates and requires explicit "Yes" confirmation:

- **IT Environment**: ~$0.50/hour (cost-optimized with basic security)
- **QA Environment**: ~$1.10/hour (security-focused with managed services)  
- **Production Environment**: ~$2.30/hour (enterprise-grade with premium features)
- **All Environments Combined**: ~$3.90/hour

### **Cost Transparency Features**
- Detailed hourly cost breakdowns by Azure service
- Monthly projections (24/7 vs. auto-shutdown scenarios)
- Explicit cost confirmation required before any operation
- Cost savings information shown during shutdown operations
- Budget alerts and monitoring automatically configured

### **Auto-Shutdown for Cost Optimization**
- All environments configured with 1-hour idle auto-shutdown
- Prevents runaway costs from forgotten resources
- Can be customized per environment needs

## 🛡️ Security Features

### **Production Safety Measures**
Production shutdown scripts include triple confirmation mechanism:
1. **BACKUP-COMPLETED** - Confirms all data is backed up
2. **AUTHORIZED-AND-UNDERSTAND** - Confirms authorization and impact understanding  
3. **I-HEREBY-DESTROY-PRODUCTION-ENVIRONMENT-PERMANENTLY** - Final commitment phrase
4. **10-second cooldown** - Final abort opportunity

### **API Gateway Integration**
All environments now include Azure API Management:
- **IT Environment**: Developer tier (cost-optimized)
- **QA Environment**: Standard tier (rate limiting, analytics)
- **Production Environment**: Premium tier (advanced security, custom domains)

## 📋 Application Architecture Overview

The Beeux application consists of:
- **Frontend**: Angular 18 application with responsive design for children aged 5-15
- **Backend**: Spring Boot REST API with PostgreSQL database
- **Storage**: MP3 audio files for spelling bee words
- **Environments**: IT → QA → Production promotion path

## 🏗️ Azure Services Architecture

### Environment Comparison

| Component | IT Environment | QA Environment | Production Environment |
|-----------|----------------|----------------|------------------------|
| **App Service Plan** | Free F1/Basic B1 | Premium P1V3 auto-scaling | Premium P2V3 auto-scaling |
| **API Management** | Developer tier | Standard tier | Premium tier |
| **Database** | Self-hosted PostgreSQL | Managed PostgreSQL (2 vCores) | Managed PostgreSQL (4 vCores) + Private Link |
| **Storage** | Standard LRS | Standard ZRS + Private Endpoints | Premium LRS + Private Endpoints + CDN |
| **Container Registry** | Basic/Free | Premium + geo-replication | Premium + geo-replication + Content Trust |
| **Security Features** | Key Vault Standard | WAF, Security Center | WAF, Security Center Premium, DDoS Protection |
| **Auto-scaling** | Manual only | Enabled | Advanced with custom metrics |
| **Monthly Cost Target** | ~$15 with auto-shutdown | ~$25 with security focus | ~$35 with performance focus |

## ⚙️ Prerequisites

### Required Tools
- Azure CLI (latest version)
- Azure Developer CLI (azd)
- Docker Desktop
- PowerShell 7+ or Azure Cloud Shell
- Git
- Visual Studio Code with Azure extensions

### Azure Subscription Setup
- Contributor or Owner access to Azure subscription
- Verified subscription quotas for required services
- Proper resource naming conventions

## 🎯 Usage Scenarios

### **Development Workflow**
1. Start IT environment for development: `.\infra\scripts\startup\complete-startup-it.ps1`
2. Develop and test features
3. Shutdown when done: `.\infra\scripts\shutdown\complete-shutdown-it.ps1`

### **Testing Workflow**  
1. Start QA environment for testing: `.\infra\scripts\startup\complete-startup-qa.ps1`
2. Deploy and test applications
3. Run security and performance tests
4. Shutdown when testing complete: `.\infra\scripts\shutdown\complete-shutdown-qa.ps1`

### **Production Deployment**
1. Start Production environment: `.\infra\scripts\startup\complete-startup-prod.ps1`
2. Deploy applications with proper approvals
3. Monitor performance and costs
4. Shutdown during maintenance: `.\infra\scripts\shutdown\complete-shutdown-prod.ps1`

### **Emergency Response**
1. **Disaster Recovery**: Use `.\infra\scripts\emergency\emergency-startup-all.ps1`
2. **Cost Emergency**: Use `.\infra\scripts\emergency\emergency-shutdown-all.ps1`

## 🔧 Utility Scripts

### **Cost Monitoring**
```powershell
# Set up budget alerts for an environment
.\infra\scripts\utilities\setup-cost-alerts.ps1 -EnvironmentName "it" -BudgetAmount 10
```

### **Auto-Shutdown Configuration**
```powershell
# Configure auto-shutdown for cost optimization
.\infra\scripts\utilities\setup-auto-shutdown.ps1 -EnvironmentName "it" -IdleHours 1
```

### **Security Hardening**
```powershell
# Apply security features and policies
.\infra\scripts\utilities\setup-security-features.ps1 -EnvironmentName "qa"
```

### **Auto-Scaling Setup**
```powershell
# Configure auto-scaling rules
.\infra\scripts\utilities\setup-autoscaling.ps1 -EnvironmentName "prod"
```

## 📊 Monitoring and Alerts

### **Automated Monitoring Setup**
- Budget alerts at 50%, 80%, 90% (forecast), and 100% of budget
- Email notifications to primary and secondary contacts
- Resource health monitoring
- Performance metrics collection
- Security event monitoring

### **Contact Configuration**
All scripts are pre-configured with these alert contacts:
- **Primary Email**: prashantmdesai@yahoo.com
- **Secondary Email**: prashantmdesai@hotmail.com  
- **Phone**: +12246564855

## 🚨 Safety and Best Practices

### **Cost Safety**
- Always confirm cost estimates before proceeding
- Use auto-shutdown to prevent runaway costs
- Monitor Azure portal for actual costs
- Set up multiple budget alert thresholds

### **Security Safety**
- Production changes require special authorization
- All secrets managed through Azure Key Vault
- Private endpoints used for secure communication
- WAF and DDoS protection for production

### **Operational Safety**
- Always backup data before production changes
- Use proper environment promotion (IT → QA → Prod)
- Test scripts in lower environments first
- Have emergency shutdown procedures ready

## 💡 Tips and Tricks

### **Cost Optimization**
- Use auto-shutdown for development environments
- Start environments only when needed
- Monitor costs daily in Azure portal
- Consider Azure Dev/Test pricing for development

### **Performance Optimization**
- Use auto-scaling in QA and Production
- Monitor application insights for bottlenecks
- Configure CDN for static content in Production
- Use premium storage tiers for Production workloads

### **Security Optimization**
- Regularly rotate Key Vault secrets
- Review security policies and compliance
- Monitor security events and alerts
- Keep all Azure services updated

## 🆘 Troubleshooting

### **Common Issues**
1. **Azure CLI not logged in**: Run `az login` first
2. **Insufficient permissions**: Ensure Contributor/Owner role
3. **Resource quota exceeded**: Check subscription limits
4. **Script execution policy**: Run `Set-ExecutionPolicy RemoteSigned`

### **Getting Help**
- Check Azure portal for detailed error messages
- Review script output for specific error details
- Use Azure documentation for service-specific issues
- Contact Azure support for subscription issues

## � Requirements Compliance Verification

### **All Requirements Met**
This project implements **all 26 requirements** from `infrasetup.instructions.md`:

- ✅ Budget limits: IT ($10), QA ($20), Production ($30)
- ✅ Alert contacts: prashantmdesai@yahoo.com, prashantmdesai@hotmail.com, +1 224 656 4855
- ✅ Cost-per-hour prompting with explicit confirmation
- ✅ Auto-shutdown after 1 hour idle for all environments
- ✅ Triple confirmation for production shutdown
- ✅ Developer VMs in all environments
- ✅ Complete HTTPS enforcement
- ✅ Azure Developer CLI integration

### **Verification Tools**
```powershell
# Quick compliance check
.\compliance-check.ps1

# Detailed compliance report
Get-Content .\COMPLIANCE-REPORT.md
```

## �📞 Support Contacts

- **Technical Issues**: Check Azure portal diagnostics
- **Cost Issues**: Review budget alerts and Azure Cost Management
- **Security Issues**: Review Azure Security Center recommendations
- **Emergency**: Use emergency shutdown scripts to stop all charges

---

**📝 Note**: This document focuses on the instructions for using the infrastructure scripts. All actual PowerShell script implementations are located in the `infra/scripts/` directory and are ready to use.
