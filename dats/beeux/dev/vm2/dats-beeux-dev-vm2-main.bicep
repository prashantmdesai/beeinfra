// =============================================================================
// DATS-BEEUX-DEV VM2 - MAIN DEPLOYMENT TEMPLATE
// =============================================================================
// This Bicep template creates the dats-beeux-dev VM2 Ubuntu VM for development
// Configuration:
// - VM: Standard_B4ms (4 vCPU, 16GB RAM)
// - Storage: 30GB Premium SSD (NEW DISK - Cannot share with VM1)
// - Network: Static Public IP
// - Ports: SSH, HTTP, HTTPS, Database
// - OS: Ubuntu 24.04 LTS
// =============================================================================

targetScope = 'subscription'

@description('Location for all resources')
param location string = 'eastus'

@description('Environment name')
param environmentName string = 'dev'

@description('VM name')
param vmName string = 'dats-beeux-dev-apps'

@description('VM admin username')
param adminUsername string = 'beeuser'

@description('VM admin password (required for new VM)')
@secure()
param adminPassword string

@description('SSH public key for authentication')
param sshPublicKey string = ''

@description('VM size')
param vmSize string = 'Standard_B2ms'

@description('Availability Zone for the VM (1, 2, or 3)')
param availabilityZone string = '1'

@description('OS disk size in GB')
param osDiskSizeGB int = 30

@description('Tags for all resources')
param tags object = {
  Environment: 'Dev'
  Project: 'BeeInfra'
  Owner: 'DevTeam'
  CostCenter: 'Development'
  CreatedBy: 'Bicep'
  VMInstance: 'VM2'
}

// =============================================================================
// RESOURCE GROUP (Use existing or create new)
// =============================================================================

resource devResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: 'rg-${environmentName}-eastus'
}

// =============================================================================
// NETWORKING MODULE (Use existing networking from VM1)
// =============================================================================

// Reference existing networking resources from VM1
module networking 'modules/dats-beeux-dev-vm2-networking.bicep' = {
  scope: devResourceGroup
  name: 'dats-beeux-dev-vm2-networking'
  params: {
    location: location
    environmentName: environmentName
    allowedSourceIP: '192.168.86.0/24'
    tags: tags
  }
}

// =============================================================================
// UBUNTU VM MODULE  
// =============================================================================

module ubuntuVM 'modules/dats-beeux-dev-vm2.bicep' = {
  scope: devResourceGroup
  name: 'dats-beeux-dev-vm2'
  params: {
    location: location
    vmName: vmName
    adminUsername: adminUsername
    adminPassword: adminPassword
    sshPublicKey: sshPublicKey
    vmSize: vmSize
    availabilityZone: availabilityZone
    osDiskSizeGB: osDiskSizeGB
    subnetId: networking.outputs.subnetId
    tags: tags
  }
}

// =============================================================================
// OUTPUTS
// =============================================================================

@description('Resource Group Name')
output resourceGroupName string = devResourceGroup.name

@description('VM Public IP Address')
output vmPublicIP string = ubuntuVM.outputs.publicIpAddress

@description('VM Private IP Address')
output vmPrivateIP string = ubuntuVM.outputs.privateIpAddress

@description('SSH Connection Command')
output sshCommand string = 'ssh ${adminUsername}@${ubuntuVM.outputs.publicIpAddress}'

@description('VM Resource ID')
output vmResourceId string = ubuntuVM.outputs.vmId

@description('Estimated Monthly Cost')
output estimatedMonthlyCost string = '$69.46 (if running 24/7)'

@description('Cost Breakdown')
output costBreakdown object = {
  vmCompute: '$59.67/month (Standard_B2ms)'
  storage: '$6.14/month (30GB Premium SSD)'
  publicIP: '$3.65/month (Static IP)'
  total: '$69.46/month'
  note: 'Costs shown for 24/7 operation. Actual costs depend on usage.'
}

@description('Combined VM1 + VM2 Monthly Cost')
output combinedMonthlyCost string = '$138.92 (both VMs running 24/7)'

@description('Combined Cost Breakdown')
output combinedCostBreakdown object = {
  vm1Compute: '$59.67/month (Standard_B2ms)'
  vm1Storage: '$6.14/month (30GB Premium SSD)'
  vm1PublicIP: '$3.65/month (Static IP)'
  vm2Compute: '$59.67/month (Standard_B2ms)'
  vm2Storage: '$6.14/month (30GB Premium SSD)'
  vm2PublicIP: '$3.65/month (Static IP)'
  totalCombined: '$138.92/month'
  savingsNote: 'No disk sharing possible - each VM requires separate disk'
}