# BeeInfra - Azure Infrastructure as Code with Terraform

## 🎯 Project Overview

**BeeInfra** is a comprehensive Azure infrastructure setup designed for a typical web application with Angular frontend, REST APIs, and PostgreSQL database. This project provides Infrastructure as Code (IaC) templates using **Terraform** and automation scripts for deploying across three environments: **IT**, **QA**, and **Production**.

## 🔄 Migration from Bicep to Terraform

This project has been **migrated from Azure Bicep to Terraform** to provide:

### ✅ **Enhanced Capabilities with Terraform**
- **Better State Management**: Automatic drift detection and state reconciliation
- **Enhanced Module Composition**: More reusable and composable infrastructure modules
- **Improved Dependency Management**: Parallel resource provisioning and smarter dependency resolution
- **Cross-Cloud Compatibility**: Future-ready for multi-cloud scenarios
- **Better Variable Validation**: Type-safe variables with comprehensive validation rules
- **Enhanced Error Handling**: Better rollback capabilities and error reporting

### 🏗️ **Terraform Architecture Advantages**
- **Infrastructure State Tracking**: Complete visibility into infrastructure changes
- **Plan and Apply Workflow**: Review changes before applying them
- **Modular Design**: Reusable modules across environments
- **Type Safety**: Strong typing and validation for all variables
- **Provider Ecosystem**: Access to hundreds of providers beyond Azure

## 🏗️ Architecture

```mermaid
graph TB
    subgraph "IT Environment (Cost-Optimized)"
        IT_FE[Angular Frontend<br/>App Service Free/B1]
        IT_API[Spring Boot API<br/>Container Apps Consumption]
        IT_DB[PostgreSQL<br/>Self-hosted/Burstable]
        IT_VM[Developer VM<br/>B1s]
    end
    
    subgraph "QA Environment (Security-Focused)"
        QA_FE[Angular Frontend<br/>App Service Premium P1V3]
        QA_API[Spring Boot API<br/>Container Apps Premium]
        QA_DB[PostgreSQL Managed<br/>B2s - 20% Production]
        QA_VM[Developer VM<br/>B2s]
        QA_WAF[Web Application Firewall]
    end
    
    subgraph "Production Environment (Enterprise-Grade)"
        PROD_FE[Angular Frontend<br/>App Service Premium P2V3]
        PROD_API[Spring Boot API<br/>Container Apps Premium]
        PROD_DB[PostgreSQL Managed<br/>D4s High-Performance]
        PROD_VM[Developer VM<br/>D2s]
        PROD_WAF[Premium WAF + DDoS]
        PROD_CDN[Azure CDN]
    end
    
    subgraph "Shared Services"
        KV[Azure Key Vault]
        STORAGE[Azure Storage]
        MONITOR[Azure Monitor]
        APIM[API Management]
    end
```

## 📋 Requirements Compliance

This infrastructure implements all requirements from `infrasetup.instructions.md`:

### 🔧 Environment Setup (Requirements 1-3)
- ✅ **IT Environment**: Free tier priority, cost-optimized resources
- ✅ **QA Environment**: Security-focused, 20% of production capacity  
- ✅ **Production Environment**: Enterprise-grade, high availability

### 💰 Cost Management (Requirements 4-11)
- ✅ **Budget Alerts**: $10 (IT), $20 (QA), $30 (Production)
- ✅ **Dual Monitoring**: Both estimated and actual cost alerts
- ✅ **Auto-shutdown**: 1-hour idle detection across all environments
- ✅ **Email Notifications**: prashantmdesai@yahoo.com, prashantmdesai@hotmail.com
- ✅ **SMS Alerts**: +1 224 656 4855

### 🔒 Security (Requirements 12-23)
- ✅ **Azure Key Vault**: All secrets management
- ✅ **HTTPS Enforcement**: All web traffic over HTTPS
- ✅ **Managed Identities**: No hardcoded credentials
- ✅ **WAF Protection**: Web Application Firewall in QA/Production
- ✅ **Private Endpoints**: Database and storage isolation

### 🖥️ Developer Access (Requirements 24-25)
- ✅ **Linux VMs**: One per environment with pre-installed tools
- ✅ **Tool Installation**: Azure CLI, GitHub CLI, Git, Docker, VS Code Server
- ✅ **Public IP Display**: Shown in startup script output

