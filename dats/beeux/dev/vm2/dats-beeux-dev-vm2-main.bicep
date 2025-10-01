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
param location string = 'centralus'

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
param vmSize string = 'Standard_B4ms'

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
  name: 'rg-${environmentName}-centralus'
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
output estimatedMonthlyCost string = '$129.46 (if running 24/7) - Central US'

@description('Cost Breakdown')
output costBreakdown object = {
  vmCompute: '$119.67/month (Standard_B4ms - 4 vCPU, 16GB RAM - Central US)'
  storage: '$6.14/month (30GB Premium SSD)'
  publicIP: '$3.65/month (Static IP)'
  total: '$129.46/month'
  note: 'Costs shown for 24/7 operation. Standard_B4ms pricing same across regions.'
}

@description('Combined VM1 + VM2 Monthly Cost')
output combinedMonthlyCost string = '$190.75 (both VMs running 24/7) - Central US'

@description('Combined Cost Breakdown')
output combinedCostBreakdown object = {
  vm1Compute: '$51.50/month (Standard_B2ms - Data VM - Central US savings)'
  vm1Storage: '$6.14/month (30GB Premium SSD)'
  vm1PublicIP: '$3.65/month (Static IP)'
  vm2Compute: '$119.67/month (Standard_B4ms - Apps VM with 4 vCPU, 16GB RAM)'
  vm2Storage: '$6.14/month (30GB Premium SSD)'
  vm2PublicIP: '$3.65/month (Static IP)'
  totalCombined: '$190.75/month'
  monthlySavings: '$8.17 saved by migrating to Central US'
  annualSavings: '$98.04 per year'
  savingsNote: 'Combined VM1 Central US savings + Standard_B4ms performance for Kubernetes'
}
