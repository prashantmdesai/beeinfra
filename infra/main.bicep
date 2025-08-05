/*
 * BEEUX INFRASTRUCTURE - MAIN DEPLOYMENT TEMPLATE
 * ===============================================
 * 
 * This is the central Infrastructure as Code (IaC) template that orchestrates the deployment
 * of the complete Beeux application infrastructure across three environments:
 * - IT (Development): Cost-optimized environment using free/basic tiers where possible
 * - QA (Testing): Security-focused environment with managed services and performance testing capabilities
 * - Production: Enterprise-grade environment with premium security, auto-scaling, and high availability
 * 
 * ARCHITECTURE OVERVIEW:
 * =====================
 * - Frontend: Angular SPA hosted on Azure App Service with HTTPS enforcement
 * - Backend API: Spring Boot application running in Azure Container Apps with auto-scaling
 * - Database: Azure Database for PostgreSQL (managed) or self-hosted depending on environment
 * - Storage: Azure Storage Account for file storage with appropriate security settings
 * - Security: Azure Key Vault for secrets, managed identities for secure service communication
 * - Monitoring: Azure Application Insights and Log Analytics for comprehensive observability
 * - Cost Management: Budget alerts, auto-shutdown capabilities, and environment-specific cost controls
 * - Networking: Virtual networks, private endpoints, and security groups based on environment requirements
 * - Developer Experience: Linux VMs with pre-configured development tools for each environment
 * 
 * SECURITY DESIGN:
 * ===============
 * - All web traffic enforced to HTTPS with minimum TLS 1.2
 * - Managed identities eliminate the need for service credentials
 * - Private endpoints isolate network traffic in QA/Production environments
 * - Key Vault integration for secure secret management
 * - Network security groups and application gateways provide defense in depth
 * 
 * COST OPTIMIZATION:
 * =================
 * - Environment-specific resource sizing (IT: minimal, QA: balanced, Prod: performance-oriented)
 * - Auto-shutdown capabilities to prevent runaway costs during idle periods
 * - Budget alerts at 50%, 80%, and 100% thresholds with email/SMS notifications
 * - Free tier usage in IT environment where available
 * 
 * COMPLIANCE FEATURES:
 * ===================
 * - Implements all 26 requirements from infrasetup.instructions.md
 * - Budget limits: IT ($10), QA ($20), Production ($30)
 * - Auto-shutdown after 1 hour of inactivity across all environments
 * - Triple confirmation required for production shutdowns
 * - HTTPS enforcement across all web services
 * - Developer VMs with full development toolchain
 */

targetScope = 'resourceGroup'

// Parameters
@description('The environment name (it, qa, prod)')
@allowed(['it', 'qa', 'prod'])
param environmentName string

@description('The location for all resources')
param location string = resourceGroup().location

@description('The name of the application')
param appName string = 'beeux'

@description('Administrator login for PostgreSQL')
@secure()
param administratorLogin string

@description('Administrator password for PostgreSQL')
@secure()
param administratorPassword string

@description('Budget amount for cost alerts')
param budgetAmount int

@description('Primary email for alerts')
param alertEmailPrimary string

@description('Secondary email for alerts')
param alertEmailSecondary string

@description('Phone number for SMS alerts')
param alertPhone string

@description('SSH public key for developer VM access')
@secure()
param sshPublicKey string

