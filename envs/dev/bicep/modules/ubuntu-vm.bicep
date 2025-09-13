// =============================================================================
// UBUNTU VIRTUAL MACHINE MODULE - DEV ENVIRONMENT
// =============================================================================
// Creates Ubuntu VM with specified configuration for development environment
// =============================================================================

@description('Location for all resources')
param location string

@description('Environment name')
param environmentName string

@description('VM name override')
param vmName string = 'dats-beeux-dev'

@description('VM administrator username')
param adminUsername string

@description('VM administrator password')
@secure()
param adminPassword string

@description('SSH public key for VM access')
param sshPublicKey string

@description('Subnet ID where VM will be deployed')
param subnetId string

@description('VM size')
param vmSize string = 'Standard_B2ms'

@description('OS disk size in GB')
param osDiskSizeGB int = 30

@description('Tags for all resources')
param tags object

// =============================================================================
// PUBLIC IP ADDRESS
// =============================================================================

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-${vmName}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: '${vmName}-${uniqueString(resourceGroup().id)}'
    }
  }
}

// =============================================================================
// NETWORK INTERFACE
// =============================================================================

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'nic-${vmName}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'internal'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

// =============================================================================
// MANAGED IDENTITY
// =============================================================================

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'mid-${vmName}'
  location: location
  tags: tags
}

// =============================================================================
// VIRTUAL MACHINE
// =============================================================================

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        name: 'disk-${vmName}-os'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: osDiskSizeGB
        deleteOption: 'Detach'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// =============================================================================
// AUTO SHUTDOWN SCHEDULE
// =============================================================================

resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${virtualMachine.name}'
  location: location
  tags: tags
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '1900'
    }
    timeZoneId: 'UTC'
    targetResourceId: virtualMachine.id
    notificationSettings: {
      status: 'Enabled'
      timeInMinutes: 30
      emailRecipient: 'prashantmdesai@yahoo.com'
      notificationLocale: 'en'
    }
  }
}

// =============================================================================
// VM EXTENSIONS
// =============================================================================

resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: virtualMachine
  name: 'CustomScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/prashantmdesai/beeinfra/main/envs/dev/scripts/install-dev-software.sh'
      ]
      commandToExecute: 'bash install-dev-software.sh'
    }
  }
}

// =============================================================================
// OUTPUTS
// =============================================================================

@description('Virtual Machine Resource ID')
output vmId string = virtualMachine.id

@description('VM Computer Name')
output vmName string = virtualMachine.name

@description('Public IP Address')
output publicIpAddress string = publicIp.properties.ipAddress

@description('Private IP Address')
output privateIpAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress

@description('FQDN for SSH connection')
output fqdn string = publicIp.properties.dnsSettings.fqdn

@description('SSH Connection Command')
output sshCommand string = 'ssh ${adminUsername}@${publicIp.properties.ipAddress}'

@description('VM Admin Username')
output adminUsername string = adminUsername

@description('Managed Identity Resource ID')
output managedIdentityId string = managedIdentity.id

@description('Network Interface Resource ID')
output networkInterfaceId string = networkInterface.id
