// =============================================================================
// DATS-BEEUX-DEV VM1 - NETWORKING MODULE
// =============================================================================
// Creates VNet, subnet, and NSG for the dats-beeux-dev VM1 Ubuntu VM
// =============================================================================

@description('Location for all resources')
param location string

@description('Environment name')
param environmentName string

@description('Tags for all resources')
param tags object

// =============================================================================
// VIRTUAL NETWORK
// =============================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-${environmentName}-${location}'
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
        name: 'subnet-${environmentName}-default'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

// =============================================================================
// NETWORK SECURITY GROUP
// =============================================================================

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-${environmentName}-ubuntu-vm'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1001
          direction: 'Inbound'
          description: 'Allow SSH access'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1002
          direction: 'Inbound'
          description: 'Allow HTTP access'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1003
          direction: 'Inbound'
          description: 'Allow HTTPS access'
        }
      }
      {
        name: 'AllowMySQL'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3306'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1004
          direction: 'Inbound'
          description: 'Allow MySQL database access'
        }
      }
      {
        name: 'AllowPostgreSQL'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5432'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1005
          direction: 'Inbound'
          description: 'Allow PostgreSQL database access'
        }
      }
      {
        name: 'AllowCustom8200'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8200'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1006
          direction: 'Inbound'
          description: 'Allow custom application on port 8200'
        }
      }
      {
        name: 'AllowCustom8888'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8888'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1007
          direction: 'Inbound'
          description: 'Allow custom application on port 8888'
        }
      }
      {
        name: 'AllowCustom8889'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8889'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1008
          direction: 'Inbound'
          description: 'Allow custom application on port 8889'
        }
      }
    ]
  }
}

// =============================================================================
// OUTPUTS
// =============================================================================

@description('Virtual Network ID')
output virtualNetworkId string = virtualNetwork.id

@description('Subnet ID')
output subnetId string = virtualNetwork.properties.subnets[0].id

@description('Network Security Group ID')
output networkSecurityGroupId string = networkSecurityGroup.id