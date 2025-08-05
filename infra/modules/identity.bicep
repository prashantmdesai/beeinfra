@description('The name of the user-assigned managed identity')
param name string

@description('The location for the managed identity')
param location string

@description('Tags to apply to the resource')
param tags object = {}

// User-assigned managed identity
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

output id string = userAssignedIdentity.id
output principalId string = userAssignedIdentity.properties.principalId
output clientId string = userAssignedIdentity.properties.clientId
output name string = userAssignedIdentity.name
