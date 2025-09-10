// =============================================================================
// UBUNTU DEV VM 01 - MAIN BICEP TEMPLATE
// =============================================================================
// VM Configuration: Standard_B2s (2 vCPU, 4GB RAM) with Premium SSD
// Environment: Development
// Purpose: General development workstation with web and database capabilities
// =============================================================================

@description('The name of the VM')
param vmName string = 'ubuntu-dev-01'

@description('Admin username for the VM')
param adminUsername string = 'beeuser'

@description('Admin password for the VM (if using password authentication)')
@secure()
param adminPassword string = ''

@description('SSH public key for authentication')
param sshPublicKey string = ''

@description('VM size/SKU')
@allowed([
  'Standard_B1s'
  'Standard_B1ms'
  'Standard_B2s'
  'Standard_B2ms'
  'Standard_D2s_v5'
  'Standard_F2s_v2'
])
param vmSize string = 'Standard_B2s'

@description('OS disk type')
@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param osDiskType string = 'Premium_LRS'

@description('OS disk size in GB')
param osDiskSizeGB int = 30

@description('Ubuntu OS version')
@allowed([
  '18.04-LTS'
  '20.04-LTS'
  '22.04-LTS'
  '24.04-LTS'
])
param ubuntuOSVersion string = '24.04-LTS'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment tag')
param environment string = 'dev'

@description('Owner tag')
param owner string = 'development-team'

@description('Cost center tag')
param costCenter string = 'dev-infrastructure'

// =============================================================================
// VARIABLES
// =============================================================================

var resourcePrefix = 'beeinfra-${environment}'
var vmResourceName = '${resourcePrefix}-${vmName}'
var networkSecurityGroupName = '${vmResourceName}-nsg'
var virtualNetworkName = '${resourcePrefix}-vnet'
var subnetName = '${resourcePrefix}-subnet'
var publicIPName = '${vmResourceName}-pip'
var networkInterfaceName = '${vmResourceName}-nic'
var osDiskName = '${vmResourceName}-osdisk'

// Common tags
var commonTags = {
  Environment: environment
  Owner: owner
  CostCenter: costCenter
  VMName: vmName
  Purpose: 'Development'
  CreatedBy: 'Bicep'
  LastModified: utcNow()
}

// Network security rules
var securityRules = [
  {
    name: 'SSH'
    properties: {
      priority: 1001
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '22'
    }
  }
  {
    name: 'HTTP'
    properties: {
      priority: 1002
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '80'
    }
  }
  {
    name: 'HTTPS'
    properties: {
      priority: 1003
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }
  {
    name: 'MySQL'
    properties: {
      priority: 1004
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '3306'
    }
  }
  {
    name: 'PostgreSQL'
    properties: {
      priority: 1005
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '5432'
    }
  }
]

// =============================================================================
// RESOURCES
// =============================================================================

// Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: virtualNetworkName
  location: location
  tags: commonTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

// Network Security Group
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: networkSecurityGroupName
  location: location
  tags: commonTags
  properties: {
    securityRules: securityRules
  }
}

// Static Public IP
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIPName
  location: location
  tags: commonTags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: toLower('${vmResourceName}-${uniqueString(resourceGroup().id)}')
    }
  }
}

// Network Interface
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: networkInterfaceName
  location: location
  tags: commonTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${virtualNetwork.id}/subnets/${subnetName}'
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

// Virtual Machine
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmResourceName
  location: location
  tags: commonTags
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
      adminPassword: !empty(adminPassword) ? adminPassword : null
      linuxConfiguration: !empty(sshPublicKey) ? {
        disablePasswordAuthentication: false
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      } : null
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: osDiskSizeGB
        managedDisk: {
          storageAccountType: osDiskType
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
        enabled: false
      }
    }
  }
}

// =============================================================================
// OUTPUTS
// =============================================================================

@description('VM Resource ID')
output vmId string = virtualMachine.id

@description('VM Name')
output vmName string = virtualMachine.name

@description('VM Computer Name')
output computerName string = virtualMachine.properties.osProfile.computerName

@description('Public IP Address')
output publicIPAddress string = publicIP.properties.ipAddress

@description('FQDN')
output fqdn string = publicIP.properties.dnsSettings.fqdn

@description('SSH Connection Command')
output sshCommand string = 'ssh ${adminUsername}@${publicIP.properties.ipAddress}'

@description('VM Size')
output vmSize string = virtualMachine.properties.hardwareProfile.vmSize

@description('OS Disk Type')
output osDiskType string = virtualMachine.properties.storageProfile.osDisk.managedDisk.storageAccountType

@description('Resource Group Name')
output resourceGroupName string = resourceGroup().name

@description('Virtual Network Name')
output vnetName string = virtualNetwork.name

@description('Subnet Name')
output subnetName string = subnetName

@description('Network Security Group Name')
output nsgName string = networkSecurityGroup.name

@description('Estimated Monthly Cost (24/7 operation)')
output estimatedMonthlyCost string = '$40.16 (B2s: $30.37 + Premium SSD: $6.14 + Static IP: $3.65)'
