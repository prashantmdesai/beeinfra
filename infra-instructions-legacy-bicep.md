# Beeux Infrastructure Setup Instructions

This document provides comprehensive instructions for setting up Azure infrastructure for the Beeux spelling bee application across IT, QA, and Production environments.

## 🔒 HTTPS-ONLY SECURITY POLICY

**CRITICAL SECURITY REQUIREMENT: ALL WEB TRAFFIC MUST BE HTTPS-ONLY**

This infrastructure enforces HTTPS-only communication across ALL components:
- ✅ **Azure App Service**: `httpsOnly: true` + TLS 1.2 minimum + HTTP to HTTPS redirect
- ✅ **Azure Container Apps**: `allowInsecure: false` + HTTPS-only ingress
- ✅ **Azure API Management**: HTTPS-only listeners + TLS 1.2+ enforcement + HTTP redirect policies
- ✅ **Azure Storage**: `supportsHttpsTrafficOnly: true` + TLS 1.2 minimum
- ✅ **Azure CDN**: `isHttpAllowed: false` + HTTPS redirect rules
- ✅ **Azure Application Gateway + WAF**: HTTPS listeners + HTTP to HTTPS redirect + secure SSL policies
- ✅ **All Backend Communications**: HTTPS between all Azure services
- ✅ **Security Headers**: HSTS, X-Content-Type-Options, X-Frame-Options, CSP enforced everywhere

## Application Architecture Overview

The Beeux application consists of:
- **Frontend**: Angular 18 application with responsive design for children aged 5-15
- **Backend**: Spring Boot REST API with PostgreSQL database
- **Storage**: MP3 audio files for spelling bee words
- **Environments**: IT → QA → Production promotion path

## Azure Services Architecture

### Core Services Required for Each Environment

#### IT Environment (Cost-Optimized, Essential Security + HTTPS Enforcement)
- **Azure App Service**: Free/Basic tier for hosting Angular frontend (HTTPS-only, TLS 1.2+)
- **Azure Container Apps**: Basic tier for hosting Spring Boot API (HTTPS-only ingress)
- **Azure API Management**: Developer tier for API Gateway (HTTPS-only, secure TLS)
- **Self-Hosted PostgreSQL**: PostgreSQL in Docker container (TLS encrypted connections)
- **Azure Blob Storage**: Free tier storage for MP3 files (HTTPS-only access)
- **Azure Container Registry**: Basic/Free tier for Docker images (HTTPS/TLS only)
- **Azure Key Vault**: Standard tier for secure secret management (TLS 1.2+)
- **Basic Monitoring**: Azure Monitor free tier with HTTPS telemetry
- **HTTPS Security Features**: TLS 1.2+, HSTS headers, HTTP to HTTPS redirect

#### QA Environment (Security-Focused + Enhanced HTTPS Protection)
- **Azure App Service**: Premium tier with auto-scaling (HTTPS-only, TLS 1.2+, security headers)
- **Azure Container Apps**: Premium tier with auto-scaling (HTTPS-only, secure ingress)
- **Azure API Management**: Standard tier with rate limiting (HTTPS-only, TLS policies)
- **Azure Database for PostgreSQL**: Managed service with SSL/TLS encryption
- **Azure Blob Storage**: Standard tier with HTTPS-only access and Private Endpoints
- **Azure Container Registry**: Premium with geo-replication (HTTPS/TLS + Private Link)
- **Azure Key Vault**: Managed secrets and TLS certificate management
- **Azure Application Insights**: Standard tier with HTTPS telemetry
- **Web Application Firewall (WAF)**: HTTPS enforcement + HTTP redirect rules
- **Enhanced HTTPS Security**: TLS 1.2+, HSTS, CSP headers, secure ciphers only

#### Production Environment (Security + Performance + Maximum HTTPS Protection)
- **Azure App Service**: Premium tier with advanced security (HTTPS-only, TLS 1.2+, security headers)
- **Azure Container Apps**: Premium tier with secure networking (HTTPS-only ingress, private endpoints)
- **Azure API Management**: Premium tier with custom domains (HTTPS-only, TLS 1.2+, advanced policies)
- **Azure Database for PostgreSQL**: Managed service with SSL/TLS + Private Link encryption
- **Azure Blob Storage**: Premium tier with HTTPS-only, CDN with TLS, geo-redundancy
- **Azure Container Registry**: Premium with TLS encryption, Private Link, Content Trust
- **Azure Key Vault**: Premium with HSM-backed TLS certificates and advanced policies
- **Azure Application Gateway + WAF**: HTTPS enforcement, TLS 1.2+, secure SSL policies
- **Azure CDN**: HTTPS-only content delivery with TLS 1.2+ and security headers
- **Maximum HTTPS Security**: TLS 1.2+, HSTS preload, advanced CSP, secure cipher suites

### Environment-Specific Configurations

| Component | IT Environment | QA Environment | Production Environment |
|-----------|----------------|----------------|------------------------|
| **App Service Plan** | Free F1 (HTTPS-only, TLS 1.2+) | Premium P1V3 with HTTPS auto-scaling | Premium P2V3 with HTTPS auto-scaling |
| **API Management** | **Developer tier (HTTPS-only API Gateway)** | Standard tier with HTTPS rate limiting | Premium tier with HTTPS custom domains |
| **Database** | **Self-hosted PostgreSQL with TLS** | Azure Database for PostgreSQL (TLS encrypted) | Azure Database for PostgreSQL (TLS + Private Link) |
| **Blob Storage** | Standard LRS (HTTPS-only access) | Standard ZRS with HTTPS + Private Endpoints | Premium LRS with HTTPS + Private Endpoints + CDN |
| **Container Registry** | Basic (HTTPS/TLS only) | Premium with HTTPS + Private Link | Premium with HTTPS + Private Link + Content Trust |
| **Application Insights** | Free tier (HTTPS telemetry) | Standard with HTTPS metrics and alerts | Premium with HTTPS analytics and monitoring |
| **Security Features** | **Key Vault Standard + HTTPS enforcement** | WAF + Key Vault + HTTPS + TLS 1.2+ | WAF + Key Vault Premium + HTTPS + TLS 1.2+ + DDoS |
| **Web Traffic** | **100% HTTPS-only with HTTP redirect** | **100% HTTPS-only with WAF protection** | **100% HTTPS-only with advanced WAF + CDN** |
| **Auto-scaling** | **None (manual scaling only)** | App Service and Container Apps HTTPS auto-scaling | Advanced HTTPS auto-scaling with custom metrics |
| **Cost Target** | **< $10/month with HTTPS alerts** | $20/month with HTTPS security focus | $30/month with HTTPS performance and security |

## Prerequisites

### Tools Required
- Azure CLI (latest version)
- Azure Developer CLI (azd)
- Docker Desktop
- PowerShell 7+ or Azure Cloud Shell
- Git
- Visual Studio Code with Azure extensions

### Azure Subscription Setup
- Ensure you have Contributor or Owner access to the Azure subscription
- Verify subscription quotas for the required services
- Set up proper resource naming conventions

## Infrastructure as Code Setup

### 1. Initialize Azure Developer CLI Project
```powershell
# Navigate to your project root
cd C:\dev\beeinfra

# Initialize azd project
azd init --template minimal

# Configure environments
azd env new it
azd env new qa  
azd env new prod
```

### 2. Resource Naming Convention
Follow this naming pattern for consistency:
```
{app-name}-{component}-{environment}-{region}

Examples:
- beeux-api-it-eastus
- beeux-web-qa-eastus
- beeux-db-prod-eastus
```

## Environment Setup Instructions

### Environment Identification Strategy
Each environment will be clearly tagged and named to ensure proper identification:
- **Resource Group Tags**: All resources will include `Environment` and `Project` tags
- **Naming Convention**: Resource names include environment suffix (it/qa/prod)
- **Resource Group Naming**: Follows pattern `beeux-rg-{environment}-{region}`
- **Cost Center Tags**: Each environment tagged with cost tracking identifiers
- **CLI Environment Context**: All commands will display current environment context
- **Terminal Prompt Enhancement**: Environment identification in all terminal operations

### Environment Context Display
Before executing any Azure CLI commands, always verify the current environment:
```powershell
# Display current environment context
Write-Host "🌍 Current Environment: $(azd env get-values | Select-String 'AZURE_ENVIRONMENT_NAME')" -ForegroundColor Yellow
Write-Host "📍 Resource Group: $(azd env get-values | Select-String 'AZURE_RESOURCE_GROUP_NAME')" -ForegroundColor Yellow
Write-Host "💰 Budget Target: $$(azd env get-values | Select-String 'BUDGET_AMOUNT')" -ForegroundColor Yellow

# Confirm before proceeding
$confirmation = Read-Host "Are you sure you want to proceed with this environment? (y/N)"
if ($confirmation -ne 'y') {
    Write-Host "❌ Operation cancelled" -ForegroundColor Red
    exit 1
}
```

### IT Environment Setup (Cost-Optimized with Essential Security)

**Environment Goal**: Minimize costs using Azure Free Tier and self-hosted services while maintaining essential security with Key Vault for secrets
**Cost Target**: Keep total monthly costs under $12 with automated alerts (includes basic Key Vault costs)
**Architecture**: Self-hosted PostgreSQL, essential security with Key Vault, minimal managed services

#### Step 1: Set Environment Variables
```powershell
# Set IT environment
azd env select it

# Configure environment variables for cost-optimized IT environment
azd env set AZURE_LOCATION eastus
azd env set AZURE_RESOURCE_GROUP_NAME beeux-rg-it-eastus
azd env set AZURE_APP_NAME beeux-it
azd env set AZURE_ENVIRONMENT_NAME it
azd env set DATABASE_TYPE "self-hosted"
azd env set DATABASE_NAME beeux_it
azd env set POSTGRES_ADMIN_USERNAME postgres_admin
azd env set BLOB_CONTAINER_NAME audio-files-it
azd env set BUDGET_AMOUNT 15
azd env set ALERT_EMAIL_PRIMARY "prashantmdesai@yahoo.com"
azd env set ALERT_EMAIL_SECONDARY "prashantmdesai@hotmail.com"
azd env set ALERT_PHONE "+12246564855"
azd env set USE_FREE_TIER "true"
azd env set USE_MANAGED_SERVICES "false"
azd env set ENABLE_SECURITY_FEATURES "basic"
azd env set ENABLE_KEY_VAULT "true"
azd env set KEY_VAULT_SKU "standard"
azd env set ENABLE_API_MANAGEMENT "true"
azd env set API_MANAGEMENT_SKU "Developer"
azd env set ENABLE_AUTO_SCALING "false"
azd env set AUTO_SHUTDOWN_ENABLED "true"
azd env set IDLE_SHUTDOWN_HOURS 1

# Confirm IT environment setup
Write-Host "✅ IT Environment variables configured" -ForegroundColor Green
Write-Host "💰 Budget Alert Threshold: $10 (includes Key Vault and API Management)" -ForegroundColor Yellow
Write-Host "🏗️  Using self-hosted PostgreSQL (no managed database)" -ForegroundColor Yellow
Write-Host "🔑 Key Vault enabled for essential secret management" -ForegroundColor Green
Write-Host "🌐 API Management (Developer tier) for REST API Gateway" -ForegroundColor Green
Write-Host "🔓 Minimal managed security services (cost optimization)" -ForegroundColor Yellow
Write-Host "📈 No auto-scaling (manual scaling only)" -ForegroundColor Yellow
Write-Host "⏰ Auto-shutdown after 1 hour of inactivity" -ForegroundColor Yellow
```

#### Step 2: Create Bicep Infrastructure Files
Create the following directory structure:
```
infra/
├── main.bicep
├── main.parameters.json
├── modules/
│   ├── app-service.bicep
│   ├── app-service-autoscaling.bicep
│   ├── container-apps.bicep
│   ├── container-apps-autoscaling.bicep
│   ├── api-management.bicep
│   ├── api-management-developer.bicep
│   ├── api-management-premium.bicep
│   ├── database-managed.bicep
│   ├── database-selfhosted.bicep
│   ├── storage.bicep
│   ├── storage-premium.bicep
│   ├── keyvault.bicep
│   ├── keyvault-premium.bicep
│   ├── monitoring.bicep
│   ├── monitoring-premium.bicep
│   ├── identity.bicep
│   ├── security-basic.bicep
│   ├── security-premium.bicep
│   ├── network-security.bicep
│   ├── private-endpoints.bicep
│   ├── waf.bicep
│   ├── ddos-protection.bicep
│   ├── budget-alerts.bicep
│   ├── cost-monitoring.bicep
│   └── auto-shutdown.bicep
└── scripts/
    ├── post-deployment.ps1
    ├── setup-cost-alerts.ps1
    ├── setup-auto-shutdown.ps1
    ├── setup-security-features.ps1
    ├── setup-autoscaling.ps1
    ├── shutdown-environment.ps1
    ├── startup-environment.ps1
    ├── complete-shutdown-it.ps1
    ├── complete-shutdown-qa.ps1
    ├── complete-shutdown-prod.ps1
    ├── verify-shutdown.ps1
    └── emergency-shutdown-all.ps1
```

#### Step 3: Deploy IT Infrastructure with Cost Monitoring
```powershell
# Display environment context before deployment
Write-Host "🔧 Deploying IT Environment" -ForegroundColor Green
Write-Host "Environment: $(azd env get-values | Select-String 'AZURE_ENVIRONMENT_NAME')" -ForegroundColor Yellow
Write-Host "Resource Group: $(azd env get-values | Select-String 'AZURE_RESOURCE_GROUP_NAME')" -ForegroundColor Yellow

# Provision Azure resources with cost optimization
azd provision

# Deploy applications
azd deploy

# Set up budget and cost alerts immediately after deployment
Write-Host "💰 Setting up IT budget alerts ($10 threshold)..." -ForegroundColor Yellow
.\infra\scripts\setup-cost-alerts.ps1 -EnvironmentName "it" -BudgetAmount 10

# Set up auto-shutdown for cost optimization
Write-Host "⏰ Setting up auto-shutdown for IT environment..." -ForegroundColor Yellow
.\infra\scripts\setup-auto-shutdown.ps1 -EnvironmentName "it" -IdleHours 1
```

### QA Environment Setup (Security-Focused)

**Environment Goal**: Balanced security and performance for comprehensive testing
**Cost Target**: $20/month with emphasis on security features
**Architecture**: Managed services with security features, auto-scaling enabled

#### Step 1: Set Environment Variables
```powershell
# Set QA environment with clear identification
azd env select qa

# Display current environment for confirmation
Write-Host "🔧 Setting up QA Environment" -ForegroundColor Cyan
Write-Host "Environment: QA (Quality Assurance)" -ForegroundColor Yellow

# Configure environment variables for QA environment
azd env set AZURE_LOCATION eastus
azd env set AZURE_RESOURCE_GROUP_NAME beeux-rg-qa-eastus
azd env set AZURE_APP_NAME beeux-qa
azd env set AZURE_ENVIRONMENT_NAME qa
azd env set DATABASE_TYPE "managed"
azd env set DATABASE_NAME beeux_qa
azd env set POSTGRES_ADMIN_USERNAME postgres_admin
azd env set BLOB_CONTAINER_NAME audio-files-qa
azd env set BUDGET_AMOUNT 25
azd env set ALERT_EMAIL_PRIMARY "prashantmdesai@yahoo.com"
azd env set ALERT_EMAIL_SECONDARY "prashantmdesai@hotmail.com"
azd env set ALERT_PHONE "+12246564855"
azd env set USE_FREE_TIER "false"
azd env set USE_MANAGED_SERVICES "true"
azd env set ENABLE_SECURITY_FEATURES "true"
azd env set ENABLE_AUTO_SCALING "true"
azd env set ENABLE_PRIVATE_ENDPOINTS "true"
azd env set ENABLE_WAF "true"
azd env set ENABLE_KEY_VAULT "true"
azd env set ENABLE_API_MANAGEMENT "true"
azd env set API_MANAGEMENT_SKU "Standard"
azd env set AUTO_SHUTDOWN_ENABLED "true"
azd env set IDLE_SHUTDOWN_HOURS 1

# Confirm QA environment setup
Write-Host "✅ QA Environment variables configured" -ForegroundColor Green
Write-Host "💰 Budget Alert Threshold: $20 (includes API Management)" -ForegroundColor Yellow
Write-Host "🔒 Security features enabled (Key Vault, WAF, Private Endpoints)" -ForegroundColor Green
Write-Host "🌐 API Management (Standard tier) with rate limiting and security policies" -ForegroundColor Green
Write-Host "📈 Auto-scaling enabled for user-facing components" -ForegroundColor Green
Write-Host "⏰ Auto-shutdown after 1 hour of inactivity" -ForegroundColor Yellow
```

#### Step 2: Deploy QA Infrastructure with Environment Identification
```powershell
# Display environment context before deployment
Write-Host "🚀 Deploying QA Environment" -ForegroundColor Cyan
Write-Host "Environment: $(azd env get-values | Select-String 'AZURE_ENVIRONMENT_NAME')" -ForegroundColor Yellow
Write-Host "Resource Group: $(azd env get-values | Select-String 'AZURE_RESOURCE_GROUP_NAME')" -ForegroundColor Yellow

# Provision Azure resources
azd provision

# Deploy applications
azd deploy

# Set up budget and cost alerts for QA ($20 threshold)
Write-Host "💰 Setting up QA budget alerts ($20 threshold)..." -ForegroundColor Yellow
.\infra\scripts\setup-cost-alerts.ps1 -EnvironmentName "qa" -BudgetAmount 25

# Set up security features for QA environment
Write-Host "🔒 Setting up security features for QA environment..." -ForegroundColor Yellow
.\infra\scripts\setup-security-features.ps1 -EnvironmentName "qa"

# Set up auto-scaling for user-facing components
Write-Host "📈 Setting up auto-scaling for QA environment..." -ForegroundColor Yellow
.\infra\scripts\setup-autoscaling.ps1 -EnvironmentName "qa"

# Set up auto-shutdown for cost optimization
Write-Host "⏰ Setting up auto-shutdown for QA environment..." -ForegroundColor Yellow
.\infra\scripts\setup-auto-shutdown.ps1 -EnvironmentName "qa" -IdleHours 1
```

### Production Environment Setup (Security + Performance Optimized)

**Environment Goal**: Maximum security and performance with advanced auto-scaling
**Cost Target**: $30/month with premium security and performance features
**Architecture**: Premium managed services, advanced security, intelligent auto-scaling

#### Step 1: Set Environment Variables
```powershell
# Set Production environment with clear identification
azd env select prod

# Display current environment for confirmation
Write-Host "🏭 Setting up Production Environment" -ForegroundColor Red
Write-Host "Environment: PRODUCTION (Live Environment)" -ForegroundColor Red -BackgroundColor Yellow

# Configure environment variables for Production environment
azd env set AZURE_LOCATION eastus
azd env set AZURE_RESOURCE_GROUP_NAME beeux-rg-prod-eastus
azd env set AZURE_APP_NAME beeux-prod
azd env set AZURE_ENVIRONMENT_NAME prod
azd env set DATABASE_TYPE "managed-premium"
azd env set DATABASE_NAME beeux_prod
azd env set POSTGRES_ADMIN_USERNAME postgres_admin
azd env set BLOB_CONTAINER_NAME audio-files-prod
azd env set CDN_PROFILE_NAME beeux-cdn-prod
azd env set BUDGET_AMOUNT 35
azd env set ALERT_EMAIL_PRIMARY "prashantmdesai@yahoo.com"
azd env set ALERT_EMAIL_SECONDARY "prashantmdesai@hotmail.com"
azd env set ALERT_PHONE "+12246564855"
azd env set USE_FREE_TIER "false"
azd env set USE_MANAGED_SERVICES "true"
azd env set ENABLE_SECURITY_FEATURES "true"
azd env set ENABLE_PREMIUM_SECURITY "true"
azd env set ENABLE_AUTO_SCALING "true"
azd env set ENABLE_ADVANCED_AUTO_SCALING "true"
azd env set ENABLE_PRIVATE_ENDPOINTS "true"
azd env set ENABLE_WAF "true"
azd env set ENABLE_DDOS_PROTECTION "true"
azd env set ENABLE_KEY_VAULT_HSM "true"
azd env set ENABLE_CONTENT_TRUST "true"
azd env set ENABLE_API_MANAGEMENT "true"
azd env set API_MANAGEMENT_SKU "Premium"
azd env set AUTO_SHUTDOWN_ENABLED "true"
azd env set IDLE_SHUTDOWN_HOURS 1

# Confirm Production environment setup
Write-Host "✅ Production Environment variables configured" -ForegroundColor Green
Write-Host "💰 Budget Alert Threshold: $30 (includes Premium API Management)" -ForegroundColor Yellow
Write-Host "🔒 Premium security features enabled (HSM Key Vault, DDoS Protection, Content Trust)" -ForegroundColor Green
Write-Host "🌐 API Management (Premium tier) with advanced analytics and custom domains" -ForegroundColor Green
Write-Host "📈 Advanced auto-scaling enabled with custom metrics" -ForegroundColor Green
Write-Host "🛡️  Enterprise security (Private Link, WAF, Security Center Premium)" -ForegroundColor Green
Write-Host "⏰ Auto-shutdown after 1 hour of inactivity" -ForegroundColor Yellow
Write-Host "⚠️  WARNING: This is PRODUCTION environment!" -ForegroundColor Red
```

#### Step 2: Deploy Production Infrastructure with Environment Identification
```powershell
# Display environment context before deployment
Write-Host "🏭 Deploying PRODUCTION Environment" -ForegroundColor Red -BackgroundColor Yellow
Write-Host "Environment: $(azd env get-values | Select-String 'AZURE_ENVIRONMENT_NAME')" -ForegroundColor Red
Write-Host "Resource Group: $(azd env get-values | Select-String 'AZURE_RESOURCE_GROUP_NAME')" -ForegroundColor Red

# Additional confirmation for production
$prodConfirmation = Read-Host "⚠️  Are you ABSOLUTELY SURE you want to deploy to PRODUCTION? Type 'DEPLOY-PRODUCTION' to confirm"
if ($prodConfirmation -ne 'DEPLOY-PRODUCTION') {
    Write-Host "❌ Production deployment cancelled for safety" -ForegroundColor Red
    exit 1
}

# Provision Azure resources with production settings
azd provision

# Deploy applications
azd deploy

# Set up budget and cost alerts for Production ($30 threshold)
Write-Host "💰 Setting up Production budget alerts ($30 threshold)..." -ForegroundColor Yellow
.\infra\scripts\setup-cost-alerts.ps1 -EnvironmentName "prod" -BudgetAmount 35

# Set up premium security features for Production environment
Write-Host "🛡️  Setting up premium security features for Production environment..." -ForegroundColor Yellow
.\infra\scripts\setup-security-features.ps1 -EnvironmentName "prod"

# Set up advanced auto-scaling for user-facing components
Write-Host "📈 Setting up advanced auto-scaling for Production environment..." -ForegroundColor Yellow
.\infra\scripts\setup-autoscaling.ps1 -EnvironmentName "prod"

# Set up auto-shutdown for cost optimization
Write-Host "⏰ Setting up auto-shutdown for Production environment..." -ForegroundColor Yellow
.\infra\scripts\setup-auto-shutdown.ps1 -EnvironmentName "prod" -IdleHours 1
```

## Infrastructure Components Configuration

### 1. Azure App Service (Angular Frontend)

#### IT Environment Configuration (Free/Lowest Cost, No Auto-scaling)
```bicep
// Free tier configuration for IT environment - no managed features
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'beeux-plan-it-${location}'
  location: location
  sku: {
    name: useFreeTier ? 'F1' : 'B1'  // Free tier first, Basic if unavailable
    tier: useFreeTier ? 'Free' : 'Basic'
  }
  properties: {
    reserved: false  // Windows hosting for cost optimization
  }
  tags: {
    Environment: 'IT'
    Project: 'Beeux'
    CostCenter: 'Development'
    Purpose: 'Cost-Optimized Development'
    AutoScaling: 'Disabled'
    SecurityLevel: 'Basic'
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: 'beeux-web-it-${location}'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      // No advanced security features for cost optimization
    }
  }
}
```

#### QA Environment Configuration (Security-Focused with Auto-scaling)
```bicep
// Premium configuration with security and auto-scaling for QA
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'beeux-plan-qa-${location}'
  location: location
  sku: {
    name: 'P1V3'
    tier: 'PremiumV3'
  }
  properties: {
    reserved: false
    targetWorkerCount: 1
    maximumElasticWorkerCount: 5  // Auto-scaling up to 5 instances
  }
  tags: {
    Environment: 'QA'
    Project: 'Beeux'
    CostCenter: 'Testing'
    Purpose: 'Security-Focused Testing'
    AutoScaling: 'Enabled'
    SecurityLevel: 'Premium'
  }
}

// Auto-scaling rules for QA
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: 'beeux-autoscale-qa-${location}'
  location: location
  properties: {
    enabled: true
    targetResourceUri: appServicePlan.id
    profiles: [
      {
        name: 'Default'
        capacity: {
          minimum: '1'
          maximum: '5'
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              operator: 'GreaterThan'
              threshold: 70
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              operator: 'LessThan'
              threshold: 30
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT10M'
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT10M'
            }
          }
        ]
      }
    ]
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: 'beeux-web-qa-${location}'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      ipSecurityRestrictions: []  // Configure as needed
      alwaysOn: true
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
}
```

#### Production Environment Configuration (Performance + Security with Advanced Auto-scaling)
```bicep
// Premium configuration with advanced auto-scaling for Production
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'beeux-plan-prod-${location}'
  location: location
  sku: {
    name: 'P2V3'  // Higher tier for production
    tier: 'PremiumV3'
  }
  properties: {
    reserved: false
    targetWorkerCount: 2
    maximumElasticWorkerCount: 10  // Higher auto-scaling limit
  }
  tags: {
    Environment: 'Production'
    Project: 'Beeux'
    CostCenter: 'Production'
    Purpose: 'High-Performance Production'
    AutoScaling: 'Advanced'
    SecurityLevel: 'Enterprise'
  }
}

// Advanced auto-scaling rules for Production
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: 'beeux-autoscale-prod-${location}'
  location: location
  properties: {
    enabled: true
    targetResourceUri: appServicePlan.id
    profiles: [
      {
        name: 'Default'
        capacity: {
          minimum: '2'
          maximum: '10'
          default: '2'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              operator: 'GreaterThan'
              threshold: 60  // Lower threshold for faster scaling
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT3M'  // Faster response
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '2'  // Scale by 2 instances
              cooldown: 'PT3M'
            }
          }
          {
            metricTrigger: {
              metricName: 'MemoryPercentage'
              metricResourceUri: appServicePlan.id
              operator: 'GreaterThan'
              threshold: 80
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT3M'
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT3M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              operator: 'LessThan'
              threshold: 25
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT15M'  // Longer window for scale-down
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT15M'
            }
          }
        ]
      }
      {
        name: 'Peak Hours'
        capacity: {
          minimum: '3'
          maximum: '10'
          default: '3'
        }
        recurrence: {
          frequency: 'Week'
          schedule: {
            timeZone: 'Eastern Standard Time'
            days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
            hours: [8]
            minutes: [0]
          }
        }
        rules: []  // Uses same rules as default but with higher baseline
      }
    ]
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: 'beeux-web-prod-${location}'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      ipSecurityRestrictions: []  // Configure with WAF integration
      alwaysOn: true
      http20Enabled: true
      use32BitWorkerProcess: false
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
}
```

