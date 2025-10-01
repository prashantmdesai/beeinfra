// =============================================================================
// DATS-BEEUX-DEV VM2 - NETWORKING MODULE
// =============================================================================
// Creates/references networking components for VM2
// Note: VM2 will use the existing VNet and NSG from VM1 but get its own Public IP
// =============================================================================

@description('Location for all resources')
param location string

@description('Environment name')
param environmentName string

@description('Allowed source IP address or CIDR block')
param allowedSourceIP string = '192.168.86.0/24'

@description('Tags for all resources')
param tags object

// =============================================================================
// REFERENCE EXISTING VNet AND NSG FROM VM1
// =============================================================================

// Reference existing VNet (created by VM1)
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: 'vnet-${environmentName}-${location}'
}

// Reference existing subnet (created by VM1)
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  parent: vnet
  name: 'subnet-${environmentName}-default'
}

// Reference existing NSG (created by VM1)
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' existing = {
  name: 'nsg-${environmentName}-ubuntu-vm'
}

// =============================================================================
// OUTPUTS
// =============================================================================

@description('Virtual Network Resource ID')
output vnetId string = vnet.id

@description('Subnet Resource ID') 
output subnetId string = subnet.id

@description('Network Security Group Resource ID')
output nsgId string = nsg.id

@description('Virtual Network Name')
output vnetName string = vnet.name

@description('Subnet Name')
output subnetName string = subnet.name

@description('Network Security Group Name')
output nsgName string = nsg.name

@description('Network Configuration')
output networkConfig object = {
  vnet: {
    name: vnet.name
    addressSpace: vnet.properties.addressSpace.addressPrefixes[0]
    location: vnet.location
  }
  subnet: {
    name: subnet.name
    addressPrefix: subnet.properties.addressPrefix
  }
  nsg: {
    name: nsg.name
    rulesCount: length(nsg.properties.securityRules)
  }
  note: 'VM2 reuses existing network infrastructure from VM1'
}