## 🚀 Quick Start

### Prerequisites
- Azure CLI installed and authenticated (`az login`)
- **Terraform 1.5.0+** installed ([Download Terraform](https://www.terraform.io/downloads.html))
- PowerShell 5.1+ or PowerShell Core
- Appropriate Azure subscription with Contributor access

### Deploy IT Environment (Cost-Optimized)
```powershell
# Navigate to project directory
cd c:\dev\beeinfra

# Deploy IT environment using Terraform (~$10/month budget)
.\infra\scripts\startup\complete-startup-it.ps1
```

### Deploy QA Environment (Security-Focused)
```powershell
# Deploy QA environment using Terraform (~$20/month budget) 
.\infra\scripts\startup\complete-startup-qa.ps1
```

### Deploy Production Environment (Enterprise-Grade)
```powershell
# Deploy Production environment using Terraform (~$30/month budget)
.\infra\scripts\startup\complete-startup-prod.ps1
```

## 📁 Project Structure

```
beeinfra/
├── 📁 .github/
│   └── instructions/
│       └── infrasetup.instructions.md          # Original requirements
├── 📁 terraform/                               # 🆕 Terraform Infrastructure (replaces infra/)
│   ├── main.tf                                 # Main Terraform configuration
│   ├── variables.tf                            # Variable definitions
│   ├── outputs.tf                              # Output definitions  
│   ├── providers.tf                            # Provider configuration
│   ├── 📁 modules/                             # Terraform modules
│   │   ├── identity/                           # Managed identity module
│   │   ├── networking/                         # Virtual network and networking
│   │   ├── keyvault/                          # Azure Key Vault module
│   │   ├── storage/                           # Storage account module
│   │   ├── postgresql/                        # PostgreSQL database module
│   │   ├── app_service/                       # App Service module (Angular frontend)
│   │   ├── container_apps/                    # Container Apps module (Spring Boot API)
│   │   ├── developer_vm/                     # Developer VM module
│   │   ├── budget_alerts/                     # Cost management module
│   │   └── ... (other modules)
│   └── 📁 environments/                        # Environment-specific configurations
│       ├── 📁 it/                             # IT environment Terraform config
│       │   ├── main.tf                        # IT environment entry point
│       │   ├── variables.tf                   # IT variable declarations
│       │   └── terraform.tfvars               # IT environment values
│       ├── 📁 qa/                             # QA environment Terraform config
│       └── 📁 prod/                           # Production environment Terraform config
├── 📁 infra/                                  # 🔄 Legacy Bicep files (being phased out)
│   ├── 📁 scripts/                            # 🆕 Updated automation scripts
│   │   ├── 📁 startup/                        # Environment startup scripts (updated for Terraform)
│   │   │   ├── complete-startup-it.ps1        # IT environment deployment (Terraform)
│   │   │   ├── complete-startup-qa.ps1        # QA environment deployment (Terraform)
│   │   │   └── complete-startup-prod.ps1      # Production deployment (Terraform)
│   │   ├── 📁 shutdown/                       # Environment shutdown scripts
│   │   │   ├── complete-shutdown-it.ps1       # IT environment teardown
│   │   │   ├── complete-shutdown-qa.ps1       # QA environment teardown
│   │   │   └── complete-shutdown-prod.ps1     # Production teardown
│   │   └── 📁 utilities/                      # Utility scripts
│   │       ├── setup-cost-alerts.ps1          # Budget alert configuration
│   │       ├── setup-auto-shutdown.ps1        # Auto-shutdown setup
│   │       ├── setup-autoscaling.ps1          # Autoscaling configuration
│   │       └── setup-security-features.ps1    # Security hardening
└── README.md                                  # This file
```

## 💰 Cost Breakdown

| Environment | Monthly Cost* | Key Features |
|-------------|---------------|--------------|
| **IT** | ~$15.84 | Free tier priority, self-hosted DB, basic security |
| **QA** | ~$55.44 | Managed services, WAF, private endpoints, autoscaling |
| **Production** | ~$138.72 | Enterprise features, DDoS protection, premium WAF, CDN |

*Costs shown are estimates for 24/7 operation. Auto-shutdown reduces costs significantly during idle periods.

## 🛠️ Key Features

### 🔄 Auto-Scaling
- **QA**: 2-4 instances based on load
- **Production**: 2-10 instances with aggressive scaling
- **Metrics**: CPU, Memory, HTTP queue length, response time

### 🔒 Security Features
- **Key Vault**: All secrets and certificates managed centrally
- **WAF**: Web Application Firewall with OWASP rules
- **Private Endpoints**: Database and storage isolated from internet
- **HTTPS Everywhere**: TLS 1.2+ enforced across all services
- **Managed Identity**: No hardcoded credentials anywhere

### 📊 Monitoring & Alerting
- **Cost Alerts**: Dual budget monitoring with Terraform-managed thresholds
- **Performance Monitoring**: Application Insights with custom metrics
- **Security Monitoring**: Azure Security Center with Terraform configuration
- **Infrastructure Monitoring**: Terraform state tracking and resource drift detection
- **Auto-shutdown**: Environment-specific scheduling via Terraform variables

### 🖥️ Developer Experience
- **VS Code Server**: Browser-based development environment
- **Pre-installed Tools**: Azure CLI, GitHub CLI, Docker, Git
- **Environment Isolation**: Separate VM per environment
- **SSH Access**: Direct terminal access to development VMs

## 📧 Support & Notifications

All alerts and notifications are sent to:
- **Primary Email**: prashantmdesai@yahoo.com
- **Secondary Email**: prashantmdesai@hotmail.com  
- **SMS**: +1 224 656 4855

## 🔧 Maintenance

### Environment Shutdown
```powershell
# Shutdown specific environment (with confirmations)
.\infra\scripts\shutdown\complete-shutdown-it.ps1
.\infra\scripts\shutdown\complete-shutdown-qa.ps1
.\infra\scripts\shutdown\complete-shutdown-prod.ps1  # Triple confirmation required
```

### Environment Restart
```powershell
# Restart from shutdown state using Terraform
.\infra\scripts\startup\complete-startup-{environment}.ps1
```

### Terraform Operations
```powershell
# Navigate to specific environment
cd terraform\environments\it  # or qa, prod

# Initialize Terraform (first time or after changes)
terraform init

# Plan infrastructure changes
terraform plan

# Apply infrastructure changes  
terraform apply

# View current state
terraform show

# Destroy infrastructure (equivalent to shutdown script)
terraform destroy
```

### Cost Management
```powershell
# Setup or modify budget alerts
.\infra\scripts\utilities\setup-cost-alerts.ps1 -EnvironmentName "qa" -BudgetAmount 25

# Configure auto-shutdown
.\infra\scripts\utilities\setup-auto-shutdown.ps1 -EnvironmentName "it" -IdleHours 2
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Make changes with appropriate documentation
4. Test in IT environment first
5. Submit pull request with detailed description

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Troubleshooting

### Common Issues

1. **Azure CLI Not Authenticated**
   ```powershell
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Terraform Not Installed**
   ```powershell
   # Windows (using Chocolatey)
   choco install terraform
   
   # Windows (using Scoop)
   scoop install terraform
   
   # Or download from: https://www.terraform.io/downloads.html
   ```

3. **Terraform Initialization Fails**
   ```powershell
   # Clear Terraform cache and reinitialize
   Remove-Item -Recurse -Force .terraform
   terraform init
   ```

4. **Terraform State Issues**
   ```powershell
   # View current state
   terraform show
   
   # Refresh state
   terraform refresh
   
   # Import existing resources if needed
   terraform import azurerm_resource_group.main /subscriptions/{subscription-id}/resourceGroups/{rg-name}
   ```

5. **Permission Errors**
   - Ensure your account has Contributor access to the Azure subscription
   - Check resource group permissions
   - Verify Terraform backend storage account access

6. **Terraform Backend Configuration**
   - Ensure backend storage account exists
   - Verify container and access key configuration
   - Check terraform.tfvars file for environment-specific values

### Support Resources

- [Azure Documentation](https://docs.microsoft.com/azure/)
- [Azure Developer CLI Documentation](https://docs.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)

---

**Built with ❤️ for scalable, secure, and cost-effective Azure deployments**
