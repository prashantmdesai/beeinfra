// =============================================================================
// DATS-BEEUX-DATA-DEV VM1 - KUBERNETES WORKER NODE (DATA)
// =============================================================================
// This Bicep template creates the dats-beeux-data-dev Ubuntu VM for Kubernetes worker
// Configuration:
// - VM: Standard_B2ms (2 vCPU, 8GB RAM) - Same as master
// - Storage: 30GB Premium SSD (fresh installation)
// - Network: Static Public IP, Static Private IP (10.0.1.4)
// - Ports: SSH, Kubernetes NodePort, HTTPS, HTTP
// - OS: Ubuntu 22.04 LTS (fresh install)
// Purpose: Kubernetes worker node for data services
// =============================================================================

targetScope = 'subscription'

@description('Location for all resources')
param location string = 'centralus'

@description('Environment name')
param environmentName string = 'dev'

@description('VM name')
param vmName string = 'dats-beeux-data-dev'

@description('VM admin username')
param adminUsername string = 'beeuser'

@description('VM size')
param vmSize string = 'Standard_B2ms'

@description('Availability Zone for the VM (1, 2, or 3) - Zone 1 to match existing VMs')
param availabilityZone string = '1'

@description('SSH public key for VM access')
@secure()
param sshPublicKey string

@description('Tags for all resources')
param tags object = {
  Environment: 'Dev'
  Project: 'BeeInfra'
  Owner: 'DevTeam'
  CostCenter: 'Development'
  CreatedBy: 'Bicep'
  Role: 'KubernetesWorker-Data'
}

// =============================================================================
// EXISTING RESOURCE GROUP (SHARED WITH ALL VMS)
// =============================================================================

resource devResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: 'rg-${environmentName}-centralus'
}

// =============================================================================
// NETWORKING (REUSES EXISTING VNET AND SUBNET)
// =============================================================================

module networking 'modules/dats-beeux-data-dev-networking.bicep' = {
  scope: devResourceGroup
  name: 'dats-beeux-data-dev-networking'
  params: {
    location: location
    environmentName: environmentName
    vmName: vmName
    availabilityZone: availabilityZone
    tags: tags
  }
}

// =============================================================================
// UBUNTU VM MODULE (KUBERNETES WORKER - DATA)
// =============================================================================

module ubuntuVM 'modules/dats-beeux-data-dev.bicep' = {
  scope: devResourceGroup
  name: 'dats-beeux-data-dev'
  params: {
    location: location
    vmName: vmName
    adminUsername: adminUsername
    vmSize: vmSize
    availabilityZone: availabilityZone
    sshPublicKey: sshPublicKey
    subnetId: networking.outputs.subnetId
    networkSecurityGroupId: networking.outputs.nsgId
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

@description('Kubernetes Node Internal URL')
output kubernetesNodeInternal string = 'https://${ubuntuVM.outputs.privateIpAddress}:10250'

@description('Estimated Monthly Cost')
output estimatedMonthlyCost string = '$61.29 (if running 24/7) - Central US'

@description('Cost Breakdown')
output costBreakdown object = {
  vmCompute: '$51.50/month (Standard_B2ms - Central US)'
  storage: '$6.14/month (30GB Premium SSD)'
  publicIP: '$3.65/month (Static IP)'
  total: '$61.29/month'
  note: 'Same configuration as master - optimized for Kubernetes worker workload'
}
