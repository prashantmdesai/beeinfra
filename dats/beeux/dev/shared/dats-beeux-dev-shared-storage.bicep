// =============================================================================
// DATS-BEEUX-DEV - SHARED STORAGE MODULE
// =============================================================================
// Creates Azure Files storage for file sharing between VMs
// Cost: ~$6-15/month for 100GB (depending on performance tier)
// =============================================================================

@description('Environment name')
param environmentName string

@description('Tags for all resources')
param tags object

@description('Location for resources')
param location string = resourceGroup().location

@description('Storage account performance tier (Standard_LRS for cost-effective, Premium_LRS for high performance)')
@allowed(['Standard_LRS', 'Standard_ZRS', 'Premium_LRS'])
param storageAccountSku string = 'Standard_LRS'

@description('Storage account tier (Standard or Premium)')
@allowed(['Standard', 'Premium'])
param storageAccountTier string = 'Standard'

@description('File share quota in GB (minimum 5GB)')
@minValue(5)
@maxValue(102400)
param fileShareQuotaGB int = 100

// =============================================================================
// STORAGE ACCOUNT
// =============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stdatsbeeux${environmentName}shared'
  location: location
  tags: tags
  sku: {
    name: storageAccountSku
  }
  kind: storageAccountTier == 'Premium' ? 'FileStorage' : 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Allow' // Can be restricted to VNet only for better security
    }
  }
}

// =============================================================================
// FILE SERVICES
// =============================================================================

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

// =============================================================================
// FILE SHARES
// =============================================================================

// Shared data directory for inter-VM file exchange
resource sharedDataFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  parent: fileServices
  name: 'shared-data'
  properties: {
    shareQuota: fileShareQuotaGB
    enabledProtocols: storageAccountTier == 'Premium' ? 'NFS' : 'SMB'
    accessTier: storageAccountTier == 'Standard' ? 'TransactionOptimized' : null
  }
}

// Configuration files share
resource configFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  parent: fileServices
  name: 'config-files'
  properties: {
    shareQuota: 50 // Smaller quota for config files
    enabledProtocols: storageAccountTier == 'Premium' ? 'NFS' : 'SMB'
    accessTier: storageAccountTier == 'Standard' ? 'TransactionOptimized' : null
  }
}

// Logs and temporary files share
resource logsFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  parent: fileServices
  name: 'logs-temp'
  properties: {
    shareQuota: 200 // Larger quota for logs
    enabledProtocols: storageAccountTier == 'Premium' ? 'NFS' : 'SMB'
    accessTier: storageAccountTier == 'Standard' ? 'Hot' : null
  }
}

// =============================================================================
// OUTPUTS
// =============================================================================

@description('Storage Account ID')
output storageAccountId string = storageAccount.id

@description('Storage Account Name')
output storageAccountName string = storageAccount.name

@description('File Share Names')
output fileShareNames object = {
  sharedData: 'shared-data'
  configFiles: 'config-files'
  logsTemp: 'logs-temp'
}

@description('Storage Account FQDN')
output storageAccountFqdn string = '${storageAccount.name}.file.${environment().suffixes.storage}'

@description('File Share Mount Points (use with Azure CLI or storage keys)')
output fileShareMountInstructions string = 'Use: az storage file upload/download commands or mount with storage account keys retrieved separately for security'
