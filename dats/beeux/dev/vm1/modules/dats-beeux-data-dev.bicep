// =============================================================================
// DATS-BEEUX-DATA-DEV VM1 - VIRTUAL MACHINE MODULE (KUBERNETES WORKER - DATA)
// =============================================================================
// Creates the dats-beeux-data-dev Ubuntu VM for Kubernetes worker with fresh installation
// Same hardware specs as master - optimized for data services
// =============================================================================

@description('Location for all resources')
param location string

@description('VM name')
param vmName string = 'dats-beeux-data-dev'

@description('VM administrator username')
param adminUsername string

@description('SSH public key for authentication')
@secure()
param sshPublicKey string

@description('Subnet ID where VM will be deployed')
param subnetId string

@description('Network Security Group ID')
param networkSecurityGroupId string

@description('VM size')
param vmSize string = 'Standard_B2ms'

@description('Availability Zone for the VM (1, 2, or 3) - Zone 1 to match existing VMs')
param availabilityZone string = '1'

@description('Tags for all resources')
param tags object

// =============================================================================
// PUBLIC IP ADDRESS
// =============================================================================

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-${vmName}'
  location: location
  tags: tags
  zones: [availabilityZone]
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: vmName
      fqdn: '${vmName}.${location}.cloudapp.azure.com'
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
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.1.4'  // Static IP for data worker node
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupId
    }
  }
}

// =============================================================================
// VIRTUAL MACHINE (FRESH INSTALLATION)
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
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'  // Ubuntu 22.04 LTS for Kubernetes compatibility
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        deleteOption: 'Delete'
        diskSizeGB: 30
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
      time: '0500'  // 5:00 AM UTC shutdown
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

@description('Kubernetes Node Internal URL')
output kubernetesNodeInternal string = 'https://${networkInterface.properties.ipConfigurations[0].properties.privateIPAddress}:10250'

@description('VM Admin Username')
output adminUsername string = adminUsername

@description('Network Interface Resource ID')
output networkInterfaceId string = networkInterface.id

@description('Availability Zone')
output vmZone string = availabilityZone

@description('System Assigned Identity Principal ID')
output systemIdentityPrincipalId string = virtualMachine.identity.principalId

@description('VM Role')
output vmRole string = 'KubernetesWorker-Data'