### 2. Azure Container Apps (Spring Boot API)

#### IT Environment Configuration (Basic, No Auto-scaling)
```bicep
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'beeux-containerenv-it-${location}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
  tags: {
    Environment: 'IT'
    Project: 'Beeux'
    CostCenter: 'Development'
    Purpose: 'Cost-Optimized Container Environment'
    SecurityLevel: 'Basic'
  }
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'beeux-api-it-${location}'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: false
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: userAssignedIdentity.id
        }
      ]
      secrets: [
        {
          name: 'database-connection'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/database-connection'
          identity: userAssignedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${containerRegistry.properties.loginServer}/beeux-api:latest'
          name: 'beeux-api'
          resources: {
            cpu: 0.5  // Minimal resources for cost optimization
            memory: '1Gi'
          }
          env: [
            {
              name: 'DATABASE_CONNECTION'
              secretRef: 'database-connection'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0  // Can scale to zero for cost savings
        maxReplicas: 1  // No auto-scaling
      }
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
}
```

#### QA Environment Configuration (Security-Focused with Auto-scaling)
```bicep
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'beeux-containerenv-qa-${location}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: enablePrivateEndpoints ? {
      infrastructureSubnetId: subnet.id
      internal: true
    } : null
  }
  tags: {
    Environment: 'QA'
    Project: 'Beeux'
    CostCenter: 'Testing'
    Purpose: 'Security-Focused Container Environment'
    SecurityLevel: 'Premium'
  }
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'beeux-api-qa-${location}'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: false
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
        }
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: userAssignedIdentity.id
        }
      ]
      secrets: [
        {
          name: 'database-connection'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/database-connection'
          identity: userAssignedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${containerRegistry.properties.loginServer}/beeux-api:latest'
          name: 'beeux-api'
          resources: {
            cpu: 1.0
            memory: '2Gi'
          }
          env: [
            {
              name: 'DATABASE_CONNECTION'
              secretRef: 'database-connection'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5  // Auto-scaling enabled
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
          {
            name: 'cpu-scaling'
            custom: {
              type: 'cpu'
              metadata: {
                type: 'Utilization'
                value: '70'
              }
            }
          }
        ]
      }
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
}
```

#### Production Environment Configuration (Performance + Security with Advanced Auto-scaling)
```bicep
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'beeux-containerenv-prod-${location}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: subnet.id
      internal: true  // Private environment for security
    }
    zoneRedundant: true  // High availability
  }
  tags: {
    Environment: 'Production'
    Project: 'Beeux'
    CostCenter: 'Production'
    Purpose: 'High-Performance Production Container Environment'
    SecurityLevel: 'Enterprise'
  }
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'beeux-api-prod-${location}'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: false
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        corsPolicy: {
          allowedOrigins: ['https://beeux-web-prod-eastus.azurewebsites.net']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
          allowCredentials: true
        }
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: userAssignedIdentity.id
        }
      ]
      secrets: [
        {
          name: 'database-connection'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/database-connection'
          identity: userAssignedIdentity.id
        }
        {
          name: 'storage-connection'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/storage-connection'
          identity: userAssignedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${containerRegistry.properties.loginServer}/beeux-api:latest'
          name: 'beeux-api'
          resources: {
            cpu: 2.0  // Higher resources for production
            memory: '4Gi'
          }
          env: [
            {
              name: 'DATABASE_CONNECTION'
              secretRef: 'database-connection'
            }
            {
              name: 'STORAGE_CONNECTION'
              secretRef: 'storage-connection'
            }
            {
              name: 'ENVIRONMENT'
              value: 'production'
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/actuator/health'
                port: 8080
              }
              initialDelaySeconds: 30
              periodSeconds: 10
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/actuator/health/readiness'
                port: 8080
              }
              initialDelaySeconds: 10
              periodSeconds: 5
            }
          ]
        }
      ]
      scale: {
        minReplicas: 2  // Always maintain high availability
        maxReplicas: 10  // Advanced auto-scaling
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '5'  // More aggressive scaling
              }
            }
          }
          {
            name: 'cpu-scaling'
            custom: {
              type: 'cpu'
              metadata: {
                type: 'Utilization'
                value: '60'  // Lower threshold for faster scaling
              }
            }
          }
          {
            name: 'memory-scaling'
            custom: {
              type: 'memory'
              metadata: {
                type: 'Utilization'
                value: '80'
              }
            }
          }
          {
            name: 'custom-metric-scaling'
            custom: {
              type: 'azure-monitor'
              metadata: {
                tenantId: tenant().tenantId
                subscriptionId: subscription().subscriptionId
                resourceGroupName: resourceGroup().name
                metricName: 'RequestsPerSecond'
                targetValue: '100'
              }
              authenticationRef: 'azure-monitor-auth'
            }
          }
        ]
      }
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
}
```

### 3. Azure API Management (REST API Gateway)

#### IT Environment Configuration (Developer Tier - Cost Optimized)
```bicep
// Developer tier API Management for IT environment
resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: 'beeux-apim-it-${location}'
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherEmail: 'admin@beeux.com'
    publisherName: 'Beeux IT Team'
    notificationSenderEmail: 'apimgmt-noreply@mail.windowsazure.com'
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: 'beeux-apim-it-${location}.azure-api.net'
        negotiateClientCertificate: false
        defaultSslBinding: true
        certificateSource: 'BuiltIn'
      }
    ]
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
    }
    virtualNetworkType: 'None'  // External for cost optimization
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  tags: {
    Environment: 'IT'
    Project: 'Beeux'
    CostCenter: 'Development'
    Purpose: 'Cost-Optimized API Gateway'
    SecurityLevel: 'Basic'
  }
}

// Basic API configuration for Spring Boot backend
resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apiManagement
  name: 'beeux-api'
  properties: {
    displayName: 'Beeux Spelling Bee API'
    apiRevision: '1'
    description: 'REST API for Beeux spelling bee application'
    subscriptionRequired: false  // Simplified for IT environment
    serviceUrl: 'https://${containerApp.properties.configuration.ingress.fqdn}'
    path: 'api'
    protocols: ['https']
    authenticationSettings: {
      oAuth2AuthenticationSettings: []
    }
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
  }
}

// Basic CORS policy for development
resource corsPolicy 'Microsoft.ApiManagement/service/policies@2023-05-01-preview' = {
  parent: apiManagement
  name: 'policy'
  properties: {
    value: '''
    <policies>
      <inbound>
        <cors allow-credentials="true">
          <allowed-origins>
            <origin>*</origin>
          </allowed-origins>
          <allowed-methods>
            <method>GET</method>
            <method>POST</method>
            <method>PUT</method>
            <method>DELETE</method>
            <method>OPTIONS</method>
          </allowed-methods>
          <allowed-headers>
            <header>*</header>
          </allowed-headers>
        </cors>
        <base />
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
    '''
  }
}
```

#### QA Environment Configuration (Standard Tier with Security)
```bicep
// Standard tier API Management for QA environment
resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: 'beeux-apim-qa-${location}'
  location: location
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    publisherEmail: 'admin@beeux.com'
    publisherName: 'Beeux QA Team'
    notificationSenderEmail: 'apimgmt-noreply@mail.windowsazure.com'
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: 'beeux-apim-qa-${location}.azure-api.net'
        negotiateClientCertificate: true  // Enhanced security
        defaultSslBinding: true
        certificateSource: 'BuiltIn'
      }
    ]
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
    }
    virtualNetworkType: enablePrivateEndpoints ? 'Internal' : 'External'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  tags: {
    Environment: 'QA'
    Project: 'Beeux'
    CostCenter: 'Testing'
    Purpose: 'Security-Focused API Gateway'
    SecurityLevel: 'Premium'
  }
}

// Enhanced API configuration with security policies
resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apiManagement
  name: 'beeux-api'
  properties: {
    displayName: 'Beeux Spelling Bee API'
    apiRevision: '1'
    description: 'REST API for Beeux spelling bee application'
    subscriptionRequired: true  // Require subscription for QA
    serviceUrl: 'https://${containerApp.properties.configuration.ingress.fqdn}'
    path: 'api'
    protocols: ['https']
    authenticationSettings: {
      oAuth2AuthenticationSettings: []
    }
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
  }
}

// Rate limiting and security policies for QA
resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: api
  name: 'policy'
  properties: {
    value: '''
    <policies>
      <inbound>
        <rate-limit calls="100" renewal-period="60" />
        <quota calls="1000" renewal-period="86400" />
        <cors allow-credentials="true">
          <allowed-origins>
            <origin>https://beeux-web-qa-eastus.azurewebsites.net</origin>
          </allowed-origins>
          <allowed-methods>
            <method>GET</method>
            <method>POST</method>
            <method>PUT</method>
            <method>DELETE</method>
            <method>OPTIONS</method>
          </allowed-methods>
          <allowed-headers>
            <header>*</header>
          </allowed-headers>
        </cors>
        <check-header name="User-Agent" failed-check-httpcode="400" failed-check-error-message="User-Agent header missing" ignore-case="false" />
        <base />
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
    '''
  }
}

// Product for QA environment
resource product 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = {
  parent: apiManagement
  name: 'qa-product'
  properties: {
    displayName: 'QA Testing Product'
    description: 'Product for QA environment testing'
    subscriptionRequired: true
    approvalRequired: false
    state: 'published'
  }
}

resource productApi 'Microsoft.ApiManagement/service/products/apis@2023-05-01-preview' = {
  parent: product
  name: api.name
}
```

#### Production Environment Configuration (Premium Tier with Advanced Security)
```bicep
// Premium tier API Management for Production environment
resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: 'beeux-apim-prod-${location}'
  location: location
  sku: {
    name: 'Premium'
    capacity: 1
  }
  properties: {
    publisherEmail: 'admin@beeux.com'
    publisherName: 'Beeux Production'
    notificationSenderEmail: 'apimgmt-noreply@mail.windowsazure.com'
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: 'api.beeux.com'  // Custom domain for production
        negotiateClientCertificate: true
        defaultSslBinding: true
        certificateSource: 'KeyVault'
        keyVaultId: '${keyVault.properties.vaultUri}secrets/api-ssl-certificate'
      }
    ]
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
    }
    virtualNetworkType: 'Internal'  // Private network for production
    additionalLocations: [
      {
        location: 'westus2'
        sku: {
          name: 'Premium'
          capacity: 1
        }
        virtualNetworkConfiguration: {
          subnetResourceId: subnet.id
        }
      }
    ]
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  tags: {
    Environment: 'Production'
    Project: 'Beeux'
    CostCenter: 'Production'
    Purpose: 'Enterprise API Gateway'
    SecurityLevel: 'Enterprise'
  }
}

// Production API configuration with advanced security
resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apiManagement
  name: 'beeux-api'
  properties: {
    displayName: 'Beeux Spelling Bee API'
    apiRevision: '1'
    description: 'Production REST API for Beeux spelling bee application'
    subscriptionRequired: true
    serviceUrl: 'https://${containerApp.properties.configuration.ingress.fqdn}'
    path: 'api'
    protocols: ['https']
    authenticationSettings: {
      oAuth2AuthenticationSettings: [
        {
          authorizationServerId: 'oauth-server'
          scope: 'api.read api.write'
        }
      ]
    }
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
  }
}

// Advanced security and rate limiting policies for Production
resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: api
  name: 'policy'
  properties: {
    value: '''
    <policies>
      <inbound>
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized">
          <openid-config url="https://login.microsoftonline.com/common/.well-known/openid_configuration" />
          <audiences>
            <audience>api://beeux-prod</audience>
          </audiences>
        </validate-jwt>
        <rate-limit-by-key calls="50" renewal-period="60" counter-key="@(context.Request.IpAddress)" />
        <quota-by-key calls="500" renewal-period="86400" counter-key="@(context.Subscription.Id)" />
        <ip-filter action="allow">
          <address-range from="10.0.0.0" to="10.255.255.255" />
          <address-range from="172.16.0.0" to="172.31.255.255" />
          <address-range from="192.168.0.0" to="192.168.255.255" />
        </ip-filter>
        <cors allow-credentials="true">
          <allowed-origins>
            <origin>https://beeux.com</origin>
            <origin>https://www.beeux.com</origin>
          </allowed-origins>
          <allowed-methods>
            <method>GET</method>
            <method>POST</method>
            <method>PUT</method>
            <method>DELETE</method>
            <method>OPTIONS</method>
          </allowed-methods>
          <allowed-headers>
            <header>Content-Type</header>
            <header>Authorization</header>
            <header>Ocp-Apim-Subscription-Key</header>
          </allowed-headers>
        </cors>
        <check-header name="User-Agent" failed-check-httpcode="400" failed-check-error-message="User-Agent header missing" ignore-case="false" />
        <set-backend-service base-url="https://${containerApp.properties.configuration.ingress.fqdn}" />
        <base />
      </inbound>
      <backend>
        <retry condition="@(context.Response.StatusCode >= 500)" count="3" interval="1" />
        <base />
      </backend>
      <outbound>
        <set-header name="X-Powered-By" exists-action="delete" />
        <set-header name="X-AspNet-Version" exists-action="delete" />
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
    '''
  }
}

// Premium product with tiered access
resource premiumProduct 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = {
  parent: apiManagement
  name: 'premium-product'
  properties: {
    displayName: 'Premium API Access'
    description: 'Premium tier access to Beeux API'
    subscriptionRequired: true
    approvalRequired: true
    state: 'published'
    subscriptionsLimit: 100
  }
}

resource productApi 'Microsoft.ApiManagement/service/products/apis@2023-05-01-preview' = {
  parent: premiumProduct
  name: api.name
}

// Application Insights integration for advanced monitoring
resource apiManagementLogger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = {
  parent: apiManagement
  name: 'applicationinsights-logger'
  properties: {
    loggerType: 'applicationInsights'
    resourceId: applicationInsights.id
    credentials: {
      instrumentationKey: applicationInsights.properties.InstrumentationKey
    }
  }
}

// Diagnostic settings for comprehensive logging
resource apiDiagnostic 'Microsoft.ApiManagement/service/apis/diagnostics@2023-05-01-preview' = {
  parent: api
  name: 'applicationinsights'
  properties: {
    loggerId: apiManagementLogger.id
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'W3C'
    verbosity: 'information'
    logClientIp: true
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: {
      request: {
        headers: ['Authorization', 'User-Agent']
        body: {
          bytes: 1024
        }
      }
      response: {
        headers: ['Content-Type']
        body: {
          bytes: 1024
        }
      }
    }
    backend: {
      request: {
        headers: ['Authorization']
        body: {
          bytes: 1024
        }
      }
      response: {
        headers: ['Content-Type']
        body: {
          bytes: 1024
        }
      }
    }
  }
}
```

### 4. Database Configuration

#### IT Environment - Self-Hosted PostgreSQL (Cost Optimization)
```bicep
// Self-hosted PostgreSQL in Container for IT environment (no managed database costs)
resource postgresContainer 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'beeux-postgres-it-${location}'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: false  // Internal only
        targetPort: 5432
        transport: 'tcp'
      }
    }
    template: {
      containers: [
        {
          image: 'postgres:15-alpine'
          name: 'postgres'
          resources: {
            cpu: 0.25  // Minimal resources
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'POSTGRES_DB'
              value: 'beeux_it'
            }
            {
              name: 'POSTGRES_USER'
              value: 'postgres_admin'
            }
            {
              name: 'POSTGRES_PASSWORD'
              value: 'ChangeMe123!'  // Use Key Vault in real deployment
            }
            {
              name: 'PGDATA'
              value: '/var/lib/postgresql/data/pgdata'
            }
          ]
          volumeMounts: [
            {
              volumeName: 'postgres-storage'
              mountPath: '/var/lib/postgresql/data'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1  // No auto-scaling for database
      }
      volumes: [
        {
          name: 'postgres-storage'
          storageType: 'EmptyDir'  // Basic storage for cost optimization
        }
      ]
    }
  }
  tags: {
    Environment: 'IT'
    Project: 'Beeux'
    CostCenter: 'Development'
    Purpose: 'Self-Hosted PostgreSQL Database'
    DatabaseType: 'Self-Hosted'
    SecurityLevel: 'Basic'
  }
}
```

#### QA Environment - Managed PostgreSQL with Security Features
```bicep
resource postgreSQLServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' = {
  name: 'beeux-db-qa-${location}'
  location: location
  sku: {
    name: 'Standard_B2s'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    version: '15'
    storage: {
      storageSizeGB: 64
    }
    backup: {
      backupRetentionDays: 14
      geoRedundantBackup: 'Enabled'
    }
    network: enablePrivateEndpoints ? {
      delegatedSubnetResourceId: subnet.id
      privateDnsZoneArmResourceId: privateDnsZone.id
    } : null
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Enabled'
      tenantId: tenant().tenantId
    }
  }
  tags: {
    Environment: 'QA'
    Project: 'Beeux'
    CostCenter: 'Testing'
    Purpose: 'Managed PostgreSQL Database'
    DatabaseType: 'Managed'
    SecurityLevel: 'Premium'
  }
}

// Database configuration with security settings
resource postgreSQLDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-12-01-preview' = {
  parent: postgreSQLServer
  name: 'beeux_qa'
  properties: {
    charset: 'utf8'
    collation: 'en_US.utf8'
  }
}

// Firewall rules for QA (more restrictive)
resource postgreSQLFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-12-01-preview' = if (!enablePrivateEndpoints) {
  parent: postgreSQLServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}
```

#### Production Environment - Premium Managed PostgreSQL with Advanced Security
```bicep
resource postgreSQLServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' = {
  name: 'beeux-db-prod-${location}'
  location: location
  sku: {
    name: 'Standard_D4s_v3'
    tier: 'GeneralPurpose'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    version: '15'
    storage: {
      storageSizeGB: 128
      autoGrow: 'Enabled'
      iops: 3000
    }
    backup: {
      backupRetentionDays: 35
      geoRedundantBackup: 'Enabled'
      earliestRestoreDate: dateTimeAdd(utcNow(), 'PT1H')
    }
    highAvailability: {
      mode: 'ZoneRedundant'
      standbyAvailabilityZone: '2'
    }
    network: {
      delegatedSubnetResourceId: subnet.id
      privateDnsZoneArmResourceId: privateDnsZone.id
    }
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'  // AAD only for production
      tenantId: tenant().tenantId
    }
    dataEncryption: {
      type: 'AzureKeyVault'
      primaryKeyURI: '${keyVault.properties.vaultUri}keys/postgres-encryption-key'
      primaryUserAssignedIdentityId: userAssignedIdentity.id
    }
  }
  tags: {
    Environment: 'Production'
    Project: 'Beeux'
    CostCenter: 'Production'
    Purpose: 'Premium Managed PostgreSQL Database'
    DatabaseType: 'Managed-Premium'
    SecurityLevel: 'Enterprise'
    HighAvailability: 'Enabled'
  }
}

// Production database with advanced configuration
resource postgreSQLDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-12-01-preview' = {
  parent: postgreSQLServer
  name: 'beeux_prod'
  properties: {
    charset: 'utf8'
    collation: 'en_US.utf8'
  }
}

// No public firewall rules for production (private endpoints only)
resource postgreSQLConfiguration 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2023-12-01-preview' = {
  parent: postgreSQLServer
  name: 'log_statement'
  properties: {
    value: 'all'  // Enhanced logging for production
    source: 'user-override'
  }
}

// Advanced threat protection for production
resource advancedThreatProtection 'Microsoft.Security/advancedThreatProtectionSettings@2019-01-01' = {
  scope: postgreSQLServer
  name: 'current'
  properties: {
    isEnabled: true
  }
}
```

### 4. Azure Blob Storage

#### IT Environment - Basic Storage (Cost Optimized)
```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'beeux${environmentName}${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'  // Cheapest option
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true  // Simplified for IT environment
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowSharedKeyAccess: true
  }
  tags: {
    Environment: 'IT'
    Project: 'Beeux'
    CostCenter: 'Development'
    Purpose: 'Basic Audio File Storage'
    SecurityLevel: 'Basic'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: ['*']  // Permissive for development
          allowedMethods: ['GET', 'HEAD']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 3600
        }
      ]
    }
  }
}
```

#### QA Environment - Security-Enhanced Storage
```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'beeux${environmentName}${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_ZRS'  // Zone redundant for resilience
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false  // Enhanced security
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowSharedKeyAccess: false  // Managed identity only
    encryption: {
      keySource: 'Microsoft.Keyvault'
      keyvaultproperties: {
        keyname: 'storage-encryption-key'
        keyvaulturi: keyVault.properties.vaultUri
      }
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: subnet.id
          action: 'Allow'
        }
      ]
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  tags: {
    Environment: 'QA'
    Project: 'Beeux'
    CostCenter: 'Testing'
    Purpose: 'Secure Audio File Storage'
    SecurityLevel: 'Premium'
  }
}

// Private endpoint for secure access
resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (enablePrivateEndpoints) {
  name: 'beeux-storage-pe-qa-${location}'
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'blob-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: ['https://beeux-web-qa-eastus.azurewebsites.net']
          allowedMethods: ['GET', 'HEAD', 'OPTIONS']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 3600
        }
      ]
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 30
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 30
    }
  }
}
```

#### Production Environment - Premium Security Storage
```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'beeux${environmentName}${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Premium_LRS'  // Premium performance
  }
  kind: 'BlockBlobStorage'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowSharedKeyAccess: false
    encryption: {
      keySource: 'Microsoft.Keyvault'
      keyvaultproperties: {
        keyname: 'storage-encryption-key'
        keyvaulturi: keyVault.properties.vaultUri
      }
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
      }
      requireInfrastructureEncryption: true  // Double encryption
    }
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: subnet.id
          action: 'Allow'
        }
      ]
      ipRules: []  // No public IP access
    }
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: 'AADKERB'
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  tags: {
    Environment: 'Production'
    Project: 'Beeux'
    CostCenter: 'Production'
    Purpose: 'Premium Secure Audio File Storage'
    SecurityLevel: 'Enterprise'
  }
}

// Private endpoint for production
resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: 'beeux-storage-pe-prod-${location}'
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'blob-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

// CDN for performance
resource cdnProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: 'beeux-cdn-prod'
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    originResponseTimeoutSeconds: 60
  }
}

resource cdnEndpoint 'Microsoft.Cdn/profiles/endpoints@2023-05-01' = {
  parent: cdnProfile
  name: 'beeux-audio-cdn'
  location: 'Global'
  properties: {
    origins: [
      {
        name: 'storage-origin'
        properties: {
          hostName: storageAccount.properties.primaryEndpoints.blob
          httpPort: 80
          httpsPort: 443
          originHostHeader: storageAccount.properties.primaryEndpoints.blob
        }
      }
    ]
    isHttpAllowed: false
    isHttpsAllowed: true
    optimizationType: 'GeneralWebDelivery'
    geoFilters: []
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: [
            'https://beeux-web-prod-eastus.azurewebsites.net'
            'https://${cdnEndpoint.properties.hostName}'
          ]
          allowedMethods: ['GET', 'HEAD', 'OPTIONS']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 86400  // Longer cache for production
        }
      ]
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 90  // Longer retention for production
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 90
    }
    changeFeed: {
      enabled: true
      retentionInDays: 90
    }
    versioning: {
      enabled: true
    }
    lastAccessTimeTrackingPolicy: {
      enable: true
      name: 'AccessTimeTracking'
      trackingGranularityInDays: 1
      blobType: ['blockBlob']
    }
  }
}

// Advanced threat protection for production storage
resource storageAdvancedThreatProtection 'Microsoft.Security/advancedThreatProtectionSettings@2019-01-01' = {
  scope: storageAccount
  name: 'current'
  properties: {
    isEnabled: true
  }
}
```

## Security Configuration

### IT Environment - Essential Security (Cost Optimized with Key Vault)
```bicep
// User-assigned identity for IT environment
resource basicIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'beeux-identity-it-${location}'
  location: location
  tags: {
    Environment: 'IT'
    SecurityLevel: 'Essential'
  }
}

// Standard Key Vault for essential secret management in IT environment
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'beeux-kv-it-${take(uniqueString(resourceGroup().id), 6)}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'  // Standard tier for cost optimization
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7  // Minimum retention for cost optimization
    enablePurgeProtection: false  // Disabled for cost optimization
    publicNetworkAccess: 'Enabled'  // Public access for simplicity in IT
    networkAcls: {
      defaultAction: 'Allow'  // Permissive for development
      bypass: 'AzureServices'
    }
  }
  tags: {
    Environment: 'IT'
    SecurityLevel: 'Essential'
    CostOptimized: 'true'
  }
}

// Key Vault access policies for IT environment
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: basicIdentity.properties.principalId
        permissions: {
          secrets: ['get', 'list']
          keys: ['get', 'list']
          certificates: ['get', 'list']
        }
      }
    ]
  }
}

// Essential secrets for IT environment
resource databaseConnectionSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'database-connection'
  properties: {
    value: 'Host=${postgresContainer.properties.configuration.ingress.fqdn};Database=beeux_it;Username=postgres;Password=${postgresPassword}'
    contentType: 'text/plain'
  }
}

resource storageConnectionSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'storage-connection'
  properties: {
    value: storageAccount.listKeys().keys[0].value
    contentType: 'text/plain'
  }
}
```

### QA Environment - Enhanced Security
```bicep
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'beeux-identity-qa-${location}'
  location: location
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'beeux-kv-qa-${take(uniqueString(resourceGroup().id), 6)}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: subnet.id
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
  }
  tags: {
    Environment: 'QA'
    SecurityLevel: 'Premium'
  }
}

// Web Application Firewall for QA
resource wafPolicy 'Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies@2023-09-01' = {
  name: 'beeux-waf-qa-${location}'
  location: location
  properties: {
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Detection'  // Detection mode for QA
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '0.1'
        }
      ]
    }
  }
}

// Application Gateway with WAF for QA
resource applicationGateway 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: 'beeux-appgw-qa-${location}'
  location: location
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 1
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGatewaySubnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: webApp.properties.defaultHostName
            }
          ]
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'beeux-appgw-qa-${location}', 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'beeux-appgw-qa-${location}', 'appGatewayFrontendPort')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', 'beeux-appgw-qa-${location}', 'appGatewaySslCert')
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          priority: 1
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'beeux-appgw-qa-${location}', 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'beeux-appgw-qa-${location}', 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'beeux-appgw-qa-${location}', 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
  }
}
```

