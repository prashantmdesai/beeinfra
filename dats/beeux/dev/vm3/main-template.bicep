// =============================================================================
// STANDARDIZED MAIN TEMPLATE FOR VM3 (dats-beeux-infr-dev)
// =============================================================================
// Kubernetes Master Node - Following uniform naming convention
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

@description('VM size')
@allowed([
  'Standard_B2ms'  // 2 vCPU, 8GB RAM - Master/Data nodes
  'Standard_B4ms'  // 4 vCPU, 16GB RAM - Apps/Worker nodes  
])
param vmSize string = 'Standard_B2ms'

@description('Availability Zone - Zone 1 to match existing VMs')
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
  Zone: '1'
  SoftwareStack: 'Ubuntu22.04-Docker-K8s1.28-Node18-Python3.12'
  AzureFileShare: 'Enabled'
  MountPoint: '/mnt/shared-data'
}

// =============================================================================
// EXISTING RESOURCE GROUP (SHARED)
// =============================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: 'rg-${environmentName}-centralus'
}

// =============================================================================
// NETWORKING MODULE
// =============================================================================

module networking 'modules/networking.bicep' = {
  scope: resourceGroup
  name: '${vmName}-networking'
  params: {
    location: location
    environmentName: environmentName
    vmName: vmName
    availabilityZone: availabilityZone
    tags: tags
  }
}

// =============================================================================
// VM MODULE
// =============================================================================

module virtualMachine 'modules/vm.bicep' = {
  scope: resourceGroup
  name: vmName
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
output resourceGroupName string = resourceGroup.name

@description('VM Public IP Address')
output vmPublicIP string = virtualMachine.outputs.publicIpAddress

@description('VM Private IP Address')  
output vmPrivateIP string = virtualMachine.outputs.privateIpAddress

@description('SSH Connection Command')
output sshCommand string = 'ssh ${adminUsername}@${virtualMachine.outputs.publicIpAddress}'

@description('VM Resource ID')
output vmResourceId string = virtualMachine.outputs.vmId

@description('Kubernetes API Server URL (Internal)')
output kubernetesApiInternal string = 'https://${virtualMachine.outputs.privateIpAddress}:6443'

@description('Kubernetes API Server URL (External)')
output kubernetesApiExternal string = 'https://${virtualMachine.outputs.publicIpAddress}:6443'

@description('VM Role and Configuration')
output vmConfiguration object = {
  name: vmName
  role: 'KubernetesMaster'
  zone: availabilityZone
  size: vmSize
  softwareStack: 'Ubuntu22.04-Docker-K8s1.28-Node18-Python3.12'
  azureFileShare: '/mnt/shared-data'
  interVmCommunication: 'Enabled'
}
