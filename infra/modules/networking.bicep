@description('Virtual network name')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name')
param environmentName string

@description('Enable private endpoints and advanced networking')
param enablePrivateEndpoints bool = false

@description('Tags for resources')
param tags object = {}

// Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateEndpointNetworkPolicies: enablePrivateEndpoints ? 'Enabled' : 'Disabled'
          privateLinkServiceNetworkPolicies: enablePrivateEndpoints ? 'Enabled' : 'Disabled'
        }
      }
      {
        name: 'container-apps'
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: [
            {
              name: 'Microsoft.App/environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      {
        name: 'app-gateway'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
      {
        name: 'private-endpoints'
        properties: {
          addressPrefix: '10.0.4.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// Public IP for Application Gateway (if WAF enabled)
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (enablePrivateEndpoints) {
  name: 'pip-appgw-${environmentName}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'beeux-appgw-${environmentName}-${uniqueString(resourceGroup().id)}'
    }
  }
}

// Outputs
output virtualNetworkId string = virtualNetwork.id
output virtualNetworkName string = virtualNetwork.name
output defaultSubnetId string = virtualNetwork.properties.subnets[0].id
output containerAppsSubnetId string = virtualNetwork.properties.subnets[1].id
output appGatewaySubnetId string = virtualNetwork.properties.subnets[2].id
output privateEndpointsSubnetId string = virtualNetwork.properties.subnets[3].id
output publicIPId string = enablePrivateEndpoints ? publicIP.id : ''
