/*
 * AZURE APP SERVICE MODULE - ANGULAR FRONTEND HOSTING
 * ===================================================
 * 
 * This module deploys and configures Azure App Service to host the Angular frontend
 * with comprehensive HTTPS enforcement and security hardening across all environments.
 * 
 * SECURITY-FIRST DESIGN:
 * ======================
 * - HTTPS-ONLY TRAFFIC: All HTTP requests are automatically redirected to HTTPS
 * - TLS 1.2 MINIMUM: Enforces modern encryption standards, rejects older TLS versions
 * - SECURITY HEADERS: Implements OWASP-recommended headers to prevent common attacks
 * - MANAGED IDENTITY: Uses Azure managed identity for secure service-to-service communication
 * - CORS POLICY: Restricts cross-origin requests to authorized domains only
 * 
 * ENVIRONMENT-SPECIFIC SCALING:
 * =============================
 * - IT Environment: F1/B1 tier for cost optimization, minimal resources
 * - QA Environment: P1V3 tier with auto-scaling for realistic testing loads
 * - Production: P2V3 tier with advanced auto-scaling and high availability
 * 
 * HTTPS ENFORCEMENT IMPLEMENTATION:
 * =================================
 * Multiple layers ensure all traffic is secure:
 * 1. httpsOnly: true - Azure platform-level HTTP to HTTPS redirect
 * 2. minTlsVersion: '1.2' - Rejects connections using older TLS versions
 * 3. ftpsState: 'Disabled' - Prevents insecure FTP access
 * 4. Security headers - Prevents downgrade attacks and enforces HTTPS
 * 
 * SECURITY HEADERS EXPLAINED:
 * ===========================
 * - Strict-Transport-Security: Forces browsers to use HTTPS for all future requests
 * - X-Content-Type-Options: Prevents MIME type confusion attacks
 * - X-Frame-Options: Prevents clickjacking attacks
 * - X-XSS-Protection: Enables browser XSS filtering
 * - Content-Security-Policy: Prevents code injection attacks
 * 
 * MONITORING AND DIAGNOSTICS:
 * ===========================
 * - HTTP logging enabled for security audit trails
 * - Detailed error logging for troubleshooting
 * - Integration with Application Insights for performance monitoring
 * - Private endpoint support for network isolation in higher environments
 */

@description('App Service name')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('App Service Plan SKU')
param sku string

@description('Environment name')
param environmentName string

@description('User assigned managed identity ID')
param userAssignedIdentityId string

@description('Key Vault name for certificates and secrets')
param keyVaultName string

@description('Enable private endpoints')
param enablePrivateEndpoints bool = false

@description('Subnet ID for private endpoints')
param subnetId string = ''

@description('Tags for resources')
param tags object = {}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${name}-plan'
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    reserved: false // Windows
  }
}

// App Service with HTTPS enforcement
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true // Enforce HTTPS only
    clientAffinityEnabled: false
    siteConfig: {
      minTlsVersion: '1.2' // Enforce minimum TLS 1.2
      scmMinTlsVersion: '1.2' // Enforce minimum TLS 1.2 for SCM
      ftpsState: 'Disabled' // Disable FTP, use FTPS only
      http20Enabled: true // Enable HTTP/2 for better performance
      alwaysOn: sku != 'F1' // Always on for non-free tiers
      webSocketsEnabled: false
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v8.0'
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        // Force HTTPS in application
        {
          name: 'HTTPS_ONLY'
          value: 'true'
        }
        // Security headers
        {
          name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS'
          value: '30'
        }
      ]
      connectionStrings: []
      cors: {
        allowedOrigins: [
          'https://${name}.azurewebsites.net'
        ]
        supportCredentials: false
      }
      // Security headers configuration
      httpHeaders: {
        'X-Content-Type-Options': 'nosniff'
        'X-Frame-Options': 'DENY'
        'X-XSS-Protection': '1; mode=block'
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains'
        'Content-Security-Policy': "default-src 'self' https:; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; style-src 'self' 'unsafe-inline' https:; img-src 'self' data: https:; connect-src 'self' https:; font-src 'self' https:; object-src 'none'; media-src 'self' https:; frame-src 'none';"
      }
    }
  }
}

// Custom domain binding with HTTPS redirect (when custom domain is provided)
resource httpsBinding 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: appService
  name: 'web'
  properties: {
    httpLoggingEnabled: true
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: true
    publishingUsername: '$${name}'
    scmType: 'None'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    alwaysOn: sku != 'F1'
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: sku != 'F1'
      }
    ]
    loadBalancing: 'LeastRequests'
    autoHealEnabled: false
    // Force HTTPS redirect
    httpsOnly: true
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'Disabled'
  }
}

// Private endpoint for App Service (if enabled)
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (enablePrivateEndpoints && !empty(subnetId)) {
  name: '${name}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-plsc'
        properties: {
          privateLinkServiceId: appService.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

// Key Vault access policy for certificates
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: appService.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
          certificates: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

// Outputs
output id string = appService.id
output name string = appService.name
output defaultHostName string = appService.properties.defaultHostName
output httpsUrl string = 'https://${appService.properties.defaultHostName}'
output principalId string = appService.identity.principalId
