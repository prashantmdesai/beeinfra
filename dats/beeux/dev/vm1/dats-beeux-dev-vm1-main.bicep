// =============================================================================
// DATS-BEEUX-DEV VM1 - MAIN DEPLOYMENT TEMPLATE
// =============================================================================
// This Bicep template creates the dats-beeux-dev VM1 Ubuntu VM for development
// Configuration:
// - VM: Standard_B4ms (4 vCPU, 16GB RAM)
// - Storage: 30GB Premium SSD
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
param vmName string = 'dats-beeux-dev'

@description('VM admin username')
param adminUsername string = 'beeuser'

@description('VM size')
param vmSize string = 'Standard_B4ms'

@description('Availability Zone for the VM (1, 2, or 3)')
param availabilityZone string = '2'

@description('Existing OS disk resource ID from dev-scsm-vault VM')
param existingOsDiskId string = '/subscriptions/f82e8e5e-cf53-4ef7-b717-dacc295d4ee4/resourceGroups/beeinfra-dev-rg/providers/Microsoft.Compute/disks/dev-scsm-vault_OsDisk_1_b230a675a9f34aaaa7f750e7d041b061'

@description('Tags for all resources')
param tags object = {
  Environment: 'Dev'
  Project: 'BeeInfra'
  Owner: 'DevTeam'
  CostCenter: 'Development'
  CreatedBy: 'Bicep'
}

// =============================================================================
// RESOURCE GROUP
// =============================================================================

resource devResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-${environmentName}-eastus'
  location: location
  tags: tags
}

// =============================================================================
// NETWORKING MODULE
// =============================================================================

module networking 'modules/dats-beeux-dev-networking.bicep' = {
  scope: devResourceGroup
  name: 'dats-beeux-dev-networking'
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

module ubuntuVM 'modules/dats-beeux-dev-vm.bicep' = {
  scope: devResourceGroup
  name: 'dats-beeux-dev-vm'
  params: {
    location: location
    vmName: vmName
    adminUsername: adminUsername
    vmSize: vmSize
    availabilityZone: availabilityZone
    existingOsDiskId: existingOsDiskId
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
output estimatedMonthlyCost string = '$128.91 (if running 24/7)'

@description('Cost Breakdown')
output costBreakdown object = {
  vmCompute: '$119.20/month (Standard_B4ms)'
  storage: '$6.14/month (30GB Premium SSD)'
  publicIP: '$3.65/month (Static IP)'
  total: '$128.91/month'
  note: 'Costs shown for 24/7 operation. Actual costs depend on usage.'
}
