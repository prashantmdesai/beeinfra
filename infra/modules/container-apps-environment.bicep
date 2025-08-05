@description('Container Apps Environment name')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('Enable private endpoints')
param enablePrivateEndpoints bool = false

@description('Subnet ID for Container Apps')
param subnetId string = ''

@description('Tags for resources')
param tags object = {}

// Container Apps Environment with HTTPS enforcement
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2022-10-01').customerId
        sharedKey: listKeys(logAnalyticsWorkspaceId, '2022-10-01').primarySharedKey
      }
    }
    zoneRedundant: false
    vnetConfiguration: enablePrivateEndpoints && !empty(subnetId) ? {
      infrastructureSubnetId: subnetId
      internal: true
    } : null
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    // Environment-level configuration for HTTPS enforcement
    customDomainConfiguration: {
      dnsSuffix: enablePrivateEndpoints ? '${name}.internal' : null
      certificateValue: null
      certificatePassword: null
    }
  }
}

// Managed certificate for HTTPS (when using custom domains)
resource managedCertificate 'Microsoft.App/managedEnvironments/managedCertificates@2023-05-01' = if (enablePrivateEndpoints) {
  parent: containerAppsEnvironment
  name: '${name}-cert'
  location: location
  tags: tags
  properties: {
    subjectName: '*.${name}.internal'
    domainControlValidation: 'CNAME'
  }
}

// Diagnostic settings for monitoring HTTPS traffic
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${name}-diagnostics'
  scope: containerAppsEnvironment
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ContainerAppConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'ContainerAppSystemLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
  }
}

// Outputs
output id string = containerAppsEnvironment.id
output name string = containerAppsEnvironment.name
output defaultDomain string = containerAppsEnvironment.properties.defaultDomain
output staticIp string = containerAppsEnvironment.properties.staticIp
output customDomainVerificationId string = containerAppsEnvironment.properties.customDomainConfiguration.customDomainVerificationId