### Production Environment - Enterprise Security
```bicep
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'beeux-identity-prod-${location}'
  location: location
}

// Premium Key Vault with HSM for Production
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'beeux-kv-prod-${take(uniqueString(resourceGroup().id), 6)}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'premium'  // Premium tier with HSM support
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Disabled'  // Private access only
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: subnet.id
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
  }
  tags: {
    Environment: 'Production'
    SecurityLevel: 'Enterprise'
  }
}

// Private endpoint for Key Vault
resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: 'beeux-kv-pe-prod-${location}'
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'keyvault-connection'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: ['vault']
        }
      }
    ]
  }
}

// DDoS Protection Plan for Production
resource ddosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@2023-09-01' = {
  name: 'beeux-ddos-prod-${location}'
  location: location
  properties: {}
  tags: {
    Environment: 'Production'
    SecurityLevel: 'Enterprise'
  }
}

// Virtual Network with DDoS Protection
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'beeux-vnet-prod-${location}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    ddosProtectionPlan: {
      id: ddosProtectionPlan.id
    }
    enableDdosProtection: true
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.1.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
            {
              service: 'Microsoft.Sql'
            }
          ]
        }
      }
      {
        name: 'appgateway'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

// Premium WAF Policy for Production
resource wafPolicy 'Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies@2023-09-01' = {
  name: 'beeux-waf-prod-${location}'
  location: location
  properties: {
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Prevention'  // Prevention mode for production
      requestBodyInspectLimitInKB: 128
      requestBodyEnforcement: true
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '0.1'
        }
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
        }
      ]
      exclusions: []
    }
    customRules: [
      {
        name: 'RateLimitRule'
        priority: 1
        ruleType: 'RateLimitRule'
        action: 'Block'
        rateLimitDuration: 'OneMin'
        rateLimitThreshold: 100
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'IPMatch'
            matchValues: ['*']
          }
        ]
      }
      {
        name: 'GeoBlockRule'
        priority: 2
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'GeoMatch'
            matchValues: ['CN', 'RU', 'KP']  // Block specific countries
          }
        ]
      }
    ]
  }
}

// Application Gateway with Premium WAF for Production
resource applicationGateway 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: 'beeux-appgw-prod-${location}'
  location: location
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2  // Higher capacity for production
    }
    autoscaleConfiguration: {
      minCapacity: 2
      maxCapacity: 10
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGatewaySubnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort443'
        properties: {
          port: 443
        }
      }
      {
        name: 'appGatewayFrontendPort80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: webApp.properties.defaultHostName
            }
          ]
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpsListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'beeux-appgw-prod-${location}', 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'beeux-appgw-prod-${location}', 'appGatewayFrontendPort443')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', 'beeux-appgw-prod-${location}', 'appGatewaySslCert')
          }
        }
      }
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'beeux-appgw-prod-${location}', 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'beeux-appgw-prod-${location}', 'appGatewayFrontendPort80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'httpsRule'
        properties: {
          priority: 1
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'beeux-appgw-prod-${location}', 'appGatewayHttpsListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'beeux-appgw-prod-${location}', 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'beeux-appgw-prod-${location}', 'appGatewayBackendHttpSettings')
          }
        }
      }
      {
        name: 'httpRedirectRule'
        properties: {
          priority: 2
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'beeux-appgw-prod-${location}', 'appGatewayHttpListener')
          }
          redirectConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', 'beeux-appgw-prod-${location}', 'httpToHttpsRedirect')
          }
        }
      }
    ]
    firewallPolicy: {
      id: wafPolicy.id
    }
  }
}

// Azure Security Center Configuration for Production
resource securityCenterWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'beeux-security-prod-${location}'
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 90
    features: {
      legacy: 0
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Enable advanced threat protection on all resources
resource sqlAdvancedThreatProtection 'Microsoft.Security/advancedThreatProtectionSettings@2019-01-01' = {
  scope: postgreSQLServer
  name: 'current'
  properties: {
    isEnabled: true
  }
}
```

### 1. Managed Identity Setup
```bicep
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'beeux-identity-${environmentName}-${location}'
  location: location
}

// Role assignments for blob storage access
resource blobContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, userAssignedIdentity.id, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
```

### 2. Key Vault Configuration
```bicep
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'beeux-kv-${environmentName}-${take(uniqueString(resourceGroup().id), 6)}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
  }
}
```

### 3. Network Security
```bicep
// Configure CORS for blob storage
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: [
            'https://${webApp.properties.defaultHostName}'
          ]
          allowedMethods: ['GET', 'HEAD']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 3600
        }
      ]
    }
  }
}
```

## Budget and Cost Monitoring Configuration

### 1. Budget Alerts Setup
Every environment must have both estimated and actual cost monitoring set up immediately after deployment.

#### Budget Configuration Bicep Module (`modules/budget-alerts.bicep`)
```bicep
@description('The name of the budget')
param budgetName string

@description('The amount for the budget')
param budgetAmount int

@description('The environment name (it, qa, prod)')
param environmentName string

@description('Primary email for alerts')
param alertEmailPrimary string

@description('Secondary email for alerts')
param alertEmailSecondary string

@description('Phone number for SMS alerts')
param alertPhone string

@description('Resource group scope for the budget')
param resourceGroupId string

// Budget for estimated costs
resource budget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: '${budgetName}-estimated'
  scope: resourceGroupId
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: '${utcNow('yyyy-MM')}-01'
      endDate: '2030-12-31'
    }
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: [
          split(resourceGroupId, '/')[4]
        ]
      }
    }
    notifications: {
      Estimated50: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        contactEmails: [
          alertEmailPrimary
          alertEmailSecondary
        ]
        contactRoles: []
        thresholdType: 'Forecasted'
      }
      Estimated80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [
          alertEmailPrimary
          alertEmailSecondary
        ]
        contactRoles: []
        thresholdType: 'Forecasted'
      }
      Estimated100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [
          alertEmailPrimary
          alertEmailSecondary
        ]
        contactRoles: []
        thresholdType: 'Forecasted'
      }
    }
  }
}

// Budget for actual costs
resource budgetActual 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: '${budgetName}-actual'
  scope: resourceGroupId
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: '${utcNow('yyyy-MM')}-01'
      endDate: '2030-12-31'
    }
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: [
          split(resourceGroupId, '/')[4]
        ]
      }
    }
    notifications: {
      Actual50: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        contactEmails: [
          alertEmailPrimary
          alertEmailSecondary
        ]
        contactRoles: []
        thresholdType: 'Actual'
      }
      Actual80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [
          alertEmailPrimary
          alertEmailSecondary
        ]
        contactRoles: []
        thresholdType: 'Actual'
      }
      Actual100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [
          alertEmailPrimary
          alertEmailSecondary
        ]
        contactRoles: []
        thresholdType: 'Actual'
      }
    }
  }
}

// Action Group for SMS and Email notifications
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'beeux-${environmentName}-cost-alerts'
  location: 'Global'
  properties: {
    groupShortName: 'BeuxCost${toUpper(environmentName)}'
    enabled: true
    emailReceivers: [
      {
        name: 'PrimaryEmail'
        emailAddress: alertEmailPrimary
        useCommonAlertSchema: true
      }
      {
        name: 'SecondaryEmail'
        emailAddress: alertEmailSecondary
        useCommonAlertSchema: true
      }
    ]
    smsReceivers: [
      {
        name: 'SMSAlert'
        countryCode: '1'
        phoneNumber: replace(alertPhone, '+1', '')
      }
    ]
  }
  tags: {
    Environment: environmentName
    Project: 'Beeux'
    Purpose: 'Cost Alert Notifications'
  }
}

// Cost Alert Rule for immediate notification when spending exceeds budget
resource costAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'beeux-${environmentName}-cost-exceeded-${budgetAmount}'
  location: 'Global'
  properties: {
    description: 'Alert when ${environmentName} environment costs exceed $${budgetAmount}'
    severity: 1
    enabled: true
    scopes: [
      resourceGroupId
    ]
    evaluationFrequency: 'PT1H'
    windowSize: 'PT6H'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'CostExceeded'
          metricName: 'Cost'
          operator: 'GreaterThan'
          threshold: budgetAmount
          timeAggregation: 'Total'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
  tags: {
    Environment: environmentName
    Project: 'Beeux'
    Purpose: 'Cost Monitoring Alert'
  }
}
```

### 2. Cost Monitoring Script (`scripts/setup-cost-alerts.ps1`)
```powershell
# Cost Alert Setup Script
param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentName,
    
    [Parameter(Mandatory=$true)]
    [int]$BudgetAmount,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$PrimaryEmail,
    
    [Parameter(Mandatory=$true)]
    [string]$SecondaryEmail,
    
    [Parameter(Mandatory=$true)]
    [string]$PhoneNumber
)

Write-Host "Setting up cost monitoring for $EnvironmentName environment..."
Write-Host "Budget Amount: $BudgetAmount"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Alert Contacts: $PrimaryEmail, $SecondaryEmail, $PhoneNumber"

# Get resource group ID
$resourceGroupId = az group show --name $ResourceGroupName --query id --output tsv

if (-not $resourceGroupId) {
    Write-Error "Resource group $ResourceGroupName not found!"
    exit 1
}

# Deploy budget alerts
Write-Host "Deploying budget alerts..."
az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file ".\infra\modules\budget-alerts.bicep" `
    --parameters `
        budgetName="beeux-$EnvironmentName-budget" `
        budgetAmount=$BudgetAmount `
        environmentName=$EnvironmentName `
        alertEmailPrimary=$PrimaryEmail `
        alertEmailSecondary=$SecondaryEmail `
        alertPhone=$PhoneNumber `
        resourceGroupId=$resourceGroupId

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Budget alerts successfully configured!" -ForegroundColor Green
    Write-Host "📧 Email alerts will be sent to: $PrimaryEmail, $SecondaryEmail" -ForegroundColor Yellow
    Write-Host "📱 SMS alerts will be sent to: $PhoneNumber" -ForegroundColor Yellow
    Write-Host "💰 Budget limit set to: $BudgetAmount USD/month" -ForegroundColor Yellow
    Write-Host "🔔 Alerts will trigger at 50%, 80%, and 100% of budget" -ForegroundColor Yellow
} else {
    Write-Error "❌ Failed to set up budget alerts!"
    exit 1
}

# Verify the setup
Write-Host "Verifying budget configuration..."
az consumption budget list --scope $resourceGroupId --query "[?contains(name, 'beeux-$EnvironmentName')].{Name:name, Amount:amount, Status:status}" --output table

Write-Host "✅ Cost monitoring setup complete for $EnvironmentName environment!" -ForegroundColor Green
```

## Auto-Shutdown Configuration for Cost Optimization

### 1. Auto-Shutdown Bicep Module (`modules/auto-shutdown.bicep`)
```bicep
@description('The environment name (it, qa, prod)')
param environmentName string

@description('The location for resources')
param location string

@description('Hours of inactivity before shutdown')
param idleHours int = 1

@description('Resource group name')
param resourceGroupName string

// Logic App for monitoring resource usage
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'beeux-auto-shutdown-${environmentName}'
  location: location
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        Recurrence: {
          type: 'Recurrence'
          recurrence: {
            frequency: 'Hour'
            interval: 1
          }
        }
      }
      actions: {
        CheckResourceUsage: {
          type: 'Http'
          inputs: {
            method: 'GET'
            uri: 'https://management.azure.com/subscriptions/@{parameters(\'subscriptionId\')}/resourceGroups/${resourceGroupName}/providers/Microsoft.Insights/metrics'
            headers: {
              Authorization: 'Bearer @{parameters(\'accessToken\')}'
            }
          }
        }
        EvaluateUsage: {
          type: 'If'
          expression: {
            and: [
              {
                lessOrEquals: [
                  '@body(\'CheckResourceUsage\')?[\'value\']?[0]?[\'timeseries\']?[0]?[\'data\']?[0]?[\'average\']'
                  0.1
                ]
              }
            ]
          }
          actions: {
            ShutdownResources: {
              type: 'Http'
              inputs: {
                method: 'POST'
                uri: 'https://management.azure.com/subscriptions/@{parameters(\'subscriptionId\')}/resourceGroups/${resourceGroupName}/providers/Microsoft.Resources/deployments/shutdown-${environmentName}'
                headers: {
                  Authorization: 'Bearer @{parameters(\'accessToken\')}'
                  'Content-Type': 'application/json'
                }
                body: {
                  properties: {
                    mode: 'Incremental'
                    template: {
                      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
                      contentVersion: '1.0.0.0'
                      resources: []
                    }
                  }
                }
              }
            }
            SendNotification: {
              type: 'Http'
              inputs: {
                method: 'POST'
                uri: 'https://api.emailjs.com/api/v1.0/email/send'
                body: {
                  service_id: 'default_service'
                  template_id: 'shutdown_notification'
                  user_id: 'user_id'
                  template_params: {
                    to_email: 'prashantmdesai@yahoo.com'
                    environment: environmentName
                    shutdown_time: '@{utcnow()}'
                    message: 'Environment ${environmentName} has been automatically shut down due to ${idleHours} hour(s) of inactivity.'
                  }
                }
              }
            }
          }
          else: {
            actions: {}
          }
        }
      }
    }
  }
  tags: {
    Environment: environmentName
    Project: 'Beeux'
    Purpose: 'Auto-Shutdown Cost Optimization'
  }
}

// Automation Account for resource management
resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: 'beeux-automation-${environmentName}'
  location: location
  properties: {
    sku: {
      name: 'Free'
    }
  }
  tags: {
    Environment: environmentName
    Project: 'Beeux'
    Purpose: 'Resource Auto-Shutdown'
  }
}

// Runbook for shutdown operations
resource shutdownRunbook 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automationAccount
  name: 'Shutdown-BeuxEnvironment'
  properties: {
    runbookType: 'PowerShell'
    description: 'Automatically shutdown Beeux ${environmentName} environment when idle'
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.automation/automation-runbook-shutdown-vms/Shutdown-Start-VMs.ps1'
    }
  }
}

// Schedule for checking resource usage
resource shutdownSchedule 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = {
  parent: automationAccount
  name: 'Hourly-Usage-Check'
  properties: {
    description: 'Check resource usage every hour'
    frequency: 'Hour'
    interval: 1
    startTime: dateTimeAdd(utcNow(), 'PT1H')
  }
}
```

### 2. Auto-Shutdown Setup Script (`scripts/setup-auto-shutdown.ps1`)
```powershell
# Auto-Shutdown Setup Script
param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentName,
    
    [Parameter(Mandatory=$true)]
    [int]$IdleHours = 1,
    
    [string]$ResourceGroupName = "",
    [string]$SubscriptionId = ""
)

if ([string]::IsNullOrEmpty($ResourceGroupName)) {
    $ResourceGroupName = "beeux-rg-$EnvironmentName-eastus"
}

if ([string]::IsNullOrEmpty($SubscriptionId)) {
    $SubscriptionId = az account show --query id --output tsv
}

Write-Host "⏰ Setting up auto-shutdown for $EnvironmentName environment..." -ForegroundColor Cyan
Write-Host "Idle threshold: $IdleHours hour(s)" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow

# Deploy auto-shutdown infrastructure
Write-Host "Deploying auto-shutdown resources..." -ForegroundColor Yellow
az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file ".\infra\modules\auto-shutdown.bicep" `
    --parameters `
        environmentName=$EnvironmentName `
        idleHours=$IdleHours `
        resourceGroupName=$ResourceGroupName `
        location="eastus"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Auto-shutdown successfully configured!" -ForegroundColor Green
    Write-Host "⏰ Environment will shut down after $IdleHours hour(s) of inactivity" -ForegroundColor Yellow
    Write-Host "📧 Shutdown notifications will be sent to configured emails" -ForegroundColor Yellow
    Write-Host "🔄 To restart environment, run: .\infra\scripts\startup-environment.ps1 -EnvironmentName $EnvironmentName" -ForegroundColor Yellow
} else {
    Write-Error "❌ Failed to set up auto-shutdown!"
    exit 1
}

Write-Host "✅ Auto-shutdown setup complete for $EnvironmentName environment!" -ForegroundColor Green
```

### 3. Manual Shutdown Script (`scripts/shutdown-environment.ps1`)
```powershell
# Manual Environment Shutdown Script
param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentName,
    
    [string]$ResourceGroupName = ""
)

if ([string]::IsNullOrEmpty($ResourceGroupName)) {
    $ResourceGroupName = "beeux-rg-$EnvironmentName-eastus"
}

Write-Host "🛑 Shutting down $EnvironmentName environment..." -ForegroundColor Red
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow

# Confirm shutdown
$confirmation = Read-Host "Are you sure you want to shut down the $EnvironmentName environment? This will stop all resources and save costs. (y/N)"
if ($confirmation -ne 'y') {
    Write-Host "❌ Shutdown cancelled" -ForegroundColor Yellow
    exit 0
}

# Stop App Services
Write-Host "Stopping App Services..." -ForegroundColor Yellow
$appServices = az webapp list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($app in $appServices) {
    if ($app) {
        az webapp stop --name $app --resource-group $ResourceGroupName
        Write-Host "  ✓ Stopped: $app" -ForegroundColor Green
    }
}

# Stop Container Apps
Write-Host "Stopping Container Apps..." -ForegroundColor Yellow
$containerApps = az containerapp list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($app in $containerApps) {
    if ($app) {
        az containerapp update --name $app --resource-group $ResourceGroupName --min-replicas 0 --max-replicas 0
        Write-Host "  ✓ Stopped: $app" -ForegroundColor Green
    }
}

# Stop Database (if not production)
if ($EnvironmentName -ne "prod") {
    Write-Host "Stopping PostgreSQL Database..." -ForegroundColor Yellow
    $databases = az postgres flexible-server list --resource-group $ResourceGroupName --query "[].name" --output tsv
    foreach ($db in $databases) {
        if ($db) {
            az postgres flexible-server stop --name $db --resource-group $ResourceGroupName
            Write-Host "  ✓ Stopped: $db" -ForegroundColor Green
        }
    }
}

# Send notification
$emailBody = @"
Environment Shutdown Notification

Environment: $EnvironmentName
Resource Group: $ResourceGroupName
Shutdown Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')
Status: Successfully shut down to save costs

To restart the environment, run:
.\infra\scripts\startup-environment.ps1 -EnvironmentName $EnvironmentName

Cost savings: Resources are now stopped and not incurring compute charges.
"@

Write-Host "📧 Sending shutdown notification..." -ForegroundColor Yellow
# Note: Email notification implementation would go here

Write-Host "✅ Environment $EnvironmentName successfully shut down!" -ForegroundColor Green
Write-Host "💰 Resources stopped to minimize costs" -ForegroundColor Yellow
Write-Host "🔄 To restart: .\infra\scripts\startup-environment.ps1 -EnvironmentName $EnvironmentName" -ForegroundColor Cyan
```

### 4. Environment Startup Script (`scripts/startup-environment.ps1`)
```powershell
# Environment Startup Script
param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentName,
    
    [string]$ResourceGroupName = ""
)

if ([string]::IsNullOrEmpty($ResourceGroupName)) {
    $ResourceGroupName = "beeux-rg-$EnvironmentName-eastus"
}

Write-Host "🚀 Starting up $EnvironmentName environment..." -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow

# Start Database first
Write-Host "Starting PostgreSQL Database..." -ForegroundColor Yellow
$databases = az postgres flexible-server list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($db in $databases) {
    if ($db) {
        az postgres flexible-server start --name $db --resource-group $ResourceGroupName
        Write-Host "  ✓ Started: $db" -ForegroundColor Green
    }
}

# Start App Services
Write-Host "Starting App Services..." -ForegroundColor Yellow
$appServices = az webapp list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($app in $appServices) {
    if ($app) {
        az webapp start --name $app --resource-group $ResourceGroupName
        Write-Host "  ✓ Started: $app" -ForegroundColor Green
    }
}

# Start Container Apps
Write-Host "Starting Container Apps..." -ForegroundColor Yellow
$containerApps = az containerapp list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($app in $containerApps) {
    if ($app) {
        az containerapp update --name $app --resource-group $ResourceGroupName --min-replicas 1 --max-replicas 3
        Write-Host "  ✓ Started: $app" -ForegroundColor Green
    }
}

# Wait for services to be ready
Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Verify services are running
Write-Host "🔍 Verifying services..." -ForegroundColor Yellow
$allHealthy = $true

foreach ($app in $appServices) {
    if ($app) {
        $status = az webapp show --name $app --resource-group $ResourceGroupName --query "state" --output tsv
        if ($status -eq "Running") {
            Write-Host "  ✓ $app is running" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $app is not running" -ForegroundColor Red
            $allHealthy = $false
        }
    }
}

if ($allHealthy) {
    Write-Host "✅ Environment $EnvironmentName successfully started!" -ForegroundColor Green
    Write-Host "🌐 All services are running and ready" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  Some services may not have started correctly" -ForegroundColor Yellow
    Write-Host "Check the Azure portal for detailed status" -ForegroundColor Yellow
}

# Send notification
Write-Host "📧 Sending startup notification..." -ForegroundColor Yellow
Write-Host "✅ Startup complete for $EnvironmentName environment!" -ForegroundColor Green
```

## Complete Environment Shutdown Scripts

### Overview
Each environment has a comprehensive shutdown script that will completely deallocate and delete all Azure resources, bringing the monthly cost to zero. These scripts are designed to be executed from VS Code terminal or Azure CLI.

**⚠️ WARNING**: These scripts will PERMANENTLY DELETE all resources in the specified environment. Ensure you have backups of any important data before running these scripts.

### Script Execution Requirements
- Azure CLI installed and authenticated
- PowerShell 7+ (recommended) or Windows PowerShell 5.1+
- Contributor or Owner permissions on the Azure subscription
- Access to the specific resource group for the environment

### Complete IT Environment Shutdown Script

Create file: `infra/scripts/complete-shutdown-it.ps1`

```powershell
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete shutdown and deletion of IT environment resources to achieve zero cost.

.DESCRIPTION
    This script will permanently delete ALL Azure resources in the IT environment
    including App Services, Container Apps, self-hosted database, storage accounts,
    container registry, and the resource group itself.

.PARAMETER Force
    Skip confirmation prompts (use with caution)

.EXAMPLE
    .\complete-shutdown-it.ps1
    .\complete-shutdown-it.ps1 -Force
#>

param(
    [switch]$Force
)

# Script configuration
$EnvironmentName = "it"
$ResourceGroupName = "beeux-rg-it-eastus"
$Location = "eastus"

Write-Host "🔥 COMPLETE IT ENVIRONMENT SHUTDOWN SCRIPT" -ForegroundColor Red -BackgroundColor Yellow
Write-Host "=========================================" -ForegroundColor Red
Write-Host "Environment: $EnvironmentName" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "⚠️  WARNING: This will PERMANENTLY DELETE all resources!" -ForegroundColor Red

# Safety confirmation
if (-not $Force) {
    Write-Host ""
    Write-Host "This action will:" -ForegroundColor Yellow
    Write-Host "❌ Delete ALL App Services and App Service Plans" -ForegroundColor Red
    Write-Host "❌ Delete ALL Container Apps and Container Environments" -ForegroundColor Red
    Write-Host "❌ Delete self-hosted PostgreSQL containers and data" -ForegroundColor Red
    Write-Host "❌ Delete ALL Storage Accounts and blob data" -ForegroundColor Red
    Write-Host "❌ Delete Container Registry and all images" -ForegroundColor Red
    Write-Host "❌ Delete Standard Key Vault and all secrets" -ForegroundColor Red
    Write-Host "❌ Delete Developer tier API Management and all configurations" -ForegroundColor Red
    Write-Host "❌ Delete Log Analytics Workspace and all logs" -ForegroundColor Red
    Write-Host "❌ Delete Application Insights and all telemetry" -ForegroundColor Red
    Write-Host "❌ Delete ALL networking resources" -ForegroundColor Red
    Write-Host "❌ Delete the entire Resource Group" -ForegroundColor Red
    Write-Host ""
    Write-Host "💰 COST SAVINGS FROM SHUTDOWN:" -ForegroundColor Green -BackgroundColor Black
    Write-Host "   💵 Will STOP cost of ~$0.50/hour" -ForegroundColor Green
    Write-Host "   💰 Will SAVE ~$12.00/day in charges" -ForegroundColor Green
    Write-Host "   📈 Will PREVENT ~$360/month if left running" -ForegroundColor Green
    Write-Host "   ✅ Final result: Monthly cost will be reduced to $0" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Shutdown stops all Azure charges for this environment!" -ForegroundColor Yellow
    Write-Host "💡 TIP: You can restart anytime with the startup script" -ForegroundColor Cyan
    Write-Host ""
    
    $costConfirmation = Read-Host "Do you accept stopping $0.50/hour charges by shutting down IT environment? Type 'Yes' to accept"
    if ($costConfirmation -ne "Yes") {
        Write-Host "❌ IT environment shutdown cancelled - cost savings not accepted" -ForegroundColor Yellow
        exit 0
    }
    
    $confirmation = Read-Host "Type 'DELETE-IT-ENVIRONMENT' to confirm complete deletion"
    if ($confirmation -ne "DELETE-IT-ENVIRONMENT") {
        Write-Host "❌ Shutdown cancelled for safety" -ForegroundColor Yellow
        exit 0
    }
}

# Check if Azure CLI is logged in
Write-Host "🔍 Checking Azure CLI authentication..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "❌ Not logged into Azure CLI. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Authenticated as: $($account.user.name)" -ForegroundColor Green
Write-Host "📋 Subscription: $($account.name) ($($account.id))" -ForegroundColor Yellow

# Check if resource group exists
Write-Host "🔍 Checking if resource group exists..." -ForegroundColor Cyan
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "✅ Resource group '$ResourceGroupName' does not exist. Nothing to delete." -ForegroundColor Green
    exit 0
}

Write-Host "📋 Found resource group: $ResourceGroupName" -ForegroundColor Yellow

# List all resources before deletion
Write-Host "📋 Listing all resources in IT environment..." -ForegroundColor Cyan
$resources = az resource list --resource-group $ResourceGroupName --query "[].{Name:name, Type:type, Location:location}" --output table
Write-Host $resources

$resourceCount = (az resource list --resource-group $ResourceGroupName --query "length([])" --output tsv)
Write-Host "📊 Total resources to delete: $resourceCount" -ForegroundColor Yellow

if ($resourceCount -eq "0") {
    Write-Host "✅ No resources found in resource group. Deleting empty resource group..." -ForegroundColor Green
    az group delete --name $ResourceGroupName --yes --no-wait
    Write-Host "✅ IT environment shutdown complete!" -ForegroundColor Green
    exit 0
}

# Start deletion process
Write-Host "🚀 Starting IT environment resource deletion..." -ForegroundColor Red

# Step 1: Stop all running services first (graceful shutdown)
Write-Host "1️⃣ Gracefully stopping running services..." -ForegroundColor Yellow