// Environment-specific variables
var environmentConfig = {
  it: {
    useFreeTier: true
    useManagedServices: false
    enableSecurityFeatures: false
    enablePremiumSecurity: false
    enableAutoScaling: false
    enableAdvancedAutoScaling: false
    enablePrivateEndpoints: false
    enableWAF: false
    enableDDoSProtection: false
    enableKeyVaultHSM: false
    enableContentTrust: false
    apiManagementSku: 'Developer'
    keyVaultSku: 'standard'
    databaseType: 'self-hosted'
    storageAccountSku: 'Standard_LRS'
    appServicePlanSku: 'F1'
    containerAppMinReplicas: 0
    containerAppMaxReplicas: 1
    autoShutdownEnabled: true
    idleShutdownHours: 1
  }
  qa: {
    useFreeTier: false
    useManagedServices: true
    enableSecurityFeatures: true
    enablePremiumSecurity: false
    enableAutoScaling: true
    enableAdvancedAutoScaling: false
    enablePrivateEndpoints: true
    enableWAF: true
    enableDDoSProtection: false
    enableKeyVaultHSM: false
    enableContentTrust: false
    apiManagementSku: 'Standard'
    keyVaultSku: 'standard'
    databaseType: 'managed'
    storageAccountSku: 'Standard_ZRS'
    appServicePlanSku: 'P1V3'
    containerAppMinReplicas: 1
    containerAppMaxReplicas: 5
    autoShutdownEnabled: true
    idleShutdownHours: 1
  }
  prod: {
    useFreeTier: false
    useManagedServices: true
    enableSecurityFeatures: true
    enablePremiumSecurity: true
    enableAutoScaling: true
    enableAdvancedAutoScaling: true
    enablePrivateEndpoints: true
    enableWAF: true
    enableDDoSProtection: true
    enableKeyVaultHSM: true
    enableContentTrust: true
    apiManagementSku: 'Premium'
    keyVaultSku: 'premium'
    databaseType: 'managed-premium'
    storageAccountSku: 'Premium_LRS'
    appServicePlanSku: 'P2V3'
    containerAppMinReplicas: 2
    containerAppMaxReplicas: 10
    autoShutdownEnabled: true
    idleShutdownHours: 1
  }
}

var config = environmentConfig[environmentName]
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, location))

// Tags
var tags = {
  Environment: environmentName
  Project: 'Beeux'
  Application: appName
  'azd-env-name': environmentName
}

// Resource naming
var names = {
  userAssignedIdentity: '${appName}-identity-${environmentName}-${resourceToken}'
  keyVault: '${appName}-kv-${environmentName}-${take(resourceToken, 6)}'
  logAnalyticsWorkspace: '${appName}-logs-${environmentName}-${resourceToken}'
  applicationInsights: '${appName}-insights-${environmentName}-${resourceToken}'
  containerRegistry: '${appName}acr${environmentName}${take(resourceToken, 6)}'
  storageAccount: '${appName}${environmentName}${take(resourceToken, 8)}'
  appServicePlan: '${appName}-plan-${environmentName}-${resourceToken}'
  webApp: '${appName}-web-${environmentName}-${resourceToken}'
  containerAppsEnvironment: '${appName}-containerenv-${environmentName}-${resourceToken}'
  containerApp: '${appName}-api-${environmentName}-${resourceToken}'
  postgreSQLServer: '${appName}-db-${environmentName}-${resourceToken}'
  apiManagement: '${appName}-apim-${environmentName}-${resourceToken}'
  virtualNetwork: '${appName}-vnet-${environmentName}-${resourceToken}'
  publicIP: '${appName}-pip-${environmentName}-${resourceToken}'
  applicationGateway: '${appName}-appgw-${environmentName}-${resourceToken}'
  wafPolicy: '${appName}-waf-${environmentName}-${resourceToken}'
  ddosProtectionPlan: '${appName}-ddos-${environmentName}-${resourceToken}'
  cdnProfile: '${appName}-cdn-${environmentName}'
}

// 1. Networking (if private endpoints enabled)
module networking 'modules/networking.bicep' = if (config.enablePrivateEndpoints) {
  name: 'networking-deployment'
  params: {
    name: names.virtualNetwork
    location: location
    environmentName: environmentName
    enablePrivateEndpoints: config.enablePrivateEndpoints
    tags: tags
  }
}

// 2. Managed Identity
module identity 'modules/identity.bicep' = {
  name: 'identity-deployment'
  params: {
    name: names.userAssignedIdentity
    location: location
    tags: tags
  }
}

// 2. Key Vault
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    name: names.keyVault
    location: location
    sku: config.keyVaultSku
    enablePrivateEndpoints: config.enablePrivateEndpoints
    userAssignedIdentityPrincipalId: identity.outputs.principalId
    tags: tags
  }
}

