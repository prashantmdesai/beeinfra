// =============================================================================
// DATS-BEEUX-DEV VM2 - VIRTUAL MACHINE MODULE
// =============================================================================
// Creates the dats-beeux-dev VM2 Ubuntu VM with NEW disk (fresh installation)
// =============================================================================

@description('Location for all resources')
param location string

@description('VM name override')
param vmName string = 'dats-beeux-dev-apps'

@description('VM administrator username')
param adminUsername string

@description('VM administrator password')
@secure()
param adminPassword string

@description('SSH public key for authentication')
param sshPublicKey string = ''

@description('Subnet ID where VM will be deployed')
param subnetId string

@description('VM size')
param vmSize string = 'Standard_B4ms'

@description('Availability Zone for the VM (1, 2, or 3)')
param availabilityZone string = '1'

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
// VIRTUAL MACHINE (NEW FRESH INSTALLATION)
// =============================================================================

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: tags
  zones: [availabilityZone]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: sshPublicKey != '' ? {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      } : {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        deleteOption: 'Delete'
        diskSizeGB: osDiskSizeGB
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        osType: 'Linux'
      }
      diskControllerType: 'SCSI'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
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
      time: '0500'  // 5:00 AM UTC (same as VM1)
    }
    timeZoneId: 'UTC'
    targetResourceId: virtualMachine.id
    notificationSettings: {
      status: 'Enabled'
      timeInMinutes: 30
      emailRecipient: 'prashantmdesai@hotmail.com'
      notificationLocale: 'en'
    }
  }
}

// =============================================================================
// VM EXTENSIONS
// =============================================================================

// Azure AD SSH Login Extension
resource aadSshExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: virtualMachine
  name: 'AADSSHLoginForLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADSSHLoginForLinux'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
}

// Custom Script Extension for software installation
// Note: Disabled for initial deployment - will install software manually
// resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
//   parent: virtualMachine
//   name: 'CustomScript'
//   location: location
//   dependsOn: [aadSshExtension]
//   properties: {
//     publisher: 'Microsoft.Azure.Extensions'
//     type: 'CustomScript'
//     typeHandlerVersion: '2.1'
//     autoUpgradeMinorVersion: true
//     settings: {
//       fileUris: [
//         'https://raw.githubusercontent.com/prashantmdesai/beeinfra/main/dats/beeux/dev/vm2/scripts/dats-beeux-dev-vm2-software-installer.sh'
//       ]
//       commandToExecute: 'bash dats-beeux-dev-vm2-software-installer.sh'
//     }
//   }
// }

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

@description('Network Interface Resource ID')
output networkInterfaceId string = networkInterface.id

@description('Availability Zone')
output vmZone string = availabilityZone

@description('Disk Configuration Used')
output diskConfiguration string = 'new-disk-fresh-install'

@description('System Assigned Identity Principal ID')
output systemIdentityPrincipalId string = virtualMachine.identity.principalId

@description('OS Disk Resource ID')
output osDiskId string = virtualMachine.properties.storageProfile.osDisk.managedDisk.id
