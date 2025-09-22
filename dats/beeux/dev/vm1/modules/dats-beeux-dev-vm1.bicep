// =============================================================================
// DATS-BEEUX-DEV VM1 - VIRTUAL MACHINE MODULE
// =============================================================================
// Creates the dats-beeux-dev VM1 Ubuntu VM with specified configuration
// =============================================================================

@description('Location for all resources')
param location string

@description('VM name override')
param vmName string = 'dats-beeux-dev'

@description('VM administrator username')
param adminUsername string

@description('Subnet ID where VM will be deployed')
param subnetId string

@description('VM size')
param vmSize string = 'Standard_B2ms'

@description('Availability Zone for the VM (1, 2, or 3)')
param availabilityZone string = '2'

@description('Existing OS disk resource ID from dev-scsm-vault VM')
param existingOsDiskId string

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
// VIRTUAL MACHINE (REUSING EXISTING DISK)
// =============================================================================

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: tags
  zones: [availabilityZone]
  identity: {
    type: 'SystemAssigned'  // Match existing VM configuration
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    // osProfile is not allowed when createOption is 'Attach' - existing disk contains OS configuration
    storageProfile: {
      // No imageReference needed when attaching existing disk
      osDisk: {
        name: split(existingOsDiskId, '/')[8]  // Extract disk name from resource ID
        caching: 'ReadWrite'
        createOption: 'Attach'  // Attach existing disk
        deleteOption: 'Detach'  // Keep disk if VM is deleted
        managedDisk: {
          id: existingOsDiskId
        }
        osType: 'Linux'  // Required when attaching existing disk
      }
      diskControllerType: 'SCSI'  // Match existing VM
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'  // Match existing VM
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
      securityType: 'TrustedLaunch'  // Match existing VM
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
      time: '0500'  // Match existing VM shutdown time (5:00 AM UTC)
    }
    timeZoneId: 'UTC'
    targetResourceId: virtualMachine.id
    notificationSettings: {
      status: 'Enabled'
      timeInMinutes: 30
      emailRecipient: 'prashantmdesai@hotmail.com'  // Match existing VM email
      notificationLocale: 'en'
    }
  }
}

// =============================================================================
// VM EXTENSIONS
// =============================================================================

// Azure AD SSH Login Extension (matches existing VM)
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

// Custom Script Extension for software installation (only for new VMs)
// NOTE: Not needed when reusing existing disk as software is already installed
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
//         'https://raw.githubusercontent.com/prashantmdesai/beeinfra/main/dats/beeux/dev/vm1/scripts/dats-beeux-dev-vm1-software-installer.sh'
//       ]
//       commandToExecute: 'bash dats-beeux-dev-vm1-software-installer.sh'
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
output diskConfiguration string = 'existing-disk-reuse'

@description('System Assigned Identity Principal ID')
output systemIdentityPrincipalId string = virtualMachine.identity.principalId