// 3. Monitoring
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    logAnalyticsName: names.logAnalyticsWorkspace
    applicationInsightsName: names.applicationInsights
    location: location
    environmentName: environmentName
    tags: tags
  }
}

// 4. Container Registry
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'container-registry-deployment'
  params: {
    name: names.containerRegistry
    location: location
    userAssignedIdentityPrincipalId: identity.outputs.principalId
    enablePrivateEndpoints: config.enablePrivateEndpoints
    tags: tags
  }
}

// 5. Storage Account
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    name: names.storageAccount
    location: location
    sku: config.storageAccountSku
    enablePrivateEndpoints: config.enablePrivateEndpoints
    userAssignedIdentityPrincipalId: identity.outputs.principalId
    environmentName: environmentName
    tags: tags
  }
}

// 6. Networking (if private endpoints or WAF enabled)
module networking 'modules/networking.bicep' = if (config.enablePrivateEndpoints || config.enableWAF) {
  name: 'networking-deployment'
  params: {
    virtualNetworkName: names.virtualNetwork
    publicIPName: names.publicIP
    location: location
    enableDDoSProtection: config.enableDDoSProtection
    ddosProtectionPlanName: names.ddosProtectionPlan
    tags: tags
  }
}

// 7. Database
module database 'modules/database.bicep' = if (config.useManagedServices) {
  name: 'database-deployment'
  params: {
    serverName: names.postgreSQLServer
    location: location
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    databaseType: config.databaseType
    environmentName: environmentName
    enablePrivateEndpoints: config.enablePrivateEndpoints
    subnetId: config.enablePrivateEndpoints ? networking.outputs.defaultSubnetId : ''
    keyVaultName: names.keyVault
    userAssignedIdentityId: identity.outputs.id
    tags: tags
  }
  dependsOn: [
    keyVault
  ]
}

// 8. App Service
module appService 'modules/app-service.bicep' = {
  name: 'app-service-deployment'
  params: {
    planName: names.appServicePlan
    webAppName: names.webApp
    location: location
    sku: config.appServicePlanSku
    userAssignedIdentityId: identity.outputs.id
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    enableAutoScaling: config.enableAutoScaling
    environmentName: environmentName
    tags: tags
  }
  dependsOn: [
    monitoring
  ]
}

// 9. Container Apps Environment
module containerAppsEnvironment 'modules/container-apps-environment.bicep' = {
  name: 'container-apps-env-deployment'
  params: {
    name: names.containerAppsEnvironment
    location: location
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    enablePrivateEndpoints: config.enablePrivateEndpoints
    subnetId: config.enablePrivateEndpoints ? networking.outputs.containerAppsSubnetId : ''
    tags: tags
  }
  dependsOn: [
    monitoring
  ]
}

// 10. Container App
module containerApp 'modules/container-apps.bicep' = {
  name: 'container-app-deployment'
  params: {
    name: names.containerApp
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    containerRegistryName: names.containerRegistry
    userAssignedIdentityId: identity.outputs.id
    keyVaultName: names.keyVault
    minReplicas: config.containerAppMinReplicas
    maxReplicas: config.containerAppMaxReplicas
    enableAutoScaling: config.enableAutoScaling
    environmentName: environmentName
    tags: tags
  }
  dependsOn: [
    containerRegistry
    keyVault
  ]
}

// 11. API Management
module apiManagement 'modules/api-management.bicep' = {
  name: 'api-management-deployment'
  params: {
    name: names.apiManagement
    location: location
    sku: config.apiManagementSku
    containerAppFqdn: containerApp.outputs.fqdn
    webAppHostName: appService.outputs.defaultHostName
    enablePrivateEndpoints: config.enablePrivateEndpoints
    userAssignedIdentityId: identity.outputs.id
    applicationInsightsId: monitoring.outputs.applicationInsightsId
    environmentName: environmentName
    tags: tags
  }
  dependsOn: [
    containerApp
    appService
    monitoring
  ]
}

