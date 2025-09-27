// =============================================================================
// DATS-BEEUX-DEV VM1 - MAIN DEPLOYMENT TEMPLATE
// =============================================================================
// This Bicep template creates the dats-beeux-dev-data Ubuntu VM for data services
// Configuration:
// - VM: Standard_B2ms (2 vCPU, 8GB RAM)
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
param vmName string = 'dats-beeux-dev-data'

@description('VM admin username')
param adminUsername string = 'beeuser'

@description('VM size')
param vmSize string = 'Standard_B2ms'

@description('Availability Zone for the VM (1, 2, or 3)')
param availabilityZone string = '1'

@description('Existing OS disk resource ID from dev-scsm-vault VM (Zone 1)')
param existingOsDiskId string = '/subscriptions/d1f25f66-8914-4652-bcc4-8c6e0e0f1216/resourceGroups/beeinfra-dev-rg/providers/Microsoft.Compute/disks/dats-beeux-dev-data-osdisk-zone1'

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

module networking 'modules/dats-beeux-dev-vm1-networking.bicep' = {
  scope: devResourceGroup
  name: 'dats-beeux-dev-vm1-networking'
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

module ubuntuVM 'modules/dats-beeux-dev-vm1.bicep' = {
  scope: devResourceGroup
  name: 'dats-beeux-dev-vm1'
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
output estimatedMonthlyCost string = '$69.46 (if running 24/7)'

@description('Cost Breakdown')
output costBreakdown object = {
  vmCompute: '$59.67/month (Standard_B2ms)'
  storage: '$6.14/month (30GB Premium SSD)'
  publicIP: '$3.65/month (Static IP)'
  total: '$69.46/month'
  note: 'Costs shown for 24/7 operation. Actual costs depend on usage.'
}
