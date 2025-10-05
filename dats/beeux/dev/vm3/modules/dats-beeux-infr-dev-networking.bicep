// =============================================================================
// DATS-BEEUX-INFR-DEV VM3 - NETWORKING MODULE (KUBERNETES MASTER)
// =============================================================================
// Reuses existing VNet and creates a new public IP for the Kubernetes master VM
// Adds Kubernetes-specific NSG rules to the existing NSG
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
// EXISTING RESOURCES (SHARED WITH VM1 AND VM2)
// =============================================================================

resource existingVNet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: 'vnet-${environmentName}-${location}'
}

resource existingNSG 'Microsoft.Network/networkSecurityGroups@2023-09-01' existing = {
  name: 'nsg-${environmentName}-ubuntu-vm'
}

// =============================================================================
// PUBLIC IP FOR NEW VM3
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
// KUBERNETES MASTER NSG RULES (ADDED TO EXISTING NSG)
// =============================================================================

resource kubernetesApiRule 'Microsoft.Network/networkSecurityGroups/securityRules@2023-09-01' = {
  parent: existingNSG
  name: 'AllowKubernetesAPI'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '6443'
    sourceAddressPrefix: '192.168.86.0/24'  // Your WiFi network
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 1023
    direction: 'Inbound'
    description: 'Allow Kubernetes API server access from your network'
  }
}

resource kubernetesEtcdRule 'Microsoft.Network/networkSecurityGroups/securityRules@2023-09-01' = {
  parent: existingNSG
  name: 'AllowKubernetesEtcd'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRanges: ['2379', '2380']
    sourceAddressPrefix: 'VirtualNetwork'  // Internal only
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 1024
    direction: 'Inbound'
    description: 'Allow etcd communication between Kubernetes nodes (internal only)'
  }
}

resource kubernetesKubeletRule 'Microsoft.Network/networkSecurityGroups/securityRules@2023-09-01' = {
  parent: existingNSG
  name: 'AllowKubernetesKubelet'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '10250'
    sourceAddressPrefix: 'VirtualNetwork'  // Internal only
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 1025
    direction: 'Inbound'
    description: 'Allow Kubelet API access between Kubernetes nodes (internal only)'
  }
}

resource kubernetesNodePortRule 'Microsoft.Network/networkSecurityGroups/securityRules@2023-09-01' = {
  parent: existingNSG
  name: 'AllowKubernetesNodePorts'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '30000-32767'
    sourceAddressPrefix: '192.168.86.0/24'  // Your WiFi network
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 1026
    direction: 'Inbound'
    description: 'Allow Kubernetes NodePort services from your network'
  }
}

// =============================================================================
// OUTPUTS
// =============================================================================

@description('Subnet ID (existing subnet reused)')
output subnetId string = existingVNet.properties.subnets[0].id

@description('Network Security Group ID (existing NSG reused)')
output nsgId string = existingNSG.id

@description('Public IP Address ID for VM3')
output publicIPId string = publicIP.id

@description('Public IP Address')
output publicIPAddress string = publicIP.properties.ipAddress

@description('Kubernetes API Server FQDN')
output kubernetesFQDN string = publicIP.properties.dnsSettings.fqdn