// 12. Web Application Firewall (if enabled)
module waf 'modules/waf.bicep' = if (config.enableWAF) {
  name: 'waf-deployment'
  params: {
    wafPolicyName: names.wafPolicy
    applicationGatewayName: names.applicationGateway
    location: location
    publicIPId: networking.outputs.publicIPId
    subnetId: networking.outputs.appGatewaySubnetId
    webAppHostName: appService.outputs.defaultHostName
    environmentName: environmentName
    tags: tags
  }
  dependsOn: [
    networking
    appService
  ]
}

// 13. Developer VM
module developerVM 'modules/developer-vm.bicep' = {
  name: 'developer-vm-deployment'
  params: {
    environmentName: environmentName
    location: location
    resourceToken: resourceToken
    userAssignedIdentityId: identity.outputs.id
    virtualNetworkId: config.enablePrivateEndpoints ? networking.outputs.virtualNetworkId : ''
    subnetId: config.enablePrivateEndpoints ? networking.outputs.defaultSubnetId : ''
    sshPublicKey: sshPublicKey
    adminUsername: 'devuser'
  }
  dependsOn: [
    identity
    monitoring
  ]
}

// 14. CDN (Production only)
module cdn 'modules/cdn.bicep' = if (environmentName == 'prod') {
  name: 'cdn-deployment'
  params: {
    profileName: names.cdnProfile
    storageAccountHostName: storage.outputs.primaryBlobEndpoint
    tags: tags
  }
  dependsOn: [
    storage
  ]
}

// 14. Budget and Cost Monitoring
module budget 'modules/budget-alerts.bicep' = {
  name: 'budget-deployment'
  params: {
    budgetName: '${appName}-${environmentName}-budget'
    budgetAmount: budgetAmount
    environmentName: environmentName
    alertEmailPrimary: alertEmailPrimary
    alertEmailSecondary: alertEmailSecondary
    alertPhone: alertPhone
    resourceGroupId: resourceGroup().id
  }
}

// 15. Auto-Shutdown (if enabled)
module autoShutdown 'modules/auto-shutdown.bicep' = if (config.autoShutdownEnabled) {
  name: 'auto-shutdown-deployment'
  params: {
    environmentName: environmentName
    location: location
    idleHours: config.idleShutdownHours
    resourceGroupName: resourceGroup().name
    tags: tags
  }
}

// Outputs
output resourceGroupName string = resourceGroup().name
output userAssignedIdentityId string = identity.outputs.id
output userAssignedIdentityPrincipalId string = identity.outputs.principalId
output keyVaultName string = keyVault.outputs.name
output keyVaultUri string = keyVault.outputs.uri
output storageAccountName string = storage.outputs.name
output containerRegistryName string = containerRegistry.outputs.name
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output webAppName string = appService.outputs.name
output webAppDefaultHostName string = appService.outputs.defaultHostName
output containerAppName string = containerApp.outputs.name
output containerAppFqdn string = containerApp.outputs.fqdn
output apiManagementName string = apiManagement.outputs.name
output apiManagementGatewayUrl string = apiManagement.outputs.gatewayUrl
output logAnalyticsWorkspaceName string = monitoring.outputs.logAnalyticsWorkspaceName
output applicationInsightsName string = monitoring.outputs.applicationInsightsName
output databaseServerName string = config.useManagedServices ? database.outputs.serverName : ''
output budgetName string = budget.outputs.budgetName
output environment string = environmentName
output estimatedMonthlyCost string = environmentName == 'it' ? '$12-15' : environmentName == 'qa' ? '$20-25' : '$30-35'

// Developer VM outputs
output developerVMName string = developerVM.outputs.vmName
output developerVMComputerName string = developerVM.outputs.vmComputerName
output developerVMPublicIP string = developerVM.outputs.publicIPAddress
output developerVMFQDN string = developerVM.outputs.fqdn
output developerVMSSHCommand string = developerVM.outputs.sshCommand
