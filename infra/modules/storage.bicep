@description('The name of the storage account')
param name string

@description('The location for the storage account')
param location string

@description('The SKU for the storage account')
@allowed(['Standard_LRS', 'Standard_ZRS', 'Premium_LRS'])
param sku string = 'Standard_LRS'

@description('Whether to enable private endpoints')
param enablePrivateEndpoints bool = false

@description('Principal ID of the user-assigned managed identity')
param userAssignedIdentityPrincipalId string

@description('The environment name')
param environmentName string

@description('Tags to apply to the resource')
param tags object = {}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: startsWith(sku, 'Premium') ? 'BlockBlobStorage' : 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: environmentName == 'it' ? true : false
    minimumTlsVersion: 'TLS1_2' // Enforce minimum TLS 1.2
    supportsHttpsTrafficOnly: true // Enforce HTTPS only - reject HTTP requests
    allowSharedKeyAccess: environmentName == 'it' ? true : false
    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
    networkAcls: enablePrivateEndpoints ? {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    } : {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
      requireInfrastructureEncryption: environmentName == 'prod' ? true : false
    }
    networkAcls: enablePrivateEndpoints ? {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    } : {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Blob service
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: environmentName == 'prod' ? 90 : 30
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: environmentName == 'prod' ? 90 : 30
    }
    versioning: {
      enabled: environmentName == 'prod' ? true : false
    }
    changeFeed: {
      enabled: environmentName == 'prod' ? true : false
      retentionInDays: environmentName == 'prod' ? 90 : null
    }
  }
}

// Audio files container
resource audioFilesContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'audio-files-${environmentName}'
  properties: {
    publicAccess: 'None'
  }
}

// Role assignment for managed identity - Storage Blob Data Contributor
resource storageBlobContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, userAssignedIdentityPrincipalId, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: userAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output id string = storageAccount.id
output name string = storageAccount.name
output primaryBlobEndpoint string = replace(replace(storageAccount.properties.primaryEndpoints.blob, 'https://', ''), '/', '')
output primaryBlobEndpointUrl string = storageAccount.properties.primaryEndpoints.blob
output primaryConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