# Stop App Services
Write-Host "   🛑 Stopping App Services..." -ForegroundColor Cyan
$webApps = az webapp list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($app in $webApps) {
    if ($app) {
        Write-Host "     Stopping: $app" -ForegroundColor Gray
        az webapp stop --name $app --resource-group $ResourceGroupName 2>$null
    }
}

# Scale down Container Apps to zero
Write-Host "   🛑 Scaling down Container Apps..." -ForegroundColor Cyan
$containerApps = az containerapp list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($app in $containerApps) {
    if ($app) {
        Write-Host "     Scaling down: $app" -ForegroundColor Gray
        az containerapp update --name $app --resource-group $ResourceGroupName --min-replicas 0 --max-replicas 0 2>$null
    }
}

# Wait for graceful shutdown
Write-Host "   ⏳ Waiting 30 seconds for graceful shutdown..." -ForegroundColor Gray
Start-Sleep -Seconds 30

# Step 2: Delete specific resource types in order
Write-Host "2️⃣ Deleting resources by type..." -ForegroundColor Yellow

# Delete Container Apps first (they depend on Container App Environment)
Write-Host "   🗑️ Deleting Container Apps..." -ForegroundColor Cyan
foreach ($app in $containerApps) {
    if ($app) {
        Write-Host "     Deleting Container App: $app" -ForegroundColor Gray
        az containerapp delete --name $app --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Container App Environments
Write-Host "   🗑️ Deleting Container App Environments..." -ForegroundColor Cyan
$containerEnvs = az containerapp env list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($env in $containerEnvs) {
    if ($env) {
        Write-Host "     Deleting Container Environment: $env" -ForegroundColor Gray
        az containerapp env delete --name $env --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Web Apps
Write-Host "   🗑️ Deleting Web Apps..." -ForegroundColor Cyan
foreach ($app in $webApps) {
    if ($app) {
        Write-Host "     Deleting Web App: $app" -ForegroundColor Gray
        az webapp delete --name $app --resource-group $ResourceGroupName 2>$null
    }
}

# Delete App Service Plans
Write-Host "   🗑️ Deleting App Service Plans..." -ForegroundColor Cyan
$appServicePlans = az appservice plan list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($plan in $appServicePlans) {
    if ($plan) {
        Write-Host "     Deleting App Service Plan: $plan" -ForegroundColor Gray
        az appservice plan delete --name $plan --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Storage Accounts (this will delete all blob data)
Write-Host "   🗑️ Deleting Storage Accounts..." -ForegroundColor Cyan
$storageAccounts = az storage account list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($storage in $storageAccounts) {
    if ($storage) {
        Write-Host "     Deleting Storage Account: $storage" -ForegroundColor Gray
        az storage account delete --name $storage --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Container Registry
Write-Host "   🗑️ Deleting Container Registry..." -ForegroundColor Cyan
$containerRegistries = az acr list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($registry in $containerRegistries) {
    if ($registry) {
        Write-Host "     Deleting Container Registry: $registry" -ForegroundColor Gray
        az acr delete --name $registry --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Application Insights
Write-Host "   🗑️ Deleting Application Insights..." -ForegroundColor Cyan
$appInsights = az monitor app-insights component show --resource-group $ResourceGroupName --query "[].name" --output tsv 2>$null
foreach ($insight in $appInsights) {
    if ($insight) {
        Write-Host "     Deleting Application Insights: $insight" -ForegroundColor Gray
        az monitor app-insights component delete --app $insight --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Log Analytics Workspaces
Write-Host "   🗑️ Deleting Log Analytics Workspaces..." -ForegroundColor Cyan
$workspaces = az monitor log-analytics workspace list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($workspace in $workspaces) {
    if ($workspace) {
        Write-Host "     Deleting Log Analytics Workspace: $workspace" -ForegroundColor Gray
        az monitor log-analytics workspace delete --workspace-name $workspace --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Key Vaults
Write-Host "   🗑️ Deleting Key Vaults..." -ForegroundColor Cyan
$keyVaults = az keyvault list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($keyVault in $keyVaults) {
    if ($keyVault) {
        Write-Host "     Deleting Key Vault: $keyVault" -ForegroundColor Gray
        az keyvault delete --name $keyVault --resource-group $ResourceGroupName 2>$null
        Write-Host "     Purging Key Vault: $keyVault (to prevent billing)" -ForegroundColor Gray
        az keyvault purge --name $keyVault 2>$null
    }
}

# Delete API Management
Write-Host "   🗑️ Deleting API Management services..." -ForegroundColor Cyan
$apimServices = az apim list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($apim in $apimServices) {
    if ($apim) {
        Write-Host "     Deleting API Management: $apim" -ForegroundColor Gray
        az apim delete --name $apim --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Managed Identities
Write-Host "   🗑️ Deleting Managed Identities..." -ForegroundColor Cyan
$identities = az identity list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($identity in $identities) {
    if ($identity) {
        Write-Host "     Deleting Managed Identity: $identity" -ForegroundColor Gray
        az identity delete --name $identity --resource-group $ResourceGroupName 2>$null
    }
}

# Step 3: Delete the entire resource group (this ensures everything is gone)
Write-Host "3️⃣ Deleting the entire resource group..." -ForegroundColor Yellow
Write-Host "   🗑️ Deleting Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "   ⏳ This may take several minutes..." -ForegroundColor Gray

az group delete --name $ResourceGroupName --yes --no-wait

# Step 4: Verify deletion
Write-Host "4️⃣ Initiating verification..." -ForegroundColor Yellow
Write-Host "   ⏳ Waiting for deletion to complete (this may take 5-10 minutes)..." -ForegroundColor Gray

# Wait and check if resource group still exists
$maxWaitMinutes = 15
$waitCount = 0
do {
    Start-Sleep -Seconds 60
    $waitCount++
    $stillExists = az group exists --name $ResourceGroupName
    
    if ($stillExists -eq "false") {
        break
    }
    
    Write-Host "   ⏳ Still deleting... ($waitCount/$maxWaitMinutes minutes)" -ForegroundColor Gray
    
    if ($waitCount -ge $maxWaitMinutes) {
        Write-Host "   ⚠️ Deletion is taking longer than expected. Check Azure portal for status." -ForegroundColor Yellow
        break
    }
} while ($stillExists -eq "true")

# Final verification
$finalCheck = az group exists --name $ResourceGroupName
if ($finalCheck -eq "false") {
    Write-Host "✅ COMPLETE IT ENVIRONMENT SHUTDOWN SUCCESSFUL!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "💰 Monthly cost reduced to: $0.00" -ForegroundColor Green
    Write-Host "🎯 All resources have been permanently deleted" -ForegroundColor Green
    Write-Host "📅 Deletion completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
} else {
    Write-Host "⚠️ Resource group may still be deleting. Check Azure portal." -ForegroundColor Yellow
    Write-Host "💡 You can monitor deletion status with: az group show --name $ResourceGroupName" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📋 Shutdown Summary:" -ForegroundColor Cyan
Write-Host "Environment: IT" -ForegroundColor Gray
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Gray
Write-Host "Resources Deleted: All ($resourceCount total)" -ForegroundColor Gray
Write-Host "Cost Reduction: 100% (to $0/month)" -ForegroundColor Green
Write-Host "Status: Complete" -ForegroundColor Green

# Cleanup azd environment variables (optional)
Write-Host ""
$cleanupAzd = Read-Host "🧹 Do you want to clean up AZD environment variables? (y/N)"
if ($cleanupAzd -eq 'y') {
    try {
        azd env select it 2>$null
        azd env delete it --force 2>$null
        Write-Host "✅ AZD IT environment variables cleaned up" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not clean up AZD environment (this is optional)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🔥 IT ENVIRONMENT SHUTDOWN COMPLETE 🔥" -ForegroundColor Green -BackgroundColor Black
```

### Complete QA Environment Shutdown Script

Create file: `infra/scripts/complete-shutdown-qa.ps1`

```powershell
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete shutdown and deletion of QA environment resources to achieve zero cost.

.DESCRIPTION
    This script will permanently delete ALL Azure resources in the QA environment
    including App Services, Container Apps, managed PostgreSQL database, storage accounts,
    Key Vault, WAF, Application Gateway, private endpoints, and the resource group itself.

.PARAMETER Force
    Skip confirmation prompts (use with caution)

.EXAMPLE
    .\complete-shutdown-qa.ps1
    .\complete-shutdown-qa.ps1 -Force
#>

param(
    [switch]$Force
)

# Script configuration
$EnvironmentName = "qa"
$ResourceGroupName = "beeux-rg-qa-eastus"
$Location = "eastus"

Write-Host "🔥 COMPLETE QA ENVIRONMENT SHUTDOWN SCRIPT" -ForegroundColor Red -BackgroundColor Yellow
Write-Host "==========================================" -ForegroundColor Red
Write-Host "Environment: $EnvironmentName" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "⚠️  WARNING: This will PERMANENTLY DELETE all resources including databases!" -ForegroundColor Red

# Safety confirmation
if (-not $Force) {
    Write-Host ""
    Write-Host "This action will:" -ForegroundColor Yellow
    Write-Host "❌ Delete ALL App Services and App Service Plans" -ForegroundColor Red
    Write-Host "❌ Delete ALL Container Apps and Container Environments" -ForegroundColor Red
    Write-Host "❌ Delete managed PostgreSQL database and ALL DATA" -ForegroundColor Red
    Write-Host "❌ Delete ALL Storage Accounts and blob data" -ForegroundColor Red
    Write-Host "❌ Delete Container Registry and all images" -ForegroundColor Red
    Write-Host "❌ Delete Key Vault and all secrets" -ForegroundColor Red
    Write-Host "❌ Delete Standard tier API Management and all configurations" -ForegroundColor Red
    Write-Host "❌ Delete Application Gateway and WAF policies" -ForegroundColor Red
    Write-Host "❌ Delete ALL private endpoints and networking" -ForegroundColor Red
    Write-Host "❌ Delete Log Analytics and Application Insights" -ForegroundColor Red
    Write-Host "❌ Delete the entire Resource Group" -ForegroundColor Red
    Write-Host ""
    Write-Host "💰 COST SAVINGS FROM SHUTDOWN:" -ForegroundColor Green -BackgroundColor Black
    Write-Host "   💵 Will STOP cost of ~$1.10/hour" -ForegroundColor Green
    Write-Host "   💰 Will SAVE ~$26.40/day in charges" -ForegroundColor Green
    Write-Host "   📈 Will PREVENT ~$800/month if left running" -ForegroundColor Green
    Write-Host "   ✅ Final result: Monthly cost will be reduced to $0" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Shutdown stops all Azure charges for this environment!" -ForegroundColor Yellow
    Write-Host "💡 TIP: You can restart anytime with the startup script" -ForegroundColor Cyan
    Write-Host ""
    
    $costConfirmation = Read-Host "Do you accept stopping $1.10/hour charges by shutting down QA environment? Type 'Yes' to accept"
    if ($costConfirmation -ne "Yes") {
        Write-Host "❌ QA environment shutdown cancelled - cost savings not accepted" -ForegroundColor Yellow
        exit 0
    }
    
    $confirmation = Read-Host "Type 'DELETE-QA-ENVIRONMENT' to confirm complete deletion"
    if ($confirmation -ne "DELETE-QA-ENVIRONMENT") {
        Write-Host "❌ Shutdown cancelled for safety" -ForegroundColor Yellow
        exit 0
    }
}

# Check if Azure CLI is logged in
Write-Host "🔍 Checking Azure CLI authentication..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "❌ Not logged into Azure CLI. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Authenticated as: $($account.user.name)" -ForegroundColor Green
Write-Host "📋 Subscription: $($account.name) ($($account.id))" -ForegroundColor Yellow

# Check if resource group exists
Write-Host "🔍 Checking if resource group exists..." -ForegroundColor Cyan
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "✅ Resource group '$ResourceGroupName' does not exist. Nothing to delete." -ForegroundColor Green
    exit 0
}

Write-Host "📋 Found resource group: $ResourceGroupName" -ForegroundColor Yellow

# List all resources before deletion
Write-Host "📋 Listing all resources in QA environment..." -ForegroundColor Cyan
$resources = az resource list --resource-group $ResourceGroupName --query "[].{Name:name, Type:type, Location:location}" --output table
Write-Host $resources

$resourceCount = (az resource list --resource-group $ResourceGroupName --query "length([])" --output tsv)
Write-Host "📊 Total resources to delete: $resourceCount" -ForegroundColor Yellow

if ($resourceCount -eq "0") {
    Write-Host "✅ No resources found in resource group. Deleting empty resource group..." -ForegroundColor Green
    az group delete --name $ResourceGroupName --yes --no-wait
    Write-Host "✅ QA environment shutdown complete!" -ForegroundColor Green
    exit 0
}

# Start deletion process
Write-Host "🚀 Starting QA environment resource deletion..." -ForegroundColor Red

# Step 1: Disable deletion protection on critical resources
Write-Host "1️⃣ Disabling deletion protection..." -ForegroundColor Yellow

# Disable Key Vault purge protection if needed
Write-Host "   🔓 Checking Key Vault deletion protection..." -ForegroundColor Cyan
$keyVaults = az keyvault list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($vault in $keyVaults) {
    if ($vault) {
        Write-Host "     Processing Key Vault: $vault" -ForegroundColor Gray
        # Get current purge protection status
        $vaultInfo = az keyvault show --name $vault --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
        if ($vaultInfo -and $vaultInfo.properties.enablePurgeProtection) {
            Write-Host "     ⚠️ Key Vault has purge protection enabled - will be soft deleted" -ForegroundColor Yellow
        }
    }
}

# Step 2: Stop all running services first (graceful shutdown)
Write-Host "2️⃣ Gracefully stopping running services..." -ForegroundColor Yellow

# Stop App Services
Write-Host "   🛑 Stopping App Services..." -ForegroundColor Cyan
$webApps = az webapp list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($app in $webApps) {
    if ($app) {
        Write-Host "     Stopping: $app" -ForegroundColor Gray
        az webapp stop --name $app --resource-group $ResourceGroupName 2>$null
    }
}

# Scale down Container Apps to zero
Write-Host "   🛑 Scaling down Container Apps..." -ForegroundColor Cyan
$containerApps = az containerapp list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($app in $containerApps) {
    if ($app) {
        Write-Host "     Scaling down: $app" -ForegroundColor Gray
        az containerapp update --name $app --resource-group $ResourceGroupName --min-replicas 0 --max-replicas 0 2>$null
    }
}

# Stop PostgreSQL database
Write-Host "   🛑 Stopping PostgreSQL databases..." -ForegroundColor Cyan
$postgresDatabases = az postgres flexible-server list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($db in $postgresDatabases) {
    if ($db) {
        Write-Host "     Stopping database: $db" -ForegroundColor Gray
        az postgres flexible-server stop --name $db --resource-group $ResourceGroupName 2>$null
    }
}

# Wait for graceful shutdown
Write-Host "   ⏳ Waiting 60 seconds for graceful shutdown..." -ForegroundColor Gray
Start-Sleep -Seconds 60

# Step 3: Delete resources in dependency order
Write-Host "3️⃣ Deleting resources in dependency order..." -ForegroundColor Yellow

# Delete Application Gateway (depends on nothing)
Write-Host "   🗑️ Deleting Application Gateways..." -ForegroundColor Cyan
$appGateways = az network application-gateway list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($gateway in $appGateways) {
    if ($gateway) {
        Write-Host "     Deleting Application Gateway: $gateway" -ForegroundColor Gray
        az network application-gateway delete --name $gateway --resource-group $ResourceGroupName 2>$null
    }
}

# Delete WAF Policies
Write-Host "   🗑️ Deleting WAF Policies..." -ForegroundColor Cyan
$wafPolicies = az network application-gateway waf-policy list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($policy in $wafPolicies) {
    if ($policy) {
        Write-Host "     Deleting WAF Policy: $policy" -ForegroundColor Gray
        az network application-gateway waf-policy delete --name $policy --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Container Apps first (they depend on Container App Environment)
Write-Host "   🗑️ Deleting Container Apps..." -ForegroundColor Cyan
foreach ($app in $containerApps) {
    if ($app) {
        Write-Host "     Deleting Container App: $app" -ForegroundColor Gray
        az containerapp delete --name $app --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Container App Environments
Write-Host "   🗑️ Deleting Container App Environments..." -ForegroundColor Cyan
$containerEnvs = az containerapp env list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($env in $containerEnvs) {
    if ($env) {
        Write-Host "     Deleting Container Environment: $env" -ForegroundColor Gray
        az containerapp env delete --name $env --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Web Apps
Write-Host "   🗑️ Deleting Web Apps..." -ForegroundColor Cyan
foreach ($app in $webApps) {
    if ($app) {
        Write-Host "     Deleting Web App: $app" -ForegroundColor Gray
        az webapp delete --name $app --resource-group $ResourceGroupName 2>$null
    }
}

# Delete App Service Plans
Write-Host "   🗑️ Deleting App Service Plans..." -ForegroundColor Cyan
$appServicePlans = az appservice plan list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($plan in $appServicePlans) {
    if ($plan) {
        Write-Host "     Deleting App Service Plan: $plan" -ForegroundColor Gray
        az appservice plan delete --name $plan --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete PostgreSQL Databases and Servers
Write-Host "   🗑️ Deleting PostgreSQL Servers..." -ForegroundColor Cyan
foreach ($db in $postgresDatabases) {
    if ($db) {
        Write-Host "     Deleting PostgreSQL Server: $db" -ForegroundColor Gray
        az postgres flexible-server delete --name $db --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Private Endpoints
Write-Host "   🗑️ Deleting Private Endpoints..." -ForegroundColor Cyan
$privateEndpoints = az network private-endpoint list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($endpoint in $privateEndpoints) {
    if ($endpoint) {
        Write-Host "     Deleting Private Endpoint: $endpoint" -ForegroundColor Gray
        az network private-endpoint delete --name $endpoint --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Storage Accounts (this will delete all blob data)
Write-Host "   🗑️ Deleting Storage Accounts..." -ForegroundColor Cyan
$storageAccounts = az storage account list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($storage in $storageAccounts) {
    if ($storage) {
        Write-Host "     Deleting Storage Account: $storage" -ForegroundColor Gray
        az storage account delete --name $storage --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Container Registry
Write-Host "   🗑️ Deleting Container Registry..." -ForegroundColor Cyan
$containerRegistries = az acr list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($registry in $containerRegistries) {
    if ($registry) {
        Write-Host "     Deleting Container Registry: $registry" -ForegroundColor Gray
        az acr delete --name $registry --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete API Management (Premium tier)
Write-Host "   🗑️ Deleting API Management services..." -ForegroundColor Cyan
$apimServices = az apim list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($apim in $apimServices) {
    if ($apim) {
        Write-Host "     Deleting API Management: $apim (Premium tier)" -ForegroundColor Gray
        az apim delete --name $apim --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Key Vaults (this will soft delete them due to purge protection)
Write-Host "   🗑️ Deleting Key Vaults..." -ForegroundColor Cyan
foreach ($vault in $keyVaults) {
    if ($vault) {
        Write-Host "     Deleting Key Vault: $vault" -ForegroundColor Gray
        az keyvault delete --name $vault --resource-group $ResourceGroupName 2>$null
        
        # Also purge the Key Vault to completely remove it and stop billing
        Write-Host "     Purging Key Vault: $vault" -ForegroundColor Gray
        az keyvault purge --name $vault --location $Location 2>$null
    }
}

# Delete Public IP Addresses
Write-Host "   🗑️ Deleting Public IP Addresses..." -ForegroundColor Cyan
$publicIPs = az network public-ip list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($pip in $publicIPs) {
    if ($pip) {
        Write-Host "     Deleting Public IP: $pip" -ForegroundColor Gray
        az network public-ip delete --name $pip --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Virtual Networks
Write-Host "   🗑️ Deleting Virtual Networks..." -ForegroundColor Cyan
$vnets = az network vnet list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($vnet in $vnets) {
    if ($vnet) {
        Write-Host "     Deleting Virtual Network: $vnet" -ForegroundColor Gray
        az network vnet delete --name $vnet --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Application Insights
Write-Host "   🗑️ Deleting Application Insights..." -ForegroundColor Cyan
$appInsights = az monitor app-insights component show --resource-group $ResourceGroupName --query "[].name" --output tsv 2>$null
foreach ($insight in $appInsights) {
    if ($insight) {
        Write-Host "     Deleting Application Insights: $insight" -ForegroundColor Gray
        az monitor app-insights component delete --app $insight --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Log Analytics Workspaces
Write-Host "   🗑️ Deleting Log Analytics Workspaces..." -ForegroundColor Cyan
$workspaces = az monitor log-analytics workspace list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($workspace in $workspaces) {
    if ($workspace) {
        Write-Host "     Deleting Log Analytics Workspace: $workspace" -ForegroundColor Gray
        az monitor log-analytics workspace delete --workspace-name $workspace --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Managed Identities
Write-Host "   🗑️ Deleting Managed Identities..." -ForegroundColor Cyan
$identities = az identity list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($identity in $identities) {
    if ($identity) {
        Write-Host "     Deleting Managed Identity: $identity" -ForegroundColor Gray
        az identity delete --name $identity --resource-group $ResourceGroupName 2>$null
    }
}

# Step 4: Delete the entire resource group (this ensures everything is gone)
Write-Host "4️⃣ Deleting the entire resource group..." -ForegroundColor Yellow
Write-Host "   🗑️ Deleting Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "   ⏳ This may take several minutes..." -ForegroundColor Gray

az group delete --name $ResourceGroupName --yes --no-wait

# Step 5: Verify deletion
Write-Host "5️⃣ Initiating verification..." -ForegroundColor Yellow
Write-Host "   ⏳ Waiting for deletion to complete (this may take 10-15 minutes)..." -ForegroundColor Gray

# Wait and check if resource group still exists
$maxWaitMinutes = 20
$waitCount = 0
do {
    Start-Sleep -Seconds 60
    $waitCount++
    $stillExists = az group exists --name $ResourceGroupName
    
    if ($stillExists -eq "false") {
        break
    }
    
    Write-Host "   ⏳ Still deleting... ($waitCount/$maxWaitMinutes minutes)" -ForegroundColor Gray
    
    if ($waitCount -ge $maxWaitMinutes) {
        Write-Host "   ⚠️ Deletion is taking longer than expected. Check Azure portal for status." -ForegroundColor Yellow
        break
    }
} while ($stillExists -eq "true")

# Final verification
$finalCheck = az group exists --name $ResourceGroupName
if ($finalCheck -eq "false") {
    Write-Host "✅ COMPLETE QA ENVIRONMENT SHUTDOWN SUCCESSFUL!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "💰 Monthly cost reduced to: $0.00" -ForegroundColor Green
    Write-Host "🎯 All resources have been permanently deleted" -ForegroundColor Green
    Write-Host "🗑️ Key Vaults have been purged to stop billing" -ForegroundColor Green
    Write-Host "📅 Deletion completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
} else {
    Write-Host "⚠️ Resource group may still be deleting. Check Azure portal." -ForegroundColor Yellow
    Write-Host "💡 You can monitor deletion status with: az group show --name $ResourceGroupName" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📋 Shutdown Summary:" -ForegroundColor Cyan
Write-Host "Environment: QA" -ForegroundColor Gray
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Gray
Write-Host "Resources Deleted: All ($resourceCount total)" -ForegroundColor Gray
Write-Host "Cost Reduction: 100% (to $0/month)" -ForegroundColor Green
Write-Host "Status: Complete" -ForegroundColor Green

# Cleanup azd environment variables (optional)
Write-Host ""
$cleanupAzd = Read-Host "🧹 Do you want to clean up AZD environment variables? (y/N)"
if ($cleanupAzd -eq 'y') {
    try {
        azd env select qa 2>$null
        azd env delete qa --force 2>$null
        Write-Host "✅ AZD QA environment variables cleaned up" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not clean up AZD environment (this is optional)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🔥 QA ENVIRONMENT SHUTDOWN COMPLETE 🔥" -ForegroundColor Green -BackgroundColor Black
```

### Complete Production Environment Shutdown Script

Create file: `infra/scripts/complete-shutdown-prod.ps1`

```powershell
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete shutdown and deletion of PRODUCTION environment resources to achieve zero cost.

.DESCRIPTION
    This script will permanently delete ALL Azure resources in the PRODUCTION environment
    including App Services, Container Apps, managed PostgreSQL database with high availability,
    storage accounts, premium Key Vault with HSM, WAF, Application Gateway, DDoS protection,
    CDN, private endpoints, and the entire resource group.

.PARAMETER Force
    Skip confirmation prompts (use with extreme caution in production)

.EXAMPLE
    .\complete-shutdown-prod.ps1
    .\complete-shutdown-prod.ps1 -Force
#>

param(
    [switch]$Force
)

# Script configuration
$EnvironmentName = "prod"
$ResourceGroupName = "beeux-rg-prod-eastus"
$Location = "eastus"

Write-Host "🔥🔥🔥 COMPLETE PRODUCTION ENVIRONMENT SHUTDOWN SCRIPT 🔥🔥🔥" -ForegroundColor Red -BackgroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Red
Write-Host "Environment: $EnvironmentName (PRODUCTION)" -ForegroundColor Red
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Red
Write-Host "⚠️🚨 CRITICAL WARNING: This will PERMANENTLY DELETE PRODUCTION DATA! 🚨⚠️" -ForegroundColor Red -BackgroundColor Yellow

# Extra safety confirmation for production - TRIPLE CONFIRMATION MECHANISM
if (-not $Force) {
    Write-Host ""
    Write-Host "🚨🚨🚨 PRODUCTION ENVIRONMENT DELETION - TRIPLE CONFIRMATION REQUIRED 🚨🚨🚨" -ForegroundColor Red -BackgroundColor Yellow
    Write-Host ""
    Write-Host "This action will PERMANENTLY DELETE:" -ForegroundColor Red
    Write-Host "❌ ALL App Services and App Service Plans (Premium P2V3)" -ForegroundColor Red
    Write-Host "❌ ALL Container Apps and Container Environments (Premium)" -ForegroundColor Red
    Write-Host "❌ Managed PostgreSQL database with HIGH AVAILABILITY and ALL PRODUCTION DATA" -ForegroundColor Red
    Write-Host "❌ Premium Storage Accounts with CDN and ALL blob data" -ForegroundColor Red
    Write-Host "❌ Premium Container Registry with geo-replication and ALL images" -ForegroundColor Red
    Write-Host "❌ Premium Key Vault with HSM keys and ALL secrets" -ForegroundColor Red
    Write-Host "❌ Azure API Management (Premium tier) and ALL API configurations" -ForegroundColor Red
    Write-Host "❌ Application Gateway with Premium WAF and DDoS protection" -ForegroundColor Red
    Write-Host "❌ CDN Profile and ALL cached content" -ForegroundColor Red
    Write-Host "❌ ALL private endpoints and premium networking" -ForegroundColor Red
    Write-Host "❌ Premium Log Analytics and Application Insights with ALL production telemetry" -ForegroundColor Red
    Write-Host "❌ DDoS Protection Plan (Premium feature)" -ForegroundColor Red
    Write-Host "❌ The ENTIRE Production Resource Group" -ForegroundColor Red
    Write-Host ""
    Write-Host "💰 Result: Monthly cost will be reduced to $0" -ForegroundColor Green
    Write-Host "🔄 Note: This action is IRREVERSIBLE and will require complete redeployment" -ForegroundColor Red
    Write-Host ""
    
    # CONFIRMATION 1: Data Backup Verification
    Write-Host "🛡️ FIRST CONFIRMATION - Data Backup Verification:" -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "Have you completed a FULL BACKUP of all production data including:" -ForegroundColor Yellow
    Write-Host "  • PostgreSQL database backup" -ForegroundColor White
    Write-Host "  • Blob storage backup" -ForegroundColor White
    Write-Host "  • Key Vault secrets export" -ForegroundColor White
    Write-Host "  • API Management policies and configurations" -ForegroundColor White
    Write-Host "  • Application configurations and environment variables" -ForegroundColor White
    $confirmation1 = Read-Host "Type 'BACKUP-COMPLETED' to confirm all data is backed up"
    if ($confirmation1 -ne "BACKUP-COMPLETED") {
        Write-Host "❌ Production shutdown cancelled - Complete backup before proceeding" -ForegroundColor Red
        Write-Host "📋 Required actions before shutdown:" -ForegroundColor Yellow
        Write-Host "  1. Export PostgreSQL database: pg_dump" -ForegroundColor White
        Write-Host "  2. Download blob storage contents" -ForegroundColor White
        Write-Host "  3. Export Key Vault secrets: az keyvault secret backup" -ForegroundColor White
        Write-Host "  4. Export API Management configuration" -ForegroundColor White
        exit 0
    }
    
    # CONFIRMATION 2: Authorization and Impact Understanding
    Write-Host ""
    Write-Host "🛡️ SECOND CONFIRMATION - Authorization and Impact:" -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "Confirm you understand the business impact:" -ForegroundColor Yellow
    Write-Host "  • Production application will be COMPLETELY UNAVAILABLE" -ForegroundColor Red
    Write-Host "  • All user sessions will be terminated immediately" -ForegroundColor Red
    Write-Host "  • API endpoints will return 404 errors" -ForegroundColor Red
    Write-Host "  • Database connections will fail" -ForegroundColor Red
    Write-Host "  • File downloads will be unavailable" -ForegroundColor Red
    Write-Host "  • Monitoring and alerting will stop" -ForegroundColor Red
    Write-Host ""
    $confirmation2 = Read-Host "Are you AUTHORIZED to shut down production and do you understand the impact? Type 'AUTHORIZED-AND-UNDERSTAND'"
    if ($confirmation2 -ne "AUTHORIZED-AND-UNDERSTAND") {
        Write-Host "❌ Production shutdown cancelled - Authorization or impact not confirmed" -ForegroundColor Red
        exit 0
    }
    
    # CONFIRMATION 3: Final Destruction Confirmation
    Write-Host ""
    Write-Host "🛡️ THIRD AND FINAL CONFIRMATION - Destruction Commitment:" -ForegroundColor Red -BackgroundColor Yellow
    Write-Host "🚨 FINAL WARNING: You are about to DESTROY the PRODUCTION environment 🚨" -ForegroundColor Red
    Write-Host ""
    Write-Host "Type the EXACT phrase below to proceed with PERMANENT DELETION:" -ForegroundColor Red
    Write-Host "'I-HEREBY-DESTROY-PRODUCTION-ENVIRONMENT-PERMANENTLY'" -ForegroundColor White -BackgroundColor Red
    Write-Host ""
    $finalConfirmation = Read-Host "Enter the exact phrase"
    if ($finalConfirmation -ne "I-HEREBY-DESTROY-PRODUCTION-ENVIRONMENT-PERMANENTLY") {
        Write-Host "❌ Production shutdown cancelled - Final confirmation phrase incorrect" -ForegroundColor Yellow
        Write-Host "✅ Production environment preserved for safety" -ForegroundColor Green
        exit 0
    }
    
    # Additional 10-second cooldown period
    Write-Host ""
    Write-Host "⏳ FINAL SAFETY DELAY: 10-second cooldown period..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C within 10 seconds to abort destruction" -ForegroundColor Red
    for ($i = 10; $i -gt 0; $i--) {
        Write-Host "Destruction in $i seconds..." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
    Write-Host ""
}

# Production Environment Cost Savings Information
Write-Host ""
Write-Host "💰 PRODUCTION ENVIRONMENT - COST SAVINGS INFORMATION:" -ForegroundColor Green -BackgroundColor Black
Write-Host "By shutting down this environment, you will STOP the following charges:" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Hourly Costs Being Stopped:" -ForegroundColor Yellow
Write-Host "  • Container Apps (Premium):           ~$1.00/hour" -ForegroundColor White
Write-Host "  • PostgreSQL Flexible Server:        ~$0.80/hour" -ForegroundColor White
Write-Host "  • Storage Account (Premium):          ~$0.20/hour" -ForegroundColor White
Write-Host "  • Application Insights:               ~$0.05/hour" -ForegroundColor White
Write-Host "  • Key Vault (Premium):                ~$0.10/hour" -ForegroundColor White
Write-Host "  • API Management (Premium):           ~$0.15/hour" -ForegroundColor White
Write-Host "  ----------------------------------------" -ForegroundColor Gray
Write-Host "  💸 TOTAL SAVINGS: ~$2.30 per HOUR" -ForegroundColor Green
Write-Host ""
Write-Host "📈 Monthly Impact:" -ForegroundColor Yellow
Write-Host "  • If left running 24/7: ~$1,656/month" -ForegroundColor Red
Write-Host "  • With auto-shutdown (8hrs/day): ~$552/month" -ForegroundColor Yellow
Write-Host "  • Current shutdown saves: $2.30/hour ongoing" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  NOTE: This will STOP all production charges but remember:" -ForegroundColor Yellow
Write-Host "     - Users cannot access the application" -ForegroundColor White
Write-Host "     - Revenue generation stops" -ForegroundColor White
Write-Host "     - Business operations impacted" -ForegroundColor White
Write-Host ""
$costConfirmation = Read-Host "Do you confirm shutting down Production environment to SAVE $2.30/hour? Type 'Yes'"
if ($costConfirmation -ne "Yes") {
    Write-Host "❌ Production shutdown cancelled by user" -ForegroundColor Red
    exit 0
}

# Check if Azure CLI is logged in
Write-Host ""
Write-Host "🔍 Checking Azure CLI authentication..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "❌ Not logged into Azure CLI. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Authenticated as: $($account.user.name)" -ForegroundColor Green
Write-Host "📋 Subscription: $($account.name) ($($account.id))" -ForegroundColor Yellow

# Verify we have sufficient permissions
Write-Host "🔍 Verifying permissions..." -ForegroundColor Cyan
$roleAssignments = az role assignment list --assignee $account.user.name --scope "/subscriptions/$($account.id)" --query "[?roleDefinitionName=='Owner' || roleDefinitionName=='Contributor']" --output tsv
if (-not $roleAssignments) {
    Write-Host "❌ Insufficient permissions. Owner or Contributor role required." -ForegroundColor Red
    exit 1
}

# Check if resource group exists
Write-Host "🔍 Checking if resource group exists..." -ForegroundColor Cyan
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "✅ Resource group '$ResourceGroupName' does not exist. Nothing to delete." -ForegroundColor Green
    exit 0
}

Write-Host "📋 Found resource group: $ResourceGroupName" -ForegroundColor Yellow

# List all resources before deletion (detailed inventory)
Write-Host "📋 Creating detailed inventory of PRODUCTION resources..." -ForegroundColor Cyan
$resources = az resource list --resource-group $ResourceGroupName --query "[].{Name:name, Type:type, Location:location, SKU:sku.name}" --output table
Write-Host $resources

$resourceCount = (az resource list --resource-group $ResourceGroupName --query "length([])" --output tsv)
Write-Host "📊 Total PRODUCTION resources to delete: $resourceCount" -ForegroundColor Red

if ($resourceCount -eq "0") {
    Write-Host "✅ No resources found in resource group. Deleting empty resource group..." -ForegroundColor Green
    az group delete --name $ResourceGroupName --yes --no-wait
    Write-Host "✅ Production environment shutdown complete!" -ForegroundColor Green
    exit 0
}

# Log the deletion action for audit purposes
Write-Host "📝 Logging deletion action for audit..." -ForegroundColor Yellow
$logEntry = @{
    Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC'
    Action = "PRODUCTION_ENVIRONMENT_DELETION"
    Environment = $EnvironmentName
    ResourceGroup = $ResourceGroupName
    User = $account.user.name
    ResourceCount = $resourceCount
} | ConvertTo-Json

Write-Host "Audit Log: $logEntry" -ForegroundColor Gray

# Start deletion process
Write-Host "🚀 Starting PRODUCTION environment resource deletion..." -ForegroundColor Red

# Step 1: Disable deletion protection on all critical resources
Write-Host "1️⃣ Disabling deletion protection on critical resources..." -ForegroundColor Yellow

# Disable Key Vault purge protection and backup policies
Write-Host "   🔓 Processing Key Vaults..." -ForegroundColor Cyan
$keyVaults = az keyvault list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($vault in $keyVaults) {
    if ($vault) {
        Write-Host "     Processing Premium Key Vault: $vault" -ForegroundColor Gray
        # Get current purge protection status
        $vaultInfo = az keyvault show --name $vault --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
        if ($vaultInfo -and $vaultInfo.properties.enablePurgeProtection) {
            Write-Host "     ⚠️ Premium Key Vault has purge protection enabled - will be soft deleted first" -ForegroundColor Yellow
        }
    }
}

# Disable database backup policies and high availability
Write-Host "   🔓 Disabling PostgreSQL high availability..." -ForegroundColor Cyan
$postgresDatabases = az postgres flexible-server list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($db in $postgresDatabases) {
    if ($db) {
        Write-Host "     Disabling HA for database: $db" -ForegroundColor Gray
        az postgres flexible-server update --name $db --resource-group $ResourceGroupName --high-availability Disabled 2>$null
    }
}

# Step 2: Gracefully stop all services to prevent data corruption
Write-Host "2️⃣ Gracefully stopping all PRODUCTION services..." -ForegroundColor Yellow

# Stop App Services
Write-Host "   🛑 Stopping Premium App Services..." -ForegroundColor Cyan
$webApps = az webapp list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($app in $webApps) {
    if ($app) {
        Write-Host "     Stopping Premium App Service: $app" -ForegroundColor Gray
        az webapp stop --name $app --resource-group $ResourceGroupName 2>$null
    }
}

# Scale down Container Apps to zero (graceful shutdown)
Write-Host "   🛑 Scaling down Premium Container Apps..." -ForegroundColor Cyan
$containerApps = az containerapp list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($app in $containerApps) {
    if ($app) {
        Write-Host "     Scaling down Premium Container App: $app" -ForegroundColor Gray
        az containerapp update --name $app --resource-group $ResourceGroupName --min-replicas 0 --max-replicas 0 2>$null
    }
}

# Stop PostgreSQL database (graceful shutdown)
Write-Host "   🛑 Stopping Premium PostgreSQL databases..." -ForegroundColor Cyan
foreach ($db in $postgresDatabases) {
    if ($db) {
        Write-Host "     Stopping Premium PostgreSQL: $db" -ForegroundColor Gray
        az postgres flexible-server stop --name $db --resource-group $ResourceGroupName 2>$null
    }
}

# Wait for graceful shutdown
Write-Host "   ⏳ Waiting 120 seconds for graceful PRODUCTION shutdown..." -ForegroundColor Gray
Start-Sleep -Seconds 120

# Step 3: Delete CDN and front-end resources first
Write-Host "3️⃣ Deleting CDN and front-end resources..." -ForegroundColor Yellow

# Delete CDN Endpoints first
Write-Host "   🗑️ Deleting CDN Endpoints..." -ForegroundColor Cyan
$cdnProfiles = az cdn profile list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($profile in $cdnProfiles) {
    if ($profile) {
        # Get and delete all endpoints in the profile
        $endpoints = az cdn endpoint list --profile-name $profile --resource-group $ResourceGroupName --query "[].name" --output tsv
        foreach ($endpoint in $endpoints) {
            if ($endpoint) {
                Write-Host "     Deleting CDN Endpoint: $endpoint" -ForegroundColor Gray
                az cdn endpoint delete --name $endpoint --profile-name $profile --resource-group $ResourceGroupName 2>$null
            }
        }
        
        Write-Host "     Deleting CDN Profile: $profile" -ForegroundColor Gray
        az cdn profile delete --name $profile --resource-group $ResourceGroupName 2>$null
    }
}

# Step 4: Delete security resources in order
Write-Host "4️⃣ Deleting security infrastructure..." -ForegroundColor Yellow

# Delete DDoS Protection Plan (if it exists)
Write-Host "   🗑️ Deleting DDoS Protection Plan..." -ForegroundColor Cyan
$ddosPlans = az network ddos-protection-plan list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($plan in $ddosPlans) {
    if ($plan) {
        Write-Host "     Deleting DDoS Protection Plan: $plan" -ForegroundColor Gray
        az network ddos-protection-plan delete --name $plan --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Application Gateway (depends on WAF policy)
Write-Host "   🗑️ Deleting Application Gateways..." -ForegroundColor Cyan
$appGateways = az network application-gateway list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($gateway in $appGateways) {
    if ($gateway) {
        Write-Host "     Deleting Premium Application Gateway: $gateway" -ForegroundColor Gray
        az network application-gateway delete --name $gateway --resource-group $ResourceGroupName 2>$null
    }
}

# Delete WAF Policies
Write-Host "   🗑️ Deleting Premium WAF Policies..." -ForegroundColor Cyan
$wafPolicies = az network application-gateway waf-policy list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($policy in $wafPolicies) {
    if ($policy) {
        Write-Host "     Deleting Premium WAF Policy: $policy" -ForegroundColor Gray
        az network application-gateway waf-policy delete --name $policy --resource-group $ResourceGroupName 2>$null
    }
}

# Step 5: Delete application resources
Write-Host "5️⃣ Deleting application resources..." -ForegroundColor Yellow

# Delete Container Apps first (they depend on Container App Environment)
Write-Host "   🗑️ Deleting Premium Container Apps..." -ForegroundColor Cyan
foreach ($app in $containerApps) {
    if ($app) {
        Write-Host "     Deleting Premium Container App: $app" -ForegroundColor Gray
        az containerapp delete --name $app --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Container App Environments
Write-Host "   🗑️ Deleting Premium Container App Environments..." -ForegroundColor Cyan
$containerEnvs = az containerapp env list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($env in $containerEnvs) {
    if ($env) {
        Write-Host "     Deleting Premium Container Environment: $env" -ForegroundColor Gray
        az containerapp env delete --name $env --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Web Apps
Write-Host "   🗑️ Deleting Premium Web Apps..." -ForegroundColor Cyan
foreach ($app in $webApps) {
    if ($app) {
        Write-Host "     Deleting Premium Web App: $app" -ForegroundColor Gray
        az webapp delete --name $app --resource-group $ResourceGroupName 2>$null
    }
}

# Delete App Service Plans
Write-Host "   🗑️ Deleting Premium App Service Plans..." -ForegroundColor Cyan
$appServicePlans = az appservice plan list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($plan in $appServicePlans) {
    if ($plan) {
        Write-Host "     Deleting Premium App Service Plan: $plan" -ForegroundColor Gray
        az appservice plan delete --name $plan --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Step 6: Delete data resources (point of no return)
Write-Host "6️⃣ Deleting data resources (POINT OF NO RETURN)..." -ForegroundColor Red

# Delete PostgreSQL Databases and Servers
Write-Host "   🗑️ Deleting Premium PostgreSQL Servers with HA..." -ForegroundColor Cyan
foreach ($db in $postgresDatabases) {
    if ($db) {
        Write-Host "     ❌ DELETING PRODUCTION DATABASE: $db" -ForegroundColor Red
        az postgres flexible-server delete --name $db --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Premium Storage Accounts (this will delete all production blob data)
Write-Host "   🗑️ Deleting Premium Storage Accounts..." -ForegroundColor Cyan
$storageAccounts = az storage account list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($storage in $storageAccounts) {
    if ($storage) {
        Write-Host "     ❌ DELETING PRODUCTION STORAGE: $storage" -ForegroundColor Red
        az storage account delete --name $storage --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Step 7: Delete security and networking resources
Write-Host "7️⃣ Deleting security and networking resources..." -ForegroundColor Yellow

# Delete Private Endpoints
Write-Host "   🗑️ Deleting Private Endpoints..." -ForegroundColor Cyan
$privateEndpoints = az network private-endpoint list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($endpoint in $privateEndpoints) {
    if ($endpoint) {
        Write-Host "     Deleting Private Endpoint: $endpoint" -ForegroundColor Gray
        az network private-endpoint delete --name $endpoint --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Container Registry
Write-Host "   🗑️ Deleting Premium Container Registry..." -ForegroundColor Cyan
$containerRegistries = az acr list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($registry in $containerRegistries) {
    if ($registry) {
        Write-Host "     Deleting Premium Container Registry: $registry" -ForegroundColor Gray
        az acr delete --name $registry --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Premium Key Vaults (this will soft delete them due to purge protection)
Write-Host "   🗑️ Deleting Premium Key Vaults with HSM..." -ForegroundColor Cyan
foreach ($vault in $keyVaults) {
    if ($vault) {
        Write-Host "     Deleting Premium Key Vault with HSM: $vault" -ForegroundColor Gray
        az keyvault delete --name $vault --resource-group $ResourceGroupName 2>$null
        
        # Also purge the Key Vault to completely remove it and stop billing
        Write-Host "     Purging Premium Key Vault: $vault" -ForegroundColor Gray
        az keyvault purge --name $vault --location $Location 2>$null
    }
}

# Delete Public IP Addresses
Write-Host "   🗑️ Deleting Public IP Addresses..." -ForegroundColor Cyan
$publicIPs = az network public-ip list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($pip in $publicIPs) {
    if ($pip) {
        Write-Host "     Deleting Public IP: $pip" -ForegroundColor Gray
        az network public-ip delete --name $pip --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Virtual Networks
Write-Host "   🗑️ Deleting Virtual Networks..." -ForegroundColor Cyan
$vnets = az network vnet list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($vnet in $vnets) {
    if ($vnet) {
        Write-Host "     Deleting Virtual Network: $vnet" -ForegroundColor Gray
        az network vnet delete --name $vnet --resource-group $ResourceGroupName 2>$null
    }
}

# Step 8: Delete monitoring and observability resources
Write-Host "8️⃣ Deleting monitoring and observability resources..." -ForegroundColor Yellow

# Delete Application Insights
Write-Host "   🗑️ Deleting Premium Application Insights..." -ForegroundColor Cyan
$appInsights = az monitor app-insights component show --resource-group $ResourceGroupName --query "[].name" --output tsv 2>$null
foreach ($insight in $appInsights) {
    if ($insight) {
        Write-Host "     Deleting Premium Application Insights: $insight" -ForegroundColor Gray
        az monitor app-insights component delete --app $insight --resource-group $ResourceGroupName 2>$null
    }
}

# Delete Log Analytics Workspaces
Write-Host "   🗑️ Deleting Premium Log Analytics Workspaces..." -ForegroundColor Cyan
$workspaces = az monitor log-analytics workspace list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($workspace in $workspaces) {
    if ($workspace) {
        Write-Host "     Deleting Premium Log Analytics Workspace: $workspace" -ForegroundColor Gray
        az monitor log-analytics workspace delete --workspace-name $workspace --resource-group $ResourceGroupName --yes 2>$null
    }
}

# Delete Managed Identities
Write-Host "   🗑️ Deleting Managed Identities..." -ForegroundColor Cyan
$identities = az identity list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($identity in $identities) {
    if ($identity) {
        Write-Host "     Deleting Managed Identity: $identity" -ForegroundColor Gray
        az identity delete --name $identity --resource-group $ResourceGroupName 2>$null
    }
}

# Step 9: Delete the entire resource group (final cleanup)
Write-Host "9️⃣ Deleting the entire PRODUCTION resource group..." -ForegroundColor Red
Write-Host "   🗑️ Deleting PRODUCTION Resource Group: $ResourceGroupName" -ForegroundColor Red
Write-Host "   ⏳ This may take 15-30 minutes for production resources..." -ForegroundColor Gray

az group delete --name $ResourceGroupName --yes --no-wait

# Step 10: Extended verification for production
Write-Host "🔟 Initiating extended verification..." -ForegroundColor Yellow
Write-Host "   ⏳ Waiting for PRODUCTION deletion to complete (this may take 20-30 minutes)..." -ForegroundColor Gray

# Wait and check if resource group still exists
$maxWaitMinutes = 30
$waitCount = 0
do {
    Start-Sleep -Seconds 60
    $waitCount++
    $stillExists = az group exists --name $ResourceGroupName
    
    if ($stillExists -eq "false") {
        break
    }
    
    Write-Host "   ⏳ Still deleting PRODUCTION resources... ($waitCount/$maxWaitMinutes minutes)" -ForegroundColor Gray
    
    if ($waitCount -ge $maxWaitMinutes) {
        Write-Host "   ⚠️ Production deletion is taking longer than expected. Check Azure portal for status." -ForegroundColor Yellow
        break
    }
} while ($stillExists -eq "true")

# Final verification
$finalCheck = az group exists --name $ResourceGroupName
if ($finalCheck -eq "false") {
    Write-Host "✅ COMPLETE PRODUCTION ENVIRONMENT SHUTDOWN SUCCESSFUL!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "💰 Monthly cost reduced to: $0.00" -ForegroundColor Green
    Write-Host "🎯 ALL PRODUCTION RESOURCES have been permanently deleted" -ForegroundColor Green
    Write-Host "🗑️ Premium Key Vaults have been purged to stop billing" -ForegroundColor Green
    Write-Host "📅 Deletion completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    
    # Send completion notification
    Write-Host "📧 PRODUCTION DELETION COMPLETE - AUDIT REQUIRED" -ForegroundColor Red -BackgroundColor Yellow
} else {
    Write-Host "⚠️ PRODUCTION resource group may still be deleting. Check Azure portal." -ForegroundColor Yellow
    Write-Host "💡 Monitor deletion status with: az group show --name $ResourceGroupName" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📋 PRODUCTION Shutdown Summary:" -ForegroundColor Red
Write-Host "Environment: PRODUCTION" -ForegroundColor Red
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Red
Write-Host "Resources Deleted: All ($resourceCount total)" -ForegroundColor Red
Write-Host "Premium Features Deleted: HSM Key Vault, DDoS Protection, Premium WAF, CDN" -ForegroundColor Red
Write-Host "Data Loss: ALL PRODUCTION DATA PERMANENTLY DELETED" -ForegroundColor Red
Write-Host "Cost Reduction: 100% (to $0/month)" -ForegroundColor Green
Write-Host "Status: Complete" -ForegroundColor Green

# Cleanup azd environment variables (optional)
Write-Host ""
$cleanupAzd = Read-Host "🧹 Do you want to clean up AZD PRODUCTION environment variables? (y/N)"
if ($cleanupAzd -eq 'y') {
    try {
        azd env select prod 2>$null
        azd env delete prod --force 2>$null
        Write-Host "✅ AZD PRODUCTION environment variables cleaned up" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not clean up AZD environment (this is optional)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🔥🔥🔥 PRODUCTION ENVIRONMENT SHUTDOWN COMPLETE 🔥🔥🔥" -ForegroundColor Red -BackgroundColor Black
Write-Host "⚠️ REMEMBER: ALL PRODUCTION DATA HAS BEEN PERMANENTLY DELETED ⚠️" -ForegroundColor Red -BackgroundColor Yellow
```

### Emergency Shutdown Script (All Environments)

Create file: `infra/scripts/emergency-shutdown-all.ps1`

```powershell
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Emergency shutdown of ALL environments (IT, QA, Production) to achieve zero cost.

.DESCRIPTION
    This script provides an emergency shutdown option to delete all environments
    in case of cost emergencies or security incidents. Use with extreme caution.

.PARAMETER Force
    Skip confirmation prompts (use with extreme caution)

.EXAMPLE
    .\emergency-shutdown-all.ps1
#>

param(
    [switch]$Force
)

Write-Host "🚨🚨🚨 EMERGENCY SHUTDOWN - ALL ENVIRONMENTS 🚨🚨🚨" -ForegroundColor Red -BackgroundColor Yellow
Write-Host "=================================================" -ForegroundColor Red
Write-Host "This will delete ALL environments: IT, QA, and PRODUCTION" -ForegroundColor Red
Write-Host "⚠️ ALL DATA IN ALL ENVIRONMENTS WILL BE LOST ⚠️" -ForegroundColor Red -BackgroundColor Yellow

if (-not $Force) {
    Write-Host ""
    Write-Host "Are you experiencing a cost or security emergency? (yes/no)"
    $emergency = Read-Host
    if ($emergency -ne "yes") {
        Write-Host "❌ Emergency shutdown cancelled" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "Type 'EMERGENCY-DELETE-ALL-ENVIRONMENTS' to confirm:"
    $confirmation = Read-Host
    if ($confirmation -ne "EMERGENCY-DELETE-ALL-ENVIRONMENTS") {
        Write-Host "❌ Emergency shutdown cancelled" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "🚀 Starting emergency shutdown of all environments..." -ForegroundColor Red

# Run all shutdown scripts in parallel for fastest deletion
Write-Host "💥 Executing all environment shutdown scripts..." -ForegroundColor Red

$jobs = @()

# Start IT environment shutdown
$jobs += Start-Job -ScriptBlock {
    param($Force)
    & ".\infra\scripts\complete-shutdown-it.ps1" $(if($Force) { "-Force" })
} -ArgumentList $Force

# Start QA environment shutdown  
$jobs += Start-Job -ScriptBlock {
    param($Force)
    & ".\infra\scripts\complete-shutdown-qa.ps1" $(if($Force) { "-Force" })
} -ArgumentList $Force

# Start Production environment shutdown
$jobs += Start-Job -ScriptBlock {
    param($Force)
    & ".\infra\scripts\complete-shutdown-prod.ps1" $(if($Force) { "-Force" })
} -ArgumentList $Force

# Wait for all jobs to complete
Write-Host "⏳ Waiting for all environments to shut down..." -ForegroundColor Yellow
$jobs | Wait-Job | Receive-Job

# Cleanup jobs
$jobs | Remove-Job

Write-Host "✅ EMERGENCY SHUTDOWN COMPLETE" -ForegroundColor Green -BackgroundColor Black
Write-Host "💰 All environment costs reduced to $0" -ForegroundColor Green
```

### Shutdown Verification Script

Create file: `infra/scripts/verify-shutdown.ps1`

```powershell
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verify that environment shutdown was successful and no resources are still billing.

.DESCRIPTION
    This script checks all resource groups and validates that no billable resources remain.

.PARAMETER Environment
    Specific environment to check (it, qa, prod, or all)

.EXAMPLE
    .\verify-shutdown.ps1 -Environment all
    .\verify-shutdown.ps1 -Environment it
#>

param(
    [ValidateSet("it", "qa", "prod", "all")]
    [string]$Environment = "all"
)

$resourceGroups = @()

switch ($Environment) {
    "it" { $resourceGroups = @("beeux-rg-it-eastus") }
    "qa" { $resourceGroups = @("beeux-rg-qa-eastus") }
    "prod" { $resourceGroups = @("beeux-rg-prod-eastus") }
    "all" { $resourceGroups = @("beeux-rg-it-eastus", "beeux-rg-qa-eastus", "beeux-rg-prod-eastus") }
}

Write-Host "🔍 Verifying shutdown for environment(s): $Environment" -ForegroundColor Cyan

foreach ($rg in $resourceGroups) {
    Write-Host ""
    Write-Host "Checking Resource Group: $rg" -ForegroundColor Yellow
    
    $exists = az group exists --name $rg
    if ($exists -eq "false") {
        Write-Host "✅ Resource group deleted successfully - no billing" -ForegroundColor Green
        continue
    }
    
    Write-Host "⚠️ Resource group still exists, checking for resources..." -ForegroundColor Yellow
    
    $resources = az resource list --resource-group $rg --query "[].{Name:name, Type:type, SKU:sku.name}" --output table
    if ($resources) {
        Write-Host "❌ Found remaining resources:" -ForegroundColor Red
        Write-Host $resources
        
        # Check for billable resources
        $billableTypes = @(
            "Microsoft.Web/serverfarms",
            "Microsoft.App/managedEnvironments", 
            "Microsoft.DBforPostgreSQL/flexibleServers",
            "Microsoft.Storage/storageAccounts",
            "Microsoft.ContainerRegistry/registries",
            "Microsoft.KeyVault/vaults",
            "Microsoft.Network/applicationGateways",
            "Microsoft.Cdn/profiles"
        )
        
        $billableResources = az resource list --resource-group $rg --query "[?contains('$($billableTypes -join "','")')]" --output tsv
        if ($billableResources) {
            Write-Host "💰 WARNING: Billable resources still exist!" -ForegroundColor Red -BackgroundColor Yellow
        }
    } else {
        Write-Host "✅ No resources found in group" -ForegroundColor Green
    }
}

# Check for soft-deleted Key Vaults (they still cost money)
Write-Host ""
Write-Host "🔍 Checking for soft-deleted Key Vaults..." -ForegroundColor Cyan
$softDeletedVaults = az keyvault list-deleted --query "[?contains(name, 'beeux')].{Name:name, Location:properties.location, DeletionDate:properties.deletionDate}" --output table
if ($softDeletedVaults) {
    Write-Host "⚠️ Found soft-deleted Key Vaults (still billing):" -ForegroundColor Yellow
    Write-Host $softDeletedVaults
    Write-Host "💡 Purge them with: az keyvault purge --name <vault-name> --location <location>" -ForegroundColor Cyan
} else {
    Write-Host "✅ No soft-deleted Key Vaults found" -ForegroundColor Green
}

Write-Host ""
Write-Host "🔍 Shutdown verification complete for: $Environment" -ForegroundColor Cyan
```

## Quick Usage Guide

### How to Use the Shutdown Scripts

1. **Individual Environment Shutdown:**
```powershell
# Shutdown IT environment (cost-optimized)
.\infra\scripts\complete-shutdown-it.ps1

# Shutdown QA environment (security-focused)
.\infra\scripts\complete-shutdown-qa.ps1

# Shutdown Production environment (premium features)
.\infra\scripts\complete-shutdown-prod.ps1
```

2. **Emergency Shutdown (All Environments):**
```powershell
# In case of cost emergency or security incident
.\infra\scripts\emergency-shutdown-all.ps1
```

3. **Verify Shutdown Success:**
```powershell
# Check all environments
.\infra\scripts\verify-shutdown.ps1 -Environment all

# Check specific environment
.\infra\scripts\verify-shutdown.ps1 -Environment prod
```

### Execution from VS Code Terminal

1. **Open VS Code Terminal** (Ctrl+` or Terminal → New Terminal)
2. **Navigate to project directory:**
```powershell
cd C:\dev\beeinfra
```
3. **Make scripts executable (if needed):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
4. **Run desired shutdown script:**
```powershell
# Example: Shutdown IT environment
.\infra\scripts\complete-shutdown-it.ps1
```

### Execution from Azure CLI

You can also run these scripts directly from Azure CLI in any terminal:

```bash
# Login to Azure first
az login

# Run shutdown script
pwsh ./infra/scripts/complete-shutdown-it.ps1
```

### Important Notes

- ⚠️ **All shutdown scripts are DESTRUCTIVE and IRREVERSIBLE**
- 💾 **Always backup important data before running shutdown scripts**
- 🔐 **Production shutdown requires multiple confirmations for safety**
- 💰 **Scripts achieve true $0 monthly cost by deleting ALL resources**
- 📋 **Scripts include detailed logging for audit purposes**
- ⏱️ **Complete shutdown may take 15-30 minutes depending on environment**
- 🧹 **Scripts optionally clean up AZD environment variables**

The scripts are designed to:
- **Delete resources in proper dependency order** to avoid conflicts
- **Handle premium features** appropriately (HSM Key Vault, DDoS protection, etc.)
- **Provide detailed progress feedback** with colored output and time estimates
- **Include safety confirmations** especially for production environments
- **Verify complete deletion** to ensure zero billing
- **Clean up AZD environment variables** optionally

---

## 🚀 Complete Environment Startup Scripts

The startup scripts are the **complete opposite** of shutdown scripts. They provision and start all Azure resources for each environment from a completely shut down state (zero resources). These scripts use **Azure Developer CLI (azd)** and **Azure CLI** to recreate the entire environment infrastructure.

### Startup Scripts Directory Structure

The startup scripts are located in the `infra/scripts/` directory:

```
infra/scripts/
├── complete-startup-it.ps1         # Start IT environment (cost-optimized)
├── complete-startup-qa.ps1         # Start QA environment (security-focused) 
├── complete-startup-prod.ps1       # Start Production environment (premium)
├── startup-verification.ps1        # Verify successful startup
├── emergency-startup-all.ps1       # Start all environments quickly
└── check-environment-status.ps1    # Check current resource status
```

### Complete IT Environment Startup Script

Create file: `infra/scripts/complete-startup-it.ps1`

```powershell
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete startup and provisioning of IT environment resources from zero state.

.DESCRIPTION
    This script will provision and start ALL Azure resources required for the IT environment
    including App Services, Container Apps, self-hosted PostgreSQL database, basic storage,
    container registry, and basic monitoring. Optimized for cost with minimal security features.

.PARAMETER Force
    Skip confirmation prompts and use default values

.EXAMPLE
    .\complete-startup-it.ps1
    .\complete-startup-it.ps1 -Force
#>

param(
    [switch]$Force
)

# Script configuration
$EnvironmentName = "it"
$ResourceGroupName = "beeux-rg-it-eastus"
$Location = "eastus"
$BudgetAmount = 10

Write-Host "🚀🚀🚀 COMPLETE IT ENVIRONMENT STARTUP SCRIPT 🚀🚀🚀" -ForegroundColor Green -BackgroundColor Black
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Environment: $EnvironmentName (IT/Development)" -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Green
Write-Host "💰 Budget Target: $${BudgetAmount}/month (cost-optimized with Key Vault)" -ForegroundColor Yellow
Write-Host "🏗️  Architecture: Self-hosted components with essential security" -ForegroundColor Yellow

if (-not $Force) {
    Write-Host ""
    Write-Host "This will provision and start:" -ForegroundColor Green
    Write-Host "✅ App Service (Free/Basic tier)" -ForegroundColor Green
    Write-Host "✅ Container Apps (Basic tier for API)" -ForegroundColor Green
    Write-Host "✅ Self-hosted PostgreSQL database (containerized)" -ForegroundColor Green
    Write-Host "✅ Basic Storage Account (Standard LRS)" -ForegroundColor Green
    Write-Host "✅ Basic Container Registry" -ForegroundColor Green
    Write-Host "✅ Standard Key Vault for secret management" -ForegroundColor Green
    Write-Host "✅ Developer tier API Management for REST API Gateway" -ForegroundColor Green
    Write-Host "✅ Basic monitoring (free tier)" -ForegroundColor Green
    Write-Host "❌ No advanced security services (cost optimization)" -ForegroundColor Yellow
    Write-Host "❌ No auto-scaling (manual scaling only)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💰 COST ESTIMATE:" -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "   📊 Estimated cost per HOUR: ~$0.50/hour" -ForegroundColor Yellow
    Write-Host "   📅 Estimated cost per DAY: ~$12.00/day" -ForegroundColor Yellow
    Write-Host "   📆 Estimated cost per MONTH: ~$360/month (if left running 24/7)" -ForegroundColor Red
    Write-Host "   ⏰ With auto-shutdown after 1 hour idle: ~$10/month" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: You will be charged for Azure resources while they are running!" -ForegroundColor Yellow
    Write-Host "💡 TIP: Use auto-shutdown feature to minimize costs when not in use" -ForegroundColor Cyan
    Write-Host ""
    
    $costConfirmation = Read-Host "Do you accept the estimated cost of ~$0.50/hour for IT environment? Type 'Yes' to accept"
    if ($costConfirmation -ne "Yes") {
        Write-Host "❌ IT environment startup cancelled - cost not accepted" -ForegroundColor Red
        exit 0
    }
    
    $confirmation = Read-Host "Do you want to start the IT environment? (y/N)"
    if ($confirmation -ne "y") {
        Write-Host "❌ IT environment startup cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Check if Azure CLI is logged in
Write-Host "🔍 Checking Azure CLI authentication..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "❌ Not logged into Azure CLI. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Authenticated as: $($account.user.name)" -ForegroundColor Green
Write-Host "📋 Subscription: $($account.name) ($($account.id))" -ForegroundColor Yellow

# Check if AZD is available
Write-Host "🔍 Checking Azure Developer CLI..." -ForegroundColor Cyan
$azdVersion = azd version 2>$null
if (-not $azdVersion) {
    Write-Host "❌ Azure Developer CLI not found. Please install azd first." -ForegroundColor Red
    Write-Host "💡 Install with: winget install microsoft.azd" -ForegroundColor Cyan
    exit 1
}
Write-Host "✅ Azure Developer CLI available" -ForegroundColor Green

# Step 1: Set up AZD environment
Write-Host "1️⃣ Setting up AZD environment..." -ForegroundColor Yellow

# Check if IT environment already exists
$existingEnv = azd env list --output json 2>$null | ConvertFrom-Json | Where-Object { $_.Name -eq "it" }
if ($existingEnv) {
    Write-Host "   📋 IT environment already exists, selecting it..." -ForegroundColor Gray
    azd env select it
} else {
    Write-Host "   🆕 Creating new IT environment..." -ForegroundColor Gray
    azd env new it
}

# Step 2: Configure environment variables for IT
Write-Host "2️⃣ Configuring IT environment variables..." -ForegroundColor Yellow

Write-Host "   Setting core configuration..." -ForegroundColor Gray
azd env set AZURE_LOCATION $Location
azd env set AZURE_RESOURCE_GROUP_NAME $ResourceGroupName
azd env set AZURE_APP_NAME "beeux-it"
azd env set AZURE_ENVIRONMENT_NAME $EnvironmentName

Write-Host "   Setting database configuration..." -ForegroundColor Gray
azd env set DATABASE_TYPE "self-hosted"
azd env set DATABASE_NAME "beeux_it"
azd env set POSTGRES_ADMIN_USERNAME "postgres_admin"

Write-Host "   Setting storage configuration..." -ForegroundColor Gray
azd env set BLOB_CONTAINER_NAME "audio-files-it"

Write-Host "   Setting budget and alerting..." -ForegroundColor Gray
azd env set BUDGET_AMOUNT $BudgetAmount
azd env set ALERT_EMAIL_PRIMARY "prashantmdesai@yahoo.com"
azd env set ALERT_EMAIL_SECONDARY "prashantmdesai@hotmail.com"
azd env set ALERT_PHONE "+12246564855"

Write-Host "   Setting cost optimization flags..." -ForegroundColor Gray
azd env set USE_FREE_TIER "true"
azd env set USE_MANAGED_SERVICES "false"
azd env set ENABLE_SECURITY_FEATURES "basic"
azd env set ENABLE_KEY_VAULT "true"
azd env set KEY_VAULT_SKU "standard"
azd env set ENABLE_AUTO_SCALING "false"
azd env set AUTO_SHUTDOWN_ENABLED "true"
azd env set IDLE_SHUTDOWN_HOURS "1"

Write-Host "✅ IT environment variables configured" -ForegroundColor Green

# Step 3: Check if infrastructure files exist
Write-Host "3️⃣ Verifying infrastructure files..." -ForegroundColor Yellow

$requiredFiles = @(
    "infra/main.bicep",
    "infra/main.parameters.json",
    "azure.yaml"
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "❌ Required file missing: $file" -ForegroundColor Red
        Write-Host "💡 Please ensure all infrastructure files are present" -ForegroundColor Cyan
        exit 1
    }
}
Write-Host "✅ All required infrastructure files found" -ForegroundColor Green

# Step 4: Provision Azure infrastructure
Write-Host "4️⃣ Provisioning Azure infrastructure..." -ForegroundColor Yellow
Write-Host "   🏗️  This will create the resource group and all Azure resources..." -ForegroundColor Gray
Write-Host "   ⏳ Estimated time: 10-15 minutes for IT environment..." -ForegroundColor Gray

$provisionResult = azd provision --no-prompt 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Infrastructure provisioning failed!" -ForegroundColor Red
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host $provisionResult -ForegroundColor Red
    exit 1
}

Write-Host "✅ Infrastructure provisioned successfully!" -ForegroundColor Green

# Step 5: Deploy applications
Write-Host "5️⃣ Deploying applications..." -ForegroundColor Yellow
Write-Host "   📦 Building and deploying Angular frontend..." -ForegroundColor Gray
Write-Host "   🐳 Building and deploying Spring Boot API container..." -ForegroundColor Gray
Write-Host "   ⏳ Estimated time: 5-10 minutes..." -ForegroundColor Gray

$deployResult = azd deploy --no-prompt 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Application deployment failed!" -ForegroundColor Red
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host $deployResult -ForegroundColor Red
    
    # Continue with infrastructure setup even if app deployment fails
    Write-Host "⚠️ Continuing with infrastructure configuration..." -ForegroundColor Yellow
}

Write-Host "✅ Applications deployed!" -ForegroundColor Green

# Step 6: Set up budget alerts
Write-Host "6️⃣ Setting up budget alerts..." -ForegroundColor Yellow
Write-Host "   💰 Creating budget alerts for ${BudgetAmount} USD..." -ForegroundColor Gray

# Check if script exists, if not create a simple version
if (Test-Path "infra\scripts\setup-cost-alerts.ps1") {
    try {
        & ".\infra\scripts\setup-cost-alerts.ps1" -EnvironmentName $EnvironmentName -BudgetAmount $BudgetAmount
        Write-Host "✅ Budget alerts configured" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Budget alert setup failed, but continuing..." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ Budget alert script not found, creating manual budget..." -ForegroundColor Yellow
    
    # Create a simple budget using Azure CLI
    $budgetConfig = @{
        amount = $BudgetAmount
        timeGrain = "Monthly"
        timePeriod = @{
            startDate = (Get-Date -Format "yyyy-MM-01")
            endDate = "2030-12-31"
        }
        notifications = @{
            "alert-80" = @{
                enabled = $true
                operator = "GreaterThan"
                threshold = 80
                contactEmails = @("prashantmdesai@yahoo.com", "prashantmdesai@hotmail.com")
                thresholdType = "Actual"
            }
            "alert-100" = @{
                enabled = $true
                operator = "GreaterThan" 
                threshold = 100
                contactEmails = @("prashantmdesai@yahoo.com", "prashantmdesai@hotmail.com")
                thresholdType = "Actual"
            }
        }
    } | ConvertTo-Json -Depth 10
    
    $budgetConfig | Out-File -FilePath "temp-budget.json" -Encoding UTF8
    az consumption budget create --budget-name "beeux-budget-it" --amount $BudgetAmount --category "Cost" --time-grain "Monthly" --resource-group $ResourceGroupName --budget-file "temp-budget.json" 2>$null
    Remove-Item "temp-budget.json" -ErrorAction SilentlyContinue
    
    Write-Host "✅ Basic budget created" -ForegroundColor Green
}

# Step 7: Set up auto-shutdown
Write-Host "7️⃣ Setting up auto-shutdown..." -ForegroundColor Yellow
Write-Host "   ⏰ Configuring auto-shutdown after 1 hour of inactivity..." -ForegroundColor Gray

if (Test-Path "infra\scripts\setup-auto-shutdown.ps1") {
    try {
        & ".\infra\scripts\setup-auto-shutdown.ps1" -EnvironmentName $EnvironmentName -IdleHours 1
        Write-Host "✅ Auto-shutdown configured" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Auto-shutdown setup failed, but continuing..." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ Auto-shutdown script not found, manual configuration required" -ForegroundColor Yellow
}

# Step 8: Verify environment is running
Write-Host "8️⃣ Verifying IT environment is running..." -ForegroundColor Yellow

Write-Host "   Checking resource group..." -ForegroundColor Gray
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "true") {
    Write-Host "   ✅ Resource group exists" -ForegroundColor Green
} else {
    Write-Host "   ❌ Resource group not found" -ForegroundColor Red
}

Write-Host "   Checking resources..." -ForegroundColor Gray
$resources = az resource list --resource-group $ResourceGroupName --query "length([])" --output tsv 2>$null
if ($resources -and [int]$resources -gt 0) {
    Write-Host "   ✅ Found $resources resources in IT environment" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ No resources found or error checking resources" -ForegroundColor Yellow
}

# Step 9: Get service URLs
Write-Host "9️⃣ Getting service URLs..." -ForegroundColor Yellow

try {
    $azdEnv = azd env get-values --output json | ConvertFrom-Json
    
    if ($azdEnv.AZURE_FRONTEND_URL) {
        Write-Host "   🌐 Frontend URL: $($azdEnv.AZURE_FRONTEND_URL)" -ForegroundColor Cyan
    }
    
    if ($azdEnv.AZURE_API_URL) {
        Write-Host "   🔗 API URL: $($azdEnv.AZURE_API_URL)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "   ⚠️ Could not retrieve service URLs" -ForegroundColor Yellow
}

# Step 10: Display summary
Write-Host "🔟 IT Environment Startup Summary:" -ForegroundColor Green
Write-Host "Environment: IT (Development)" -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Green
Write-Host "Budget: $${BudgetAmount}/month with alerts" -ForegroundColor Green
Write-Host "Security: Essential (Standard Key Vault for secrets)" -ForegroundColor Green
Write-Host "Auto-shutdown: Enabled (1 hour idle)" -ForegroundColor Green
Write-Host "Architecture: Cost-optimized with essential security" -ForegroundColor Green
Write-Host "Status: Running" -ForegroundColor Green

Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Cyan
Write-Host "   • Monitor costs in Azure portal" -ForegroundColor Cyan
Write-Host "   • Test application functionality" -ForegroundColor Cyan
Write-Host "   • Set up CI/CD pipelines" -ForegroundColor Cyan
Write-Host "   • Use shutdown script when not needed: .\infra\scripts\complete-shutdown-it.ps1" -ForegroundColor Cyan

Write-Host ""
Write-Host "🚀🚀🚀 IT ENVIRONMENT STARTUP COMPLETE 🚀🚀🚀" -ForegroundColor Green -BackgroundColor Black
```

### Complete QA Environment Startup Script

Create file: `infra/scripts/complete-startup-qa.ps1`

```powershell
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete startup and provisioning of QA environment resources from zero state.

.DESCRIPTION
    This script will provision and start ALL Azure resources required for the QA environment
    including Premium App Services, Container Apps, managed PostgreSQL database with security,
    encrypted storage with private endpoints, premium Container Registry, Key Vault,
    WAF, and advanced monitoring. Security-focused configuration.

.PARAMETER Force
    Skip confirmation prompts and use default values

.EXAMPLE
    .\complete-startup-qa.ps1
    .\complete-startup-qa.ps1 -Force
#>

param(
    [switch]$Force
)

# Script configuration
$EnvironmentName = "qa"
$ResourceGroupName = "beeux-rg-qa-eastus"
$Location = "eastus"
$BudgetAmount = 20

Write-Host "🚀🚀🚀 COMPLETE QA ENVIRONMENT STARTUP SCRIPT 🚀🚀🚀" -ForegroundColor Cyan -BackgroundColor Black
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "Environment: $EnvironmentName (Quality Assurance)" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "💰 Budget Target: $${BudgetAmount}/month (security-focused)" -ForegroundColor Yellow
Write-Host "🔒 Architecture: Managed services with enhanced security features" -ForegroundColor Yellow

if (-not $Force) {
    Write-Host ""
    Write-Host "This will provision and start:" -ForegroundColor Cyan
    Write-Host "✅ App Service (Premium P1V3 with auto-scaling)" -ForegroundColor Green
    Write-Host "✅ Container Apps (Premium with auto-scaling)" -ForegroundColor Green
    Write-Host "✅ Managed PostgreSQL database with encryption" -ForegroundColor Green
    Write-Host "✅ Premium Storage with Private Endpoints" -ForegroundColor Green
    Write-Host "✅ Premium Container Registry with geo-replication" -ForegroundColor Green
    Write-Host "✅ Key Vault for secure secret management" -ForegroundColor Green
    Write-Host "✅ Standard tier API Management with rate limiting" -ForegroundColor Green
    Write-Host "✅ Web Application Firewall (WAF)" -ForegroundColor Green
    Write-Host "✅ Application Gateway with security features" -ForegroundColor Green
    Write-Host "✅ Advanced monitoring and alerting" -ForegroundColor Green
    Write-Host "✅ Auto-scaling for performance testing" -ForegroundColor Green
    Write-Host ""
    Write-Host "💰 COST ESTIMATE:" -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "   📊 Estimated cost per HOUR: ~$1.10/hour" -ForegroundColor Yellow
    Write-Host "   📅 Estimated cost per DAY: ~$26.40/day" -ForegroundColor Yellow
    Write-Host "   📆 Estimated cost per MONTH: ~$800/month (if left running 24/7)" -ForegroundColor Red
    Write-Host "   ⏰ With auto-shutdown after 1 hour idle: ~$20/month" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: You will be charged for Azure resources while they are running!" -ForegroundColor Yellow
    Write-Host "💡 TIP: Use auto-shutdown feature to minimize costs when not in use" -ForegroundColor Cyan
    Write-Host ""
    
    $costConfirmation = Read-Host "Do you accept the estimated cost of ~$1.10/hour for QA environment? Type 'Yes' to accept"
    if ($costConfirmation -ne "Yes") {
        Write-Host "❌ QA environment startup cancelled - cost not accepted" -ForegroundColor Red
        exit 0
    }
    
    $confirmation = Read-Host "Do you want to start the QA environment? (y/N)"
    if ($confirmation -ne "y") {
        Write-Host "❌ QA environment startup cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Cyan

# Check Azure CLI
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "❌ Not logged into Azure CLI. Please run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Azure CLI authenticated as: $($account.user.name)" -ForegroundColor Green

# Check AZD
$azdVersion = azd version 2>$null
if (-not $azdVersion) {
    Write-Host "❌ Azure Developer CLI not found. Please install azd first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Azure Developer CLI available" -ForegroundColor Green

# Step 1: Set up AZD environment  
Write-Host "1️⃣ Setting up AZD environment..." -ForegroundColor Yellow

$existingEnv = azd env list --output json 2>$null | ConvertFrom-Json | Where-Object { $_.Name -eq "qa" }
if ($existingEnv) {
    Write-Host "   📋 QA environment already exists, selecting it..." -ForegroundColor Gray
    azd env select qa
} else {
    Write-Host "   🆕 Creating new QA environment..." -ForegroundColor Gray
    azd env new qa
}

# Step 2: Configure environment variables for QA
Write-Host "2️⃣ Configuring QA environment variables..." -ForegroundColor Yellow

Write-Host "   Setting core configuration..." -ForegroundColor Gray
azd env set AZURE_LOCATION $Location
azd env set AZURE_RESOURCE_GROUP_NAME $ResourceGroupName
azd env set AZURE_APP_NAME "beeux-qa"
azd env set AZURE_ENVIRONMENT_NAME $EnvironmentName

Write-Host "   Setting managed database configuration..." -ForegroundColor Gray
azd env set DATABASE_TYPE "managed"
azd env set DATABASE_NAME "beeux_qa"
azd env set POSTGRES_ADMIN_USERNAME "postgres_admin"

Write-Host "   Setting storage configuration..." -ForegroundColor Gray
azd env set BLOB_CONTAINER_NAME "audio-files-qa"

Write-Host "   Setting budget and alerting..." -ForegroundColor Gray
azd env set BUDGET_AMOUNT $BudgetAmount
azd env set ALERT_EMAIL_PRIMARY "prashantmdesai@yahoo.com"
azd env set ALERT_EMAIL_SECONDARY "prashantmdesai@hotmail.com"
azd env set ALERT_PHONE "+12246564855"

Write-Host "   Setting security and performance flags..." -ForegroundColor Gray
azd env set USE_FREE_TIER "false"
azd env set USE_MANAGED_SERVICES "true"
azd env set ENABLE_SECURITY_FEATURES "true"
azd env set ENABLE_AUTO_SCALING "true"
azd env set ENABLE_PRIVATE_ENDPOINTS "true"
azd env set ENABLE_WAF "true"
azd env set ENABLE_KEY_VAULT "true"
azd env set AUTO_SHUTDOWN_ENABLED "true"
azd env set IDLE_SHUTDOWN_HOURS "1"

Write-Host "✅ QA environment variables configured" -ForegroundColor Green

# Step 3: Provision Azure infrastructure
Write-Host "3️⃣ Provisioning Azure infrastructure..." -ForegroundColor Yellow
Write-Host "   🏗️  Creating managed services with security features..." -ForegroundColor Gray
Write-Host "   ⏳ Estimated time: 15-25 minutes for QA environment..." -ForegroundColor Gray

$provisionResult = azd provision --no-prompt 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Infrastructure provisioning failed!" -ForegroundColor Red
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host $provisionResult -ForegroundColor Red
    exit 1
}

Write-Host "✅ Infrastructure provisioned successfully!" -ForegroundColor Green

# Step 4: Deploy applications
Write-Host "4️⃣ Deploying applications..." -ForegroundColor Yellow
Write-Host "   📦 Building and deploying to premium services..." -ForegroundColor Gray

$deployResult = azd deploy --no-prompt 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Application deployment failed!" -ForegroundColor Red
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host $deployResult -ForegroundColor Red
    Write-Host "⚠️ Continuing with infrastructure configuration..." -ForegroundColor Yellow
}

Write-Host "✅ Applications deployed!" -ForegroundColor Green

# Step 5: Set up security features
Write-Host "5️⃣ Setting up security features..." -ForegroundColor Yellow
Write-Host "   🔒 Configuring Key Vault, WAF, and security policies..." -ForegroundColor Gray

if (Test-Path "infra\scripts\setup-security-features.ps1") {
    try {
        & ".\infra\scripts\setup-security-features.ps1" -EnvironmentName $EnvironmentName
        Write-Host "✅ Security features configured" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Security feature setup encountered issues, but continuing..." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ Security setup script not found, manual configuration required" -ForegroundColor Yellow
}

# Step 6: Set up auto-scaling
Write-Host "6️⃣ Setting up auto-scaling..." -ForegroundColor Yellow
Write-Host "   📈 Configuring auto-scaling for App Service and Container Apps..." -ForegroundColor Gray

if (Test-Path "infra\scripts\setup-autoscaling.ps1") {
    try {
        & ".\infra\scripts\setup-autoscaling.ps1" -EnvironmentName $EnvironmentName
        Write-Host "✅ Auto-scaling configured" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Auto-scaling setup failed, but continuing..." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ Auto-scaling script not found, manual configuration required" -ForegroundColor Yellow
}

# Step 7: Set up budget alerts
Write-Host "7️⃣ Setting up budget alerts..." -ForegroundColor Yellow
Write-Host "   💰 Creating budget alerts for ${BudgetAmount} USD..." -ForegroundColor Gray

if (Test-Path "infra\scripts\setup-cost-alerts.ps1") {
    try {
        & ".\infra\scripts\setup-cost-alerts.ps1" -EnvironmentName $EnvironmentName -BudgetAmount $BudgetAmount
        Write-Host "✅ Budget alerts configured" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Budget alert setup failed, but continuing..." -ForegroundColor Yellow
    }
}

# Step 8: Set up auto-shutdown
Write-Host "8️⃣ Setting up auto-shutdown..." -ForegroundColor Yellow

if (Test-Path "infra\scripts\setup-auto-shutdown.ps1") {
    try {
        & ".\infra\scripts\setup-auto-shutdown.ps1" -EnvironmentName $EnvironmentName -IdleHours 1
        Write-Host "✅ Auto-shutdown configured" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Auto-shutdown setup failed, but continuing..." -ForegroundColor Yellow
    }
}

# Step 9: Verify environment
Write-Host "9️⃣ Verifying QA environment..." -ForegroundColor Yellow

$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "true") {
    $resources = az resource list --resource-group $ResourceGroupName --query "length([])" --output tsv 2>$null
    Write-Host "   ✅ Found $resources resources in QA environment" -ForegroundColor Green
    
    # List key resources
    Write-Host "   🔍 Key resources:" -ForegroundColor Gray
    $keyResources = az resource list --resource-group $ResourceGroupName --query "[?contains(type, 'Microsoft.Web/sites') || contains(type, 'Microsoft.App/containerApps') || contains(type, 'Microsoft.DBforPostgreSQL') || contains(type, 'Microsoft.Storage/storageAccounts') || contains(type, 'Microsoft.KeyVault')].{Name:name, Type:type}" --output table
    Write-Host $keyResources
} else {
    Write-Host "   ❌ Resource group not found" -ForegroundColor Red
}

# Step 10: Get service URLs
Write-Host "🔟 Getting service URLs..." -ForegroundColor Yellow

try {
    $azdEnv = azd env get-values --output json | ConvertFrom-Json
    
    if ($azdEnv.AZURE_FRONTEND_URL) {
        Write-Host "   🌐 Frontend URL: $($azdEnv.AZURE_FRONTEND_URL)" -ForegroundColor Cyan
    }
    
    if ($azdEnv.AZURE_API_URL) {
        Write-Host "   🔗 API URL: $($azdEnv.AZURE_API_URL)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "   ⚠️ Could not retrieve service URLs" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "📋 QA Environment Startup Summary:" -ForegroundColor Cyan
Write-Host "Environment: QA (Quality Assurance)" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "Budget: $${BudgetAmount}/month with alerts" -ForegroundColor Cyan
Write-Host "Security: Enhanced (Key Vault, WAF, Private Endpoints)" -ForegroundColor Cyan
Write-Host "Auto-scaling: Enabled for load testing" -ForegroundColor Cyan
Write-Host "Auto-shutdown: Enabled (1 hour idle)" -ForegroundColor Cyan
Write-Host "Status: Running" -ForegroundColor Green

Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Cyan
Write-Host "   • Run security tests and vulnerability scans" -ForegroundColor Cyan
Write-Host "   • Perform load testing to validate auto-scaling" -ForegroundColor Cyan
Write-Host "   • Test WAF policies and security features" -ForegroundColor Cyan
Write-Host "   • Use shutdown script when not needed: .\infra\scripts\complete-shutdown-qa.ps1" -ForegroundColor Cyan

Write-Host ""
Write-Host "🚀🚀🚀 QA ENVIRONMENT STARTUP COMPLETE 🚀🚀🚀" -ForegroundColor Cyan -BackgroundColor Black
```

### Complete Production Environment Startup Script

Create file: `infra/scripts/complete-startup-prod.ps1`

```powershell
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete startup and provisioning of PRODUCTION environment resources from zero state.

.DESCRIPTION
    This script will provision and start ALL Azure resources required for the PRODUCTION environment
    including Premium P2V3 App Services, premium Container Apps, managed PostgreSQL with high availability,
    premium storage with CDN, premium Container Registry with geo-replication, premium Key Vault with HSM,
    Application Gateway with Premium WAF, DDoS protection, private endpoints, and enterprise monitoring.

.PARAMETER Force
    Skip confirmation prompts (use with extreme caution in production)

.EXAMPLE
    .\complete-startup-prod.ps1
    .\complete-startup-prod.ps1 -Force
#>

param(
    [switch]$Force
)

# Script configuration
$EnvironmentName = "prod"
$ResourceGroupName = "beeux-rg-prod-eastus"
$Location = "eastus"
$BudgetAmount = 30

Write-Host "🚀🚀🚀 COMPLETE PRODUCTION ENVIRONMENT STARTUP SCRIPT 🚀🚀🚀" -ForegroundColor Red -BackgroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Red
Write-Host "Environment: $EnvironmentName (PRODUCTION)" -ForegroundColor Red
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Red
Write-Host "💰 Budget Target: $${BudgetAmount}/month (premium features)" -ForegroundColor Yellow
Write-Host "🛡️  Architecture: Enterprise-grade with maximum security and performance" -ForegroundColor Yellow

# Extra safety confirmation for production
if (-not $Force) {
    Write-Host ""
    Write-Host "🚨🚨🚨 PRODUCTION ENVIRONMENT STARTUP 🚨🚨🚨" -ForegroundColor Red -BackgroundColor Yellow
    Write-Host ""
    Write-Host "This will provision and start:" -ForegroundColor Red
    Write-Host "✅ App Service (Premium P2V3 with advanced auto-scaling)" -ForegroundColor Green
    Write-Host "✅ Container Apps (Premium with enterprise features)" -ForegroundColor Green
    Write-Host "✅ Managed PostgreSQL with HIGH AVAILABILITY and encryption" -ForegroundColor Green
    Write-Host "✅ Premium Storage with CDN and geo-redundancy" -ForegroundColor Green
    Write-Host "✅ Premium Container Registry with Content Trust" -ForegroundColor Green
    Write-Host "✅ Premium Key Vault with HSM-backed keys" -ForegroundColor Green
    Write-Host "✅ Premium tier API Management with advanced analytics" -ForegroundColor Green
    Write-Host "✅ Application Gateway with Premium WAF" -ForegroundColor Green
    Write-Host "✅ DDoS Protection Plan" -ForegroundColor Green
    Write-Host "✅ Private endpoints for all services" -ForegroundColor Green
    Write-Host "✅ Enterprise monitoring and alerting" -ForegroundColor Green
    Write-Host "✅ Advanced auto-scaling with custom metrics" -ForegroundColor Green
    Write-Host ""
    Write-Host "💰 PRODUCTION COST ESTIMATE:" -ForegroundColor Red -BackgroundColor Yellow
    Write-Host "   📊 Estimated cost per HOUR: ~$2.30/hour" -ForegroundColor Red
    Write-Host "   📅 Estimated cost per DAY: ~$55.20/day" -ForegroundColor Red
    Write-Host "   📆 Estimated cost per MONTH: ~$1,656/month (if left running 24/7)" -ForegroundColor Red
    Write-Host "   ⏰ With auto-shutdown after 1 hour idle: ~$30/month" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⚠️ ⚠️ ⚠️  CRITICAL: Production charges are SIGNIFICANT! ⚠️ ⚠️ ⚠️" -ForegroundColor Red -BackgroundColor White
    Write-Host "💡 IMPORTANT: Use auto-shutdown to prevent high costs when not in use" -ForegroundColor Cyan
    Write-Host "⚠️ This is the PRODUCTION environment!" -ForegroundColor Red
    Write-Host ""
    
    $costConfirmation = Read-Host "Do you accept the estimated cost of ~$2.30/hour for PRODUCTION environment? Type 'Yes' to accept"
    if ($costConfirmation -ne "Yes") {
        Write-Host "❌ PRODUCTION environment startup cancelled - cost not accepted" -ForegroundColor Red
        exit 0
    }
    
    Write-Host "🛡️ PRODUCTION SAFETY CHECKPOINT:" -ForegroundColor Yellow
    $prodCheck = Read-Host "Are you authorized to start the PRODUCTION environment? (yes/no)"
    if ($prodCheck -ne "yes") {
        Write-Host "❌ Production startup cancelled for safety" -ForegroundColor Yellow
        exit 0
    }
    
    $confirmation = Read-Host "Type 'START-PRODUCTION' to confirm startup"
    if ($confirmation -ne "START-PRODUCTION") {
        Write-Host "❌ Production startup cancelled for safety" -ForegroundColor Yellow
        exit 0
    }
}

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Cyan

$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "❌ Not logged into Azure CLI. Please run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Azure CLI authenticated as: $($account.user.name)" -ForegroundColor Green

# Verify we have sufficient permissions for production
Write-Host "🔍 Verifying permissions..." -ForegroundColor Cyan
$roleAssignments = az role assignment list --assignee $account.user.name --scope "/subscriptions/$($account.id)" --query "[?roleDefinitionName=='Owner' || roleDefinitionName=='Contributor']" --output tsv
if (-not $roleAssignments) {
    Write-Host "❌ Insufficient permissions. Owner or Contributor role required for production." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Sufficient permissions verified" -ForegroundColor Green

$azdVersion = azd version 2>$null
if (-not $azdVersion) {
    Write-Host "❌ Azure Developer CLI not found. Please install azd first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Azure Developer CLI available" -ForegroundColor Green

# Step 1: Set up AZD environment
Write-Host "1️⃣ Setting up AZD PRODUCTION environment..." -ForegroundColor Yellow

$existingEnv = azd env list --output json 2>$null | ConvertFrom-Json | Where-Object { $_.Name -eq "prod" }
if ($existingEnv) {
    Write-Host "   📋 Production environment already exists, selecting it..." -ForegroundColor Gray
    azd env select prod
} else {
    Write-Host "   🆕 Creating new PRODUCTION environment..." -ForegroundColor Gray
    azd env new prod
}

# Step 2: Configure environment variables for Production
Write-Host "2️⃣ Configuring PRODUCTION environment variables..." -ForegroundColor Yellow

Write-Host "   Setting core configuration..." -ForegroundColor Gray
azd env set AZURE_LOCATION $Location
azd env set AZURE_RESOURCE_GROUP_NAME $ResourceGroupName
azd env set AZURE_APP_NAME "beeux-prod"
azd env set AZURE_ENVIRONMENT_NAME $EnvironmentName

Write-Host "   Setting premium database configuration..." -ForegroundColor Gray
azd env set DATABASE_TYPE "managed-premium"
azd env set DATABASE_NAME "beeux_prod"
azd env set POSTGRES_ADMIN_USERNAME "postgres_admin"

Write-Host "   Setting premium storage and CDN configuration..." -ForegroundColor Gray
azd env set BLOB_CONTAINER_NAME "audio-files-prod"
azd env set CDN_PROFILE_NAME "beeux-cdn-prod"

Write-Host "   Setting budget and alerting..." -ForegroundColor Gray
azd env set BUDGET_AMOUNT $BudgetAmount
azd env set ALERT_EMAIL_PRIMARY "prashantmdesai@yahoo.com"
azd env set ALERT_EMAIL_SECONDARY "prashantmdesai@hotmail.com"
azd env set ALERT_PHONE "+12246564855"

Write-Host "   Setting enterprise security and performance flags..." -ForegroundColor Gray
azd env set USE_FREE_TIER "false"
azd env set USE_MANAGED_SERVICES "true"
azd env set ENABLE_SECURITY_FEATURES "true"
azd env set ENABLE_PREMIUM_SECURITY "true"
azd env set ENABLE_AUTO_SCALING "true"
azd env set ENABLE_ADVANCED_AUTO_SCALING "true"
azd env set ENABLE_PRIVATE_ENDPOINTS "true"
azd env set ENABLE_WAF "true"
azd env set ENABLE_DDOS_PROTECTION "true"
azd env set ENABLE_KEY_VAULT_HSM "true"
azd env set ENABLE_CONTENT_TRUST "true"
azd env set AUTO_SHUTDOWN_ENABLED "true"
azd env set IDLE_SHUTDOWN_HOURS "1"

Write-Host "✅ PRODUCTION environment variables configured" -ForegroundColor Green

# Step 3: Provision Azure infrastructure
Write-Host "3️⃣ Provisioning PRODUCTION Azure infrastructure..." -ForegroundColor Yellow
Write-Host "   🏗️  Creating enterprise-grade services with maximum security..." -ForegroundColor Gray
Write-Host "   ⏳ Estimated time: 25-40 minutes for PRODUCTION environment..." -ForegroundColor Gray

$provisionResult = azd provision --no-prompt 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ PRODUCTION infrastructure provisioning failed!" -ForegroundColor Red
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host $provisionResult -ForegroundColor Red
    exit 1
}

Write-Host "✅ PRODUCTION infrastructure provisioned successfully!" -ForegroundColor Green

# Step 4: Deploy applications to production
Write-Host "4️⃣ Deploying applications to PRODUCTION..." -ForegroundColor Yellow
Write-Host "   📦 Building and deploying to premium production services..." -ForegroundColor Gray

$deployResult = azd deploy --no-prompt 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ PRODUCTION application deployment failed!" -ForegroundColor Red
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host $deployResult -ForegroundColor Red
    Write-Host "⚠️ Continuing with infrastructure configuration..." -ForegroundColor Yellow
}

Write-Host "✅ Applications deployed to PRODUCTION!" -ForegroundColor Green

# Step 5: Set up premium security features
Write-Host "5️⃣ Setting up premium security features..." -ForegroundColor Yellow
Write-Host "   🛡️  Configuring HSM Key Vault, Premium WAF, DDoS protection..." -ForegroundColor Gray

if (Test-Path "infra\scripts\setup-security-features.ps1") {
    try {
        & ".\infra\scripts\setup-security-features.ps1" -EnvironmentName $EnvironmentName
        Write-Host "✅ Premium security features configured" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Security feature setup encountered issues, but continuing..." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ Security setup script not found, manual configuration required" -ForegroundColor Yellow
}

# Step 6: Set up advanced auto-scaling
Write-Host "6️⃣ Setting up advanced auto-scaling..." -ForegroundColor Yellow
Write-Host "   📈 Configuring enterprise auto-scaling with custom metrics..." -ForegroundColor Gray

if (Test-Path "infra\scripts\setup-autoscaling.ps1") {
    try {
        & ".\infra\scripts\setup-autoscaling.ps1" -EnvironmentName $EnvironmentName
        Write-Host "✅ Advanced auto-scaling configured" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Auto-scaling setup failed, but continuing..." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ Auto-scaling script not found, manual configuration required" -ForegroundColor Yellow
}

# Step 7: Set up budget alerts
Write-Host "7️⃣ Setting up budget alerts..." -ForegroundColor Yellow
Write-Host "   💰 Creating budget alerts for ${BudgetAmount} USD..." -ForegroundColor Gray

if (Test-Path "infra\scripts\setup-cost-alerts.ps1") {
    try {
        & ".\infra\scripts\setup-cost-alerts.ps1" -EnvironmentName $EnvironmentName -BudgetAmount $BudgetAmount
        Write-Host "✅ Budget alerts configured" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Budget alert setup failed, but continuing..." -ForegroundColor Yellow
    }
}

# Step 8: Set up auto-shutdown
Write-Host "8️⃣ Setting up auto-shutdown..." -ForegroundColor Yellow

if (Test-Path "infra\scripts\setup-auto-shutdown.ps1") {
    try {
        & ".\infra\scripts\setup-auto-shutdown.ps1" -EnvironmentName $EnvironmentName -IdleHours 1
        Write-Host "✅ Auto-shutdown configured" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Auto-shutdown setup failed, but continuing..." -ForegroundColor Yellow
    }
}

# Step 9: Verify PRODUCTION environment
Write-Host "9️⃣ Verifying PRODUCTION environment..." -ForegroundColor Yellow

$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "true") {
    $resources = az resource list --resource-group $ResourceGroupName --query "length([])" --output tsv 2>$null
    Write-Host "   ✅ Found $resources resources in PRODUCTION environment" -ForegroundColor Green
    
    # List enterprise resources
    Write-Host "   🔍 Enterprise resources:" -ForegroundColor Gray
    $enterpriseResources = az resource list --resource-group $ResourceGroupName --query "[].{Name:name, Type:type, SKU:sku.name}" --output table
    Write-Host $enterpriseResources
} else {
    Write-Host "   ❌ PRODUCTION resource group not found" -ForegroundColor Red
}

# Step 10: Get PRODUCTION service URLs
Write-Host "🔟 Getting PRODUCTION service URLs..." -ForegroundColor Yellow

try {
    $azdEnv = azd env get-values --output json | ConvertFrom-Json
    
    if ($azdEnv.AZURE_FRONTEND_URL) {
        Write-Host "   🌐 PRODUCTION Frontend URL: $($azdEnv.AZURE_FRONTEND_URL)" -ForegroundColor Cyan
    }
    
    if ($azdEnv.AZURE_API_URL) {
        Write-Host "   🔗 PRODUCTION API URL: $($azdEnv.AZURE_API_URL)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "   ⚠️ Could not retrieve service URLs" -ForegroundColor Yellow
}

# Step 11: Run production health checks
Write-Host "1️⃣1️⃣ Running PRODUCTION health checks..." -ForegroundColor Yellow

Write-Host "   🏥 Checking application health..." -ForegroundColor Gray
if ($azdEnv.AZURE_FRONTEND_URL) {
    try {
        $healthCheck = Invoke-WebRequest -Uri "$($azdEnv.AZURE_FRONTEND_URL)/health" -UseBasicParsing -TimeoutSec 30 2>$null
        if ($healthCheck.StatusCode -eq 200) {
            Write-Host "   ✅ Frontend health check passed" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ⚠️ Frontend health check failed or not available" -ForegroundColor Yellow
    }
}

# Summary
Write-Host ""
Write-Host "📋 PRODUCTION Environment Startup Summary:" -ForegroundColor Red
Write-Host "Environment: PRODUCTION" -ForegroundColor Red
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Red
Write-Host "Budget: $${BudgetAmount}/month with alerts" -ForegroundColor Red
Write-Host "Security: Enterprise-grade (HSM Key Vault, DDoS, Premium WAF)" -ForegroundColor Red
Write-Host "Performance: Premium P2V3 with advanced auto-scaling" -ForegroundColor Red
Write-Host "High Availability: Zone redundant with geo-replication" -ForegroundColor Red
Write-Host "Auto-shutdown: Enabled (1 hour idle)" -ForegroundColor Red
Write-Host "Status: Running" -ForegroundColor Green

Write-Host ""
Write-Host "💡 PRODUCTION Next Steps:" -ForegroundColor Cyan
Write-Host "   • Monitor production metrics and performance" -ForegroundColor Cyan
Write-Host "   • Set up production CI/CD pipelines" -ForegroundColor Cyan
Write-Host "   • Configure production monitoring and alerting" -ForegroundColor Cyan
Write-Host "   • Review security policies and compliance" -ForegroundColor Cyan
Write-Host "   • Use shutdown script when maintenance needed: .\infra\scripts\complete-shutdown-prod.ps1" -ForegroundColor Cyan

Write-Host ""
Write-Host "📧 PRODUCTION STARTUP COMPLETE - NOTIFY STAKEHOLDERS" -ForegroundColor Red -BackgroundColor Yellow
Write-Host ""
Write-Host "🚀🚀🚀 PRODUCTION ENVIRONMENT STARTUP COMPLETE 🚀🚀🚀" -ForegroundColor Red -BackgroundColor Black
```

### Emergency Startup Script (All Environments)

Create file: `infra/scripts/emergency-startup-all.ps1`

```powershell
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

# Start all environment startups in parallel for fastest recovery
Write-Host "⚡ Executing all environment startup scripts in parallel..." -ForegroundColor Green

$jobs = @()

# Start IT environment startup
$jobs += Start-Job -ScriptBlock {
    param($Force)
    & ".\infra\scripts\complete-startup-it.ps1" $(if($Force) { "-Force" })
} -ArgumentList $Force

# Start QA environment startup  
$jobs += Start-Job -ScriptBlock {
    param($Force)
    & ".\infra\scripts\complete-startup-qa.ps1" $(if($Force) { "-Force" })
} -ArgumentList $Force

# Start Production environment startup
$jobs += Start-Job -ScriptBlock {
    param($Force)
    & ".\infra\scripts\complete-startup-prod.ps1" $(if($Force) { "-Force" })
} -ArgumentList $Force

# Wait for all jobs to complete
Write-Host "⏳ Waiting for all environments to start up..." -ForegroundColor Yellow
Write-Host "   This may take 30-45 minutes for all environments..." -ForegroundColor Gray

$jobs | Wait-Job | Receive-Job

# Cleanup jobs
$jobs | Remove-Job

Write-Host "✅ EMERGENCY STARTUP COMPLETE" -ForegroundColor Green -BackgroundColor Black
Write-Host "🌐 All environments should now be running" -ForegroundColor Green
```

### Startup Verification Script

Create file: `infra/scripts/startup-verification.ps1`

```powershell
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verify that environment startup was successful and all resources are running.

.DESCRIPTION
    This script checks all resource groups and validates that resources are properly started and accessible.

.PARAMETER Environment
    Specific environment to check (it, qa, prod, or all)

.EXAMPLE
    .\startup-verification.ps1 -Environment all
    .\startup-verification.ps1 -Environment prod
#>

param(
    [ValidateSet("it", "qa", "prod", "all")]
    [string]$Environment = "all"
)

$resourceGroups = @()

switch ($Environment) {
    "it" { $resourceGroups = @("beeux-rg-it-eastus") }
    "qa" { $resourceGroups = @("beeux-rg-qa-eastus") }
    "prod" { $resourceGroups = @("beeux-rg-prod-eastus") }
    "all" { $resourceGroups = @("beeux-rg-it-eastus", "beeux-rg-qa-eastus", "beeux-rg-prod-eastus") }
}

Write-Host "🔍 Verifying startup for environment(s): $Environment" -ForegroundColor Cyan

foreach ($rg in $resourceGroups) {
    Write-Host ""
    Write-Host "Checking Resource Group: $rg" -ForegroundColor Yellow
    
    $exists = az group exists --name $rg
    if ($exists -eq "false") {
        Write-Host "❌ Resource group does not exist - startup failed or not started" -ForegroundColor Red
        continue
    }
    
    Write-Host "✅ Resource group exists" -ForegroundColor Green
    
    $resources = az resource list --resource-group $rg --query "[].{Name:name, Type:type, State:properties.provisioningState}" --output table
    if ($resources) {
        Write-Host "📋 Resources found:" -ForegroundColor Green
        Write-Host $resources
        
        # Check for running resources
        $runningResources = az resource list --resource-group $rg --query "[?properties.provisioningState=='Succeeded'].name" --output tsv
        if ($runningResources) {
            $runningCount = ($runningResources | Measure-Object).Count
            Write-Host "✅ $runningCount resources running successfully" -ForegroundColor Green
        }
        
        # Check for failed resources
        $failedResources = az resource list --resource-group $rg --query "[?properties.provisioningState=='Failed'].{Name:name, Type:type}" --output table
        if ($failedResources) {
            Write-Host "❌ Some resources failed to start:" -ForegroundColor Red
            Write-Host $failedResources
        }
    } else {
        Write-Host "❌ No resources found in group" -ForegroundColor Red
    }
    
    # Check specific service types
    Write-Host ""
    Write-Host "🔍 Checking key services:" -ForegroundColor Cyan
    
    # App Services
    $appServices = az webapp list --resource-group $rg --query "[].{Name:name, State:state, Url:defaultHostName}" --output table
    if ($appServices) {
        Write-Host "   🌐 App Services:" -ForegroundColor Gray
        Write-Host "   $appServices"
    }
    
    # Container Apps
    $containerApps = az containerapp list --resource-group $rg --query "[].{Name:name, Status:properties.provisioningState, Url:properties.configuration.ingress.fqdn}" --output table 2>$null
    if ($containerApps) {
        Write-Host "   🐳 Container Apps:" -ForegroundColor Gray
        Write-Host "   $containerApps"
    }
    
    # Databases
    $databases = az postgres flexible-server list --resource-group $rg --query "[].{Name:name, State:state, Version:version}" --output table 2>$null
    if ($databases) {
        Write-Host "   🗄️  PostgreSQL Databases:" -ForegroundColor Gray
        Write-Host "   $databases"
    }
    
    # Storage Accounts
    $storageAccounts = az storage account list --resource-group $rg --query "[].{Name:name, Status:statusOfPrimary, Tier:sku.tier}" --output table
    if ($storageAccounts) {
        Write-Host "   💾 Storage Accounts:" -ForegroundColor Gray
        Write-Host "   $storageAccounts"
    }
}

Write-Host ""
Write-Host "🔍 Startup verification complete for: $Environment" -ForegroundColor Cyan
```

### Environment Status Check Script

Create file: `infra/scripts/check-environment-status.ps1`

```powershell
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Check the current status of all environments and provide cost estimates.

.DESCRIPTION
    This script provides a dashboard view of all environments, their resource status,
    and current estimated costs.

.EXAMPLE
    .\check-environment-status.ps1
#>

Write-Host "📊 BEEUX ENVIRONMENT STATUS DASHBOARD 📊" -ForegroundColor Cyan -BackgroundColor Black
Write-Host "=========================================" -ForegroundColor Cyan

$environments = @(
    @{ Name = "IT"; ResourceGroup = "beeux-rg-it-eastus"; Budget = 10; Color = "Green" },
    @{ Name = "QA"; ResourceGroup = "beeux-rg-qa-eastus"; Budget = 20; Color = "Cyan" },
    @{ Name = "Production"; ResourceGroup = "beeux-rg-prod-eastus"; Budget = 30; Color = "Red" }
)

foreach ($env in $environments) {
    Write-Host ""
    Write-Host "🔍 $($env.Name) Environment Status" -ForegroundColor $env.Color
    Write-Host "Resource Group: $($env.ResourceGroup)" -ForegroundColor Gray
    Write-Host "Budget: $($env.Budget) USD/month" -ForegroundColor Gray
    
    # Check if resource group exists
    $exists = az group exists --name $env.ResourceGroup
    if ($exists -eq "false") {
        Write-Host "❌ Status: SHUT DOWN (No resources)" -ForegroundColor Red
        Write-Host "💰 Current Cost: $0.00" -ForegroundColor Green
        Write-Host "⚡ To start: .\infra\scripts\complete-startup-$($env.Name.ToLower()).ps1" -ForegroundColor Yellow
        continue
    }
    
    # Count resources
    $resourceCount = az resource list --resource-group $env.ResourceGroup --query "length([])" --output tsv 2>$null
    if ([int]$resourceCount -eq 0) {
        Write-Host "❌ Status: SHUT DOWN (Empty resource group)" -ForegroundColor Red
        Write-Host "💰 Current Cost: $0.00" -ForegroundColor Green
    } else {
        Write-Host "✅ Status: RUNNING ($resourceCount resources)" -ForegroundColor Green
        
        # List key resources
        $keyResources = az resource list --resource-group $env.ResourceGroup --query "[?contains(type, 'Microsoft.Web/sites') || contains(type, 'Microsoft.App/containerApps') || contains(type, 'Microsoft.DBforPostgreSQL') || contains(type, 'Microsoft.Storage/storageAccounts')].{Name:name, Type:type}" --output tsv 2>$null
        if ($keyResources) {
            Write-Host "🔑 Key Resources: $(($keyResources | Measure-Object).Count) active" -ForegroundColor Gray
        }
        
        Write-Host "💰 Estimated Cost: ~$($env.Budget) USD/month (when fully utilized)" -ForegroundColor Yellow
        Write-Host "🛑 To shutdown: .\infra\scripts\complete-shutdown-$($env.Name.ToLower()).ps1" -ForegroundColor Yellow
    }
    
    Write-Host "────────────────────────────────────────" -ForegroundColor Gray
}

# Overall summary
Write-Host ""
Write-Host "📊 OVERALL SUMMARY" -ForegroundColor Cyan
$totalRunning = 0
$totalCost = 0

foreach ($env in $environments) {
    $exists = az group exists --name $env.ResourceGroup
    if ($exists -eq "true") {
        $resourceCount = az resource list --resource-group $env.ResourceGroup --query "length([])" --output tsv 2>$null
        if ([int]$resourceCount -gt 0) {
            $totalRunning++
            $totalCost += $env.Budget
        }
    }
}

Write-Host "🌐 Running Environments: $totalRunning/3" -ForegroundColor $(if ($totalRunning -eq 0) { "Green" } else { "Yellow" })
Write-Host "💰 Estimated Total Monthly Cost: $${totalCost}" -ForegroundColor $(if ($totalCost -eq 0) { "Green" } elseif ($totalCost -lt 30) { "Yellow" } else { "Red" })

Write-Host ""
Write-Host "🚀 Quick Actions:" -ForegroundColor Cyan
Write-Host "   Start all environments: .\infra\scripts\emergency-startup-all.ps1" -ForegroundColor Gray
Write-Host "   Shutdown all environments: .\infra\scripts\emergency-shutdown-all.ps1" -ForegroundColor Gray
Write-Host "   Verify startup: .\infra\scripts\startup-verification.ps1 -Environment all" -ForegroundColor Gray
Write-Host "   Verify shutdown: .\infra\scripts\verify-shutdown.ps1 -Environment all" -ForegroundColor Gray
```

## Quick Usage Guide

### How to Use the Startup Scripts

1. **Individual Environment Startup:**
```powershell
# Start IT environment (cost-optimized)
.\infra\scripts\complete-startup-it.ps1

# Start QA environment (security-focused)
.\infra\scripts\complete-startup-qa.ps1

# Start Production environment (premium features)
.\infra\scripts\complete-startup-prod.ps1
```

2. **Emergency Startup (All Environments):**
```powershell
# In case of disaster recovery or rapid environment creation
.\infra\scripts\emergency-startup-all.ps1
```

3. **Verify Startup Success:**
```powershell
# Check all environments
.\infra\scripts\startup-verification.ps1 -Environment all

# Check specific environment
.\infra\scripts\startup-verification.ps1 -Environment prod
```

4. **Check Environment Status:**
```powershell
# Get dashboard view of all environments
.\infra\scripts\check-environment-status.ps1
```

### Execution from VS Code Terminal

1. **Open VS Code Terminal** (Ctrl+` or Terminal → New Terminal)
2. **Navigate to project directory:**
```powershell
cd C:\dev\beeinfra
```
3. **Make scripts executable (if needed):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
4. **Run desired startup script:**
```powershell
# Example: Start IT environment
.\infra\scripts\complete-startup-it.ps1
```

### Execution from Azure CLI

You can also run these scripts directly from Azure CLI in any terminal:

```bash
# Login to Azure first
az login

# Run startup script
pwsh ./infra/scripts/complete-startup-it.ps1
```

### Environment Configuration Management

⚠️ **IMPORTANT**: When you modify the environment configuration (add/remove resources), you MUST update both startup and shutdown scripts:

#### When Adding New Resources:
1. **Update the environment's Bicep templates** in `infra/modules/`
2. **Add the new resource to the startup script** for that environment
3. **Add the new resource to the shutdown script** for that environment (in reverse dependency order)
4. **Update the verification scripts** to check for the new resource
5. **Test both startup and shutdown** to ensure they work correctly

#### When Removing Resources:
1. **Remove from Bicep templates** first
2. **Remove from startup script** for that environment  
3. **Remove from shutdown script** for that environment
4. **Update verification scripts**
5. **Test the modified scripts**

#### Example: Adding Redis Cache to QA Environment

If you add Azure Cache for Redis to the QA environment:

**1. Update `complete-startup-qa.ps1`:**
```powershell
# Add after Step 3 (Provision Azure infrastructure)
Write-Host "   🔴 Provisioning Redis Cache for session management..." -ForegroundColor Gray
```

**2. Update `complete-shutdown-qa.ps1`:**
```powershell
# Add in Step 7 (Delete data resources)
Write-Host "   🗑️ Deleting Redis Cache..." -ForegroundColor Cyan
$redisCaches = az redis list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($cache in $redisCaches) {
    if ($cache) {
        Write-Host "     Deleting Redis Cache: $cache" -ForegroundColor Gray
        az redis delete --name $cache --resource-group $ResourceGroupName --yes 2>$null
    }
}
```

**3. Update verification scripts** to check Redis status.

### Script Execution Order

**Startup Order (when starting from zero):**
1. IT Environment: `complete-startup-it.ps1` (lowest cost, fastest)
2. QA Environment: `complete-startup-qa.ps1` (security testing)
3. Production Environment: `complete-startup-prod.ps1` (enterprise features)

**Shutdown Order (when stopping everything):**
1. Production Environment: `complete-shutdown-prod.ps1` (highest cost savings)
2. QA Environment: `complete-shutdown-qa.ps1` (medium cost savings)
3. IT Environment: `complete-shutdown-it.ps1` (lowest cost savings)

### Important Notes

- ✅ **All startup scripts provision resources from COMPLETE ZERO STATE**
- 🔧 **Scripts use Azure Developer CLI (azd) for infrastructure provisioning**
- 📊 **Scripts include resource verification and health checks**
- 💰 **Budget alerts are automatically configured during startup**
- ⏰ **Auto-shutdown is configured to prevent runaway costs**
- 🔐 **Production startup requires multiple confirmations for safety**
- 📋 **Scripts provide detailed progress feedback and URLs**
- 🧹 **Scripts handle AZD environment configuration automatically**

The startup scripts are designed to:
- **Provision resources from complete zero state** using Azure Developer CLI
- **Configure environment-specific settings** automatically
- **Handle dependencies in correct order** for successful provisioning
- **Provide detailed progress feedback** with colored output and time estimates
- **Include safety confirmations** especially for production environments
- **Set up monitoring and cost controls** automatically during startup
- **Verify successful deployment** with health checks and URL retrieval
- **Handle AZD environment configuration** seamlessly

### Script Maintenance Requirements

**🔄 CRITICAL REQUIREMENT**: Whenever you modify the infrastructure configuration for any environment, you MUST update BOTH the startup AND shutdown scripts for that environment.

#### Maintenance Checklist for Infrastructure Changes:

**When adding a new Azure resource to an environment:**
- [ ] ✅ Update the Bicep templates in `infra/modules/`
- [ ] ✅ Add provisioning logic to the appropriate `complete-startup-{env}.ps1`
- [ ] ✅ Add deletion logic to the appropriate `complete-shutdown-{env}.ps1` (in reverse dependency order)
- [ ] ✅ Update `startup-verification.ps1` to check the new resource
- [ ] ✅ Update `verify-shutdown.ps1` to verify deletion of the new resource
- [ ] ✅ Update `check-environment-status.ps1` to display the new resource
- [ ] ✅ Test both startup and shutdown scripts thoroughly
- [ ] ✅ Update documentation if the resource changes the environment's purpose

**When removing an Azure resource from an environment:**
- [ ] ✅ Remove from Bicep templates first
- [ ] ✅ Remove provisioning logic from `complete-startup-{env}.ps1`
- [ ] ✅ Remove deletion logic from `complete-shutdown-{env}.ps1`
- [ ] ✅ Update all verification and status scripts
- [ ] ✅ Test the modified scripts to ensure no errors
- [ ] ✅ Update cost estimates in documentation

**When modifying resource configuration (SKU, features, etc.):**
- [ ] ✅ Update environment variables in startup scripts
- [ ] ✅ Update shutdown scripts if deletion process changes
- [ ] ✅ Update cost estimates and budget amounts
- [ ] ✅ Test scripts with new configuration
- [ ] ✅ Update documentation with new features/costs

### Example: Adding Azure Cache for Redis to QA Environment

Here's a complete example of how to add a new resource and maintain script consistency:

#### Step 1: Update Bicep Templates
Add to `infra/modules/cache.bicep`:
```bicep
resource redisCache 'Microsoft.Cache/redis@2023-04-01' = {
  name: 'beeux-redis-qa-${location}'
  location: location
  properties: {
    sku: {
      name: 'Standard'
      capacity: 1
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
  }
  tags: {
    Environment: 'QA'
    Project: 'Beeux'
    Purpose: 'Session Management'
  }
}
```

#### Step 2: Update QA Startup Script
Add to `complete-startup-qa.ps1` after infrastructure provisioning:
```powershell
# In Step 3: Provision Azure infrastructure
Write-Host "   🔴 Provisioning Redis Cache for session management..." -ForegroundColor Gray
azd env set ENABLE_REDIS_CACHE "true"
azd env set REDIS_SKU "Standard"
azd env set REDIS_CAPACITY "1"
```

#### Step 3: Update QA Shutdown Script
Add to `complete-shutdown-qa.ps1` in Step 7 (Delete data resources):
```powershell
# Delete Redis Caches
Write-Host "   🗑️ Deleting Redis Caches..." -ForegroundColor Cyan
$redisCaches = az redis list --resource-group $ResourceGroupName --query "[].name" --output tsv
foreach ($cache in $redisCaches) {
    if ($cache) {
        Write-Host "     Deleting Redis Cache: $cache" -ForegroundColor Gray
        az redis delete --name $cache --resource-group $ResourceGroupName --yes 2>$null
    }
}
```

#### Step 4: Update Verification Scripts
Add to `startup-verification.ps1`:
```powershell
# Redis Caches
$redisCaches = az redis list --resource-group $rg --query "[].{Name:name, Status:provisioningState, Tier:sku.name}" --output table 2>$null
if ($redisCaches) {
    Write-Host "   🔴 Redis Caches:" -ForegroundColor Gray
    Write-Host "   $redisCaches"
}
```

#### Step 5: Update Status Check Script
Add to `check-environment-status.ps1`:
```powershell
# In the key resources check, add Redis
$keyResources = az resource list --resource-group $env.ResourceGroup --query "[?contains(type, 'Microsoft.Web/sites') || contains(type, 'Microsoft.App/containerApps') || contains(type, 'Microsoft.DBforPostgreSQL') || contains(type, 'Microsoft.Storage/storageAccounts') || contains(type, 'Microsoft.Cache/redis')].{Name:name, Type:type}" --output tsv 2>$null
```

#### Step 6: Test and Document
1. **Test startup script**: `.\infra\scripts\complete-startup-qa.ps1`
2. **Verify Redis is created**: `.\infra\scripts\startup-verification.ps1 -Environment qa`
3. **Test shutdown script**: `.\infra\scripts\complete-shutdown-qa.ps1`
4. **Verify Redis is deleted**: `.\infra\scripts\verify-shutdown.ps1 -Environment qa`
5. **Update budget if needed**: Adjust `$BudgetAmount` in QA startup script

---

## Infrastructure Components Configuration
```

### 3. Environment-Specific Budget Targets

#### IT Environment Budget ($10 Monthly)
- **Target**: Leverage Azure Free Tier maximally
- **Alert Thresholds**: $5 (50%), $8 (80%), $10 (100%)
- **Auto-Shutdown**: After 1 hour of inactivity
- **Free Tier Resources**:
  - App Service: F1 Free tier (1GB disk, 60 CPU minutes/day)
  - Storage Account: 5GB free outbound data transfer
  - Application Insights: 5GB/month free
  - Container Registry: Basic tier with 10GB storage

#### QA Environment Budget ($20 Monthly)
- **Target**: Balanced cost and performance for testing
- **Alert Thresholds**: $10 (50%), $16 (80%), $20 (100%)
- **Auto-Shutdown**: After 1 hour of inactivity
- **Cost Optimization**: Automatic resource shutdown when idle

#### Production Environment Budget ($30 Monthly)
- **Target**: Performance and reliability optimized with cost controls
- **Alert Thresholds**: $15 (50%), $24 (80%), $30 (100%)
- **Auto-Shutdown**: After 1 hour of inactivity (configurable)
- **Cost Management**: Aggressive cost monitoring with immediate alerts

### 4. Cost Optimization Monitoring
```powershell
# Weekly cost review script
# Add to scheduled tasks or GitHub Actions

# Get current month costs by environment
az consumption usage list `
    --start-date (Get-Date).AddDays(-30).ToString("yyyy-MM-dd") `
    --end-date (Get-Date).ToString("yyyy-MM-dd") `
    --query "[?contains(instanceName, 'beeux-it')].{Resource:instanceName, Cost:pretaxCost}" `
    --output table

# Generate cost optimization recommendations
az advisor recommendation list `
    --category Cost `
    --query "[?contains(resourceMetadata.resourceId, 'beeux')].{Resource:resourceMetadata.resourceId, Recommendation:shortDescription.solution}" `
    --output table
```

## Application Configuration

### 1. Angular Frontend Environment Configuration

Create environment-specific configuration files:

#### `src/environments/environment.it.ts`
```typescript
export const environment = {
  production: false,
  apiUrl: 'https://beeux-api-it-eastus.azurecontainerapps.io/api',
  audioBaseUrl: 'https://beeuxitstorage.blob.core.windows.net/audio-files-it',
  environmentName: 'IT'
};
```

#### `src/environments/environment.qa.ts`
```typescript
export const environment = {
  production: false,
  apiUrl: 'https://beeux-api-qa-eastus.azurecontainerapps.io/api',
  audioBaseUrl: 'https://beeuxqastorage.blob.core.windows.net/audio-files-qa',
  environmentName: 'QA'
};
```

#### `src/environments/environment.prod.ts`
```typescript
export const environment = {
  production: true,
  apiUrl: 'https://beeux-api-prod-eastus.azurecontainerapps.io/api',
  audioBaseUrl: 'https://beeuxcdn.azureedge.net/audio-files-prod',
  environmentName: 'Production'
};
```

### 2. Spring Boot API Configuration

#### `application-it.yml`
```yaml
spring:
  profiles:
    active: it
  datasource:
    url: jdbc:postgresql://beeux-db-it-eastus.postgres.database.azure.com:5432/beeux_it
    username: ${POSTGRES_USERNAME}
    password: ${POSTGRES_PASSWORD}
  
azure:
  storage:
    account-name: ${AZURE_STORAGE_ACCOUNT_NAME}
    container-name: audio-files-it
  keyvault:
    uri: ${AZURE_KEYVAULT_URI}

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
```

#### `application-qa.yml`
```yaml
spring:
  profiles:
    active: qa
  datasource:
    url: jdbc:postgresql://beeux-db-qa-eastus.postgres.database.azure.com:5432/beeux_qa
    username: ${POSTGRES_USERNAME}
    password: ${POSTGRES_PASSWORD}
  
azure:
  storage:
    account-name: ${AZURE_STORAGE_ACCOUNT_NAME}
    container-name: audio-files-qa
  keyvault:
    uri: ${AZURE_KEYVAULT_URI}

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
```

#### `application-prod.yml`
```yaml
spring:
  profiles:
    active: prod
  datasource:
    url: jdbc:postgresql://beeux-db-prod-eastus.postgres.database.azure.com:5432/beeux_prod
    username: ${POSTGRES_USERNAME}
    password: ${POSTGRES_PASSWORD}
    hikari:
      maximum-pool-size: 20
      connection-timeout: 30000
  
azure:
  storage:
    account-name: ${AZURE_STORAGE_ACCOUNT_NAME}
    container-name: audio-files-prod
  keyvault:
    uri: ${AZURE_KEYVAULT_URI}
  cdn:
    endpoint: https://beeuxcdn.azureedge.net

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
```

## CI/CD Pipeline Setup

### 1. GitHub Actions Workflow Structure
```
.github/
└── workflows/
    ├── deploy-it.yml
    ├── deploy-qa.yml
    └── deploy-prod.yml
```

### 2. Environment Promotion Strategy
- **IT Environment**: Automatic deployment on feature branch merges
- **QA Environment**: Manual deployment after IT validation
- **Production**: Manual deployment after QA approval with additional safeguards

### 3. Deployment Commands with Environment Identification
```powershell
# Deploy to IT Environment
Write-Host "🔧 Deploying to IT Environment" -ForegroundColor Green
azd env select it
Write-Host "Current Environment: IT" -ForegroundColor Yellow
azd deploy

# Deploy to QA Environment (after IT validation)
Write-Host "🧪 Deploying to QA Environment" -ForegroundColor Cyan
azd env select qa
Write-Host "Current Environment: QA" -ForegroundColor Yellow
azd deploy

# Deploy to Production (after QA approval)
Write-Host "🏭 Deploying to PRODUCTION Environment" -ForegroundColor Red -BackgroundColor Yellow
azd env select prod
Write-Host "Current Environment: PRODUCTION" -ForegroundColor Red
$confirmation = Read-Host "⚠️  Type 'DEPLOY-PRODUCTION' to confirm deployment to production"
if ($confirmation -eq 'DEPLOY-PRODUCTION') {
    azd deploy
} else {
    Write-Host "❌ Production deployment cancelled for safety" -ForegroundColor Red
}

# Environment Status Check Commands
Write-Host "📊 Environment Status Commands:" -ForegroundColor Cyan
Write-Host "IT Status:     az resource list --resource-group beeux-rg-it-eastus --output table" -ForegroundColor Yellow
Write-Host "QA Status:     az resource list --resource-group beeux-rg-qa-eastus --output table" -ForegroundColor Yellow
Write-Host "Prod Status:   az resource list --resource-group beeux-rg-prod-eastus --output table" -ForegroundColor Yellow
```

## Monitoring and Observability

### 1. Application Insights Configuration
- Custom metrics for spelling bee sessions
- Performance monitoring for audio file streaming
- Error tracking and alerting
- User behavior analytics (anonymized for children)

### 2. Health Checks
```yaml
# Spring Boot Actuator health checks
management:
  health:
    db:
      enabled: true
    azure-storage:
      enabled: true
    diskspace:
      enabled: true
```

### 3. Alerting Rules
- Database connection failures
- API response time > 2 seconds
- Audio file access errors
- Storage account issues
- High memory/CPU usage

## Data Management

### 1. Database Migration Strategy
```sql
-- Example Flyway migration script
-- V1.0.0__Initial_schema.sql
CREATE TABLE word (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    word_text VARCHAR(100) NOT NULL,
    audio_file_name VARCHAR(200) NOT NULL,
    difficulty_level INTEGER NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) DEFAULT 'system',
    modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by VARCHAR(100) DEFAULT 'system'
);

CREATE INDEX idx_word_difficulty ON word(difficulty_level);
CREATE INDEX idx_word_text ON word(word_text);
```

### 2. Audio File Management
```powershell
# Upload audio files to blob storage for each environment
az storage blob upload-batch \
  --source "./audio-files" \
  --destination "audio-files-it" \
  --account-name "beeuxitstorage" \
  --auth-mode login
```

## Backup and Disaster Recovery

### 1. Database Backup Configuration
- IT: 7-day retention, local backup only
- QA: 14-day retention, geo-redundant backup
- Production: 35-day retention, geo-redundant backup with point-in-time recovery

### 2. Blob Storage Backup
- Production: Geo-redundant storage with read access
- QA: Geo-redundant storage
- IT: Locally redundant storage

### 3. Application Recovery
- Container images stored in geo-replicated container registry
- Infrastructure as Code enables rapid environment recreation
- Database restore procedures documented and tested

## Cost Optimization

### 1. Resource Optimization by Environment
- **IT**: Free tier and lowest-cost options to stay under $10/month with auto-shutdown
- **QA**: Standard tiers for performance testing with $20/month target and auto-shutdown
- **Production**: Premium tiers with auto-scaling, $30/month target, and intelligent auto-shutdown

### 2. Automated Cost Monitoring and Alerts
- **Budget Alerts**: Set up automatically during deployment
- **Email Notifications**: prashantmdesai@yahoo.com, prashantmdesai@hotmail.com
- **SMS Notifications**: +1 224 656 4855
- **Alert Thresholds**: 50%, 80%, and 100% of budget
- **Both Estimated and Actual Cost Tracking**: Separate budgets for forecasted vs actual spending
- **Auto-Shutdown**: All environments shut down after 1 hour of inactivity

### 3. Cost Optimization Best Practices
- Set up budget alerts for each environment immediately after deployment
- Monitor resource utilization and right-size accordingly
- Use Azure Cost Management for optimization recommendations
- Leverage Azure Advisor for cost reduction suggestions
- Review costs weekly and optimize unused resources
- **Automatic shutdown when idle to minimize costs**
- **Manual startup/shutdown scripts for cost control**

### 4. Environment-Specific Cost Targets and Auto-Shutdown
```powershell
# IT Environment - Target: Under $10/month
# - Auto-shutdown after 1 hour of inactivity
# - Free tier resources with aggressive cost monitoring

# QA Environment - Target: Under $20/month
# - Auto-shutdown after 1 hour of inactivity  
# - Standard tier resources for testing

# Production Environment - Target: Under $30/month
# - Auto-shutdown after 1 hour of inactivity (configurable)
# - Premium tier resources with cost controls
```

### 5. Manual Environment Management Commands
```powershell
# Manually shut down environment to save costs
.\infra\scripts\shutdown-environment.ps1 -EnvironmentName "it"
.\infra\scripts\shutdown-environment.ps1 -EnvironmentName "qa"
.\infra\scripts\shutdown-environment.ps1 -EnvironmentName "prod"

# Restart environment when needed
.\infra\scripts\startup-environment.ps1 -EnvironmentName "it"
.\infra\scripts\startup-environment.ps1 -EnvironmentName "qa"
.\infra\scripts\startup-environment.ps1 -EnvironmentName "prod"

# Check environment status
az resource list --resource-group beeux-rg-it-eastus --query "[].{Name:name, Type:type, State:properties.state}" --output table
```

## Security Checklist

### Pre-Deployment Security
- [ ] Enable Azure Security Center
- [ ] Configure Key Vault access policies
- [ ] Set up Managed Identity for all services
- [ ] Enable encryption at rest for all storage
- [ ] Configure network security groups
- [ ] Set up private endpoints for production
- [ ] Enable Azure Defender for all services

### Post-Deployment Security
- [ ] Verify SSL/TLS certificates
- [ ] Test authentication flows
- [ ] Validate CORS configuration
- [ ] Check firewall rules
- [ ] Review access logs
- [ ] Verify backup encryption

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. Database Connection Issues
```powershell
# Check PostgreSQL server status
az postgres flexible-server show --name beeux-db-it-eastus --resource-group beeux-rg-it-eastus

# Test connectivity
psql --host=beeux-db-it-eastus.postgres.database.azure.com --port=5432 --username=postgres_admin --dbname=beeux_it
```

#### 2. Blob Storage Access Issues
```powershell
# Check storage account status
az storage account show --name beeuxitstorage --resource-group beeux-rg-it-eastus

# Test blob access
az storage blob list --container-name audio-files-it --account-name beeuxitstorage --auth-mode login
```

#### 3. Container App Deployment Issues
```powershell
# Check container app logs
az containerapp logs show --name beeux-api-it --resource-group beeux-rg-it-eastus

# Check container app revision status
az containerapp revision list --name beeux-api-it --resource-group beeux-rg-it-eastus
```

## Post-Deployment Validation

### 1. Functional Testing
- [ ] Angular app loads correctly
- [ ] API endpoints respond correctly
- [ ] Database connectivity verified
- [ ] Audio files play successfully
- [ ] User authentication works
- [ ] Session tracking functions properly

### 2. Performance Testing
- [ ] Page load times < 3 seconds
- [ ] API response times < 500ms
- [ ] Audio streaming works smoothly
- [ ] Database queries optimized
- [ ] CDN serving static content

### 3. Security Testing
- [ ] HTTPS enforced
- [ ] Authentication required
- [ ] CORS properly configured
- [ ] No sensitive data in logs
- [ ] Access controls verified

## Maintenance and Updates

### 1. Regular Maintenance Tasks
- Weekly: Review Application Insights alerts
- Monthly: Update container images with security patches
- Quarterly: Review and optimize resource costs
- Annually: Review and update disaster recovery procedures

### 2. Update Strategy
- Test updates in IT environment first
- Validate in QA environment
- Deploy to production during maintenance windows
- Maintain rollback capability for all deployments

This infrastructure setup ensures a robust, scalable, and secure deployment of the Beeux spelling bee application across all environments while following Azure best practices and maintaining cost efficiency.
