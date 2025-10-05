// =============================================================================
// DATS-BEEUX-INFR-DEV VM3 - KUBERNETES MASTER NODE
// =============================================================================
// This Bicep template creates the dats-beeux-infr-dev Ubuntu VM for Kubernetes master
// Configuration:
// - VM: Standard_B2ms (2 vCPU, 8GB RAM) - Same as data VM
// - Storage: 30GB Premium SSD (fresh installation)
// - Network: Static Public IP
// - Ports: SSH, Kubernetes API (6443), HTTPS, HTTP
// - OS: Ubuntu 24.04 LTS (fresh install)
// Purpose: Kubernetes master node for the 3-VM cluster
// =============================================================================

targetScope = 'subscription'

@description('Location for all resources')
param location string = 'centralus'

@description('Environment name')
param environmentName string = 'dev'

@description('VM name')
param vmName string = 'dats-beeux-infr-dev'

@description('VM admin username')
param adminUsername string = 'beeuser'

@description('VM size - B2ms for master/data role, B4ms for apps role')
@allowed([
  'Standard_B2ms'  // 2 vCPU, 8GB RAM - Master/Data nodes
  'Standard_B4ms'  // 4 vCPU, 16GB RAM - Apps/Worker nodes  
])
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
  Role: 'KubernetesMaster'
}

// =============================================================================
// EXISTING RESOURCE GROUP (SHARED WITH VM1 AND VM2)
// =============================================================================

resource devResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: 'rg-${environmentName}-centralus'
}

// =============================================================================
// NETWORKING (REUSES EXISTING VNET AND SUBNET)
// =============================================================================

module networking 'modules/dats-beeux-infr-dev-networking.bicep' = {
  scope: devResourceGroup
  name: 'dats-beeux-infr-dev-networking'
  params: {
    location: location
    environmentName: environmentName
    vmName: vmName
    availabilityZone: availabilityZone
    tags: tags
  }
}

// =============================================================================
// UBUNTU VM MODULE (KUBERNETES MASTER)
// =============================================================================

module ubuntuVM 'modules/dats-beeux-infr-dev.bicep' = {
  scope: devResourceGroup
  name: 'dats-beeux-infr-dev'
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

@description('Kubernetes API Server URL (Internal)')
output kubernetesApiInternal string = 'https://${ubuntuVM.outputs.privateIpAddress}:6443'

@description('Kubernetes API Server URL (External)')
output kubernetesApiExternal string = 'https://${ubuntuVM.outputs.publicIpAddress}:6443'

@description('Estimated Monthly Cost')
output estimatedMonthlyCost string = '$61.29 (if running 24/7) - Central US'

@description('Cost Breakdown')
output costBreakdown object = {
  vmCompute: '$51.50/month (Standard_B2ms - Central US)'
  storage: '$6.14/month (30GB Premium SSD)'
  publicIP: '$3.65/month (Static IP)'
  total: '$61.29/month'
  note: 'Same configuration as data VM - optimized for Kubernetes master workload'
}
