// =============================================================================
// DEV ENVIRONMENT - UBUNTU VM
// =============================================================================
// This Bicep template creates an Ubuntu VM specifically for the Dev environment
// Configuration based on user selections:
// - VM: Standard_B2s (2 vCPU, 4GB RAM)
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

@description('VM admin username')
param adminUsername string = 'beeuser'

@description('SSH public key for authentication')
@secure()
param sshPublicKey string

@description('Admin password for the VM')
@secure()
param adminPassword string

@description('VM size')
param vmSize string = 'Standard_B2s'

@description('OS disk size in GB')
param osDiskSizeGB int = 30

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

module networking 'modules/networking.bicep' = {
  scope: devResourceGroup
  name: 'dev-networking'
  params: {
    location: location
    environmentName: environmentName
    tags: tags
  }
}

// =============================================================================
// UBUNTU VM MODULE  
// =============================================================================

module ubuntuVM 'modules/ubuntu-vm.bicep' = {
  scope: devResourceGroup
  name: 'dev-ubuntu-vm'
  params: {
    location: location
    environmentName: environmentName
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    adminPassword: adminPassword
    vmSize: vmSize
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
output vmPublicIP string = ubuntuVM.outputs.publicIPAddress

@description('VM Private IP Address')
output vmPrivateIP string = ubuntuVM.outputs.privateIPAddress

@description('SSH Connection Command')
output sshCommand string = 'ssh ${adminUsername}@${ubuntuVM.outputs.publicIPAddress}'

@description('VM Resource ID')
output vmResourceId string = ubuntuVM.outputs.vmResourceId

@description('Estimated Monthly Cost')
output estimatedMonthlyCost string = '$40.16 (if running 24/7)'

@description('Cost Breakdown')
output costBreakdown object = {
  vmCompute: '$30.37/month (Standard_B2s)'
  storage: '$6.14/month (30GB Premium SSD)'
  publicIP: '$3.65/month (Static IP)'
  total: '$40.16/month'
  note: 'Costs shown for 24/7 operation. Actual costs depend on usage.'
}
