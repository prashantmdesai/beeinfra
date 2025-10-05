// =============================================================================
// STANDARDIZED NETWORKING MODULE FOR VM3
// =============================================================================
// Reuses existing networking infrastructure with consistent naming
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
// EXISTING NETWORKING RESOURCES (SHARED)
// =============================================================================

// Use existing VNet and subnet (shared with VM1 and VM2)
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: 'vnet-${environmentName}-centralus'
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  parent: virtualNetwork
  name: 'subnet-${environmentName}-default'
}

// Use existing NSG (shared with VM1 and VM2)
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' existing = {
  name: 'nsg-${environmentName}-ubuntu-vm'
}

// Add VM3-specific NSG rules for Kubernetes master
resource kubernetesApiRule 'Microsoft.Network/networkSecurityGroups/securityRules@2023-09-01' = {
  parent: networkSecurityGroup
  name: 'AllowKubernetesAPI-VM3'
  properties: {
    description: 'Allow Kubernetes API server access for VM3 master node'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '6443'
    sourceAddressPrefix: '10.0.1.0/24'  // Allow from same subnet
    destinationAddressPrefix: '10.0.1.6'  // VM3 private IP
    access: 'Allow'
    priority: 1100
    direction: 'Inbound'
  }
}

resource kubernetesEtcdRule 'Microsoft.Network/networkSecurityGroups/securityRules@2023-09-01' = {
  parent: networkSecurityGroup
  name: 'AllowKubernetesEtcd-VM3'
  properties: {
    description: 'Allow etcd communication for VM3 Kubernetes master'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRanges: ['2379', '2380']
    sourceAddressPrefix: '10.0.1.0/24'  // Allow from same subnet
    destinationAddressPrefix: '10.0.1.6'  // VM3 private IP
    access: 'Allow'
    priority: 1101
    direction: 'Inbound'
  }
}

resource kubernetesKubeletRule 'Microsoft.Network/networkSecurityGroups/securityRules@2023-09-01' = {
  parent: networkSecurityGroup
  name: 'AllowKubernetesKubelet-VM3'
  properties: {
    description: 'Allow kubelet API access for VM3 Kubernetes master'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRanges: ['10250', '10257', '10259']
    sourceAddressPrefix: '10.0.1.0/24'  // Allow from same subnet
    destinationAddressPrefix: '10.0.1.6'  // VM3 private IP
    access: 'Allow'
    priority: 1102
    direction: 'Inbound'
  }
}

// =============================================================================
// OUTPUTS
// =============================================================================

@description('Subnet Resource ID')
output subnetId string = subnet.id

@description('Network Security Group Resource ID')
output nsgId string = networkSecurityGroup.id

@description('Virtual Network Resource ID')
output vnetId string = virtualNetwork.id

@description('VM3 Network Configuration')
output networkConfiguration object = {
  vnetName: virtualNetwork.name
  subnetName: subnet.name
  nsgName: networkSecurityGroup.name
  privateIpAddress: '10.0.1.6'
  subnetRange: '10.0.1.0/24'
  kubernetesRulesAdded: true
}