// =============================================================================
// DATS-BEEUX-DATA-DEV VM1 - NETWORKING MODULE (KUBERNETES WORKER - DATA)
// =============================================================================
// Reuses existing VNet, subnet, and NSG
// Creates a new public IP for the data worker VM
// =============================================================================

@description('Location for all resources')
param location string

@description('Environment name')
param environmentName string

@description('VM name')
param vmName string

@description('Availability Zone for the VM')
param availabilityZone string

@description('Tags for all resources')
param tags object

// =============================================================================
// EXISTING RESOURCES (SHARED WITH ALL VMS)
// =============================================================================

resource existingVNet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: 'vnet-${environmentName}-${location}'
}

resource existingNSG 'Microsoft.Network/networkSecurityGroups@2023-09-01' existing = {
  name: 'nsg-${environmentName}-ubuntu-vm'
}

// =============================================================================
// PUBLIC IP FOR DATA VM
// =============================================================================

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${vmName}-pip'
  location: location
  tags: tags
  zones: [availabilityZone]
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: vmName
      fqdn: '${vmName}.${location}.cloudapp.azure.com'
    }
  }
}

// =============================================================================
// OUTPUTS
// =============================================================================

@description('Subnet ID (existing subnet reused)')
output subnetId string = existingVNet.properties.subnets[0].id

@description('Network Security Group ID (existing NSG reused)')
output nsgId string = existingNSG.id

@description('Public IP Address ID')
output publicIPId string = publicIP.id

@description('Public IP Address')
output publicIPAddress string = publicIP.properties.ipAddress

@description('VM FQDN')
output vmFQDN string = publicIP.properties.dnsSettings.fqdn
