/*
 * DEVELOPER VIRTUAL MACHINE MODULE
 * ================================
 * 
 * This module deploys a Linux-based development virtual machine in each environment
 * to fulfill requirement 24 from infrasetup.instructions.md. The VM provides developers
 * with direct access to environment resources and a fully configured development environment.
 * 
 * PURPOSE AND REQUIREMENTS COMPLIANCE:
 * ====================================
 * Requirements 18-20 mandate a Linux virtual machine in each environment that:
 * - Allows developers to login and access Azure resources in that environment
 * - Has all requisite development software pre-installed (Azure CLI, Git, etc.)
 * - Displays IP address and machine name after environment setup
 * - Provides SSH access for remote development
 * 
 * ENVIRONMENT-SPECIFIC VM SIZING:
 * ===============================
 * VM sizes are optimized for each environment's purpose and budget:
 * 
 * - IT Environment: Standard_B2s (2 vCPUs, 4GB RAM, ~$30/month)
 *   * Cost-optimized for development work
 *   * Burstable performance for occasional intensive tasks
 *   * Perfect for individual developer use
 * 
 * - QA Environment: Standard_D2s_v3 (2 vCPUs, 8GB RAM, ~$70/month)  
 *   * More memory for running test suites and performance testing
 *   * Consistent performance for reliable testing
 *   * Can handle multiple concurrent test processes
 * 
 * - Production: Standard_D4s_v3 (4 vCPUs, 16GB RAM, ~$140/month)
 *   * High-performance for production debugging and monitoring
 *   * Sufficient resources for production troubleshooting tools
 *   * Can handle intensive monitoring and diagnostic workloads
 * 
 * PRE-INSTALLED DEVELOPMENT TOOLS:
 * ================================
 * The VM is automatically configured with a complete development environment:
 * - Ubuntu 22.04 LTS (latest stable Linux distribution)
 * - Azure CLI (for managing Azure resources)
 * - Git (version control)
 * - Docker (containerization)
 * - Node.js (for Angular frontend development)
 * - Python (for automation scripts)
 * - VS Code Server (browser-based development environment)
 * - Java/Maven (for Spring Boot backend development)
 * 
 * NETWORK SECURITY CONFIGURATION:
 * ===============================
 * The VM is secured with a Network Security Group that allows:
 * - SSH (port 22): For terminal access and development
 * - HTTP (port 80): For local web development and testing
 * - HTTPS (port 443): For secure web access
 * - VS Code Server (port 8080): For browser-based development
 * 
 * IDENTITY AND ACCESS MANAGEMENT:
 * ===============================
 * - Uses Azure Managed Identity for secure access to Azure resources
 * - SSH key-based authentication (no passwords for security)
 * - Can access Key Vault, Storage, and other environment resources
 * - Properly tagged for environment identification and cost tracking
 * 
 * AUTOMATIC SETUP AND CONFIGURATION:
 * ==================================
 * - Custom script extension runs setup scripts automatically
 * - All tools are installed and configured without manual intervention
 * - SSH keys are automatically deployed for immediate access
 * - VM is ready for development work immediately after deployment
 * 
 * OUTPUTS FOR DEVELOPER ACCESS:
 * =============================
 * The module provides all necessary information for developers to access the VM:
 * - VM Name and Computer Name for identification
 * - Public IP Address for direct access
 * - FQDN for DNS-based access
 * - Complete SSH command for easy connection
 * - Resource IDs for Azure management operations
 */

@description('Environment name (it, qa, prod)')
param environmentName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Resource token for unique naming')
param resourceToken string

@description('User assigned managed identity ID')
param userAssignedIdentityId string

@description('Virtual network ID')
param virtualNetworkId string

@description('Subnet ID for VMs')
param subnetId string

@description('Admin username for the VM')
param adminUsername string = 'devuser'

@description('SSH public key for VM access')
@secure()
param sshPublicKey string

// VM size based on environment
var vmSizes = {
  it: 'Standard_B2s'      // 2 vCPUs, 4GB RAM (~$30/month)
  qa: 'Standard_D2s_v3'   // 2 vCPUs, 8GB RAM (~$70/month)
  prod: 'Standard_D4s_v3' // 4 vCPUs, 16GB RAM (~$140/month)
}

var vmName = 'vm-dev-${environmentName}-${resourceToken}'
var networkInterfaceName = 'nic-dev-${environmentName}-${resourceToken}'
var osDiskName = 'disk-dev-${environmentName}-${resourceToken}'
var nsgName = 'nsg-dev-${environmentName}-${resourceToken}'

// Network Security Group for VM
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  tags: {
    Environment: environmentName
    Purpose: 'Developer VM Security'
    'azd-env-name': environmentName
  }
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1001
          protocol: 'TCP'
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
          protocol: 'TCP'
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
          protocol: 'TCP'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'VSCode'
        properties: {
          priority: 1004
          protocol: 'TCP'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '8080'
        }
      }
    ]
  }
}

// Public IP for VM
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-dev-${environmentName}-${resourceToken}'
  location: location
  tags: {
    Environment: environmentName
    Purpose: 'Developer VM Public IP'
    'azd-env-name': environmentName
  }
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'beeux-dev-${environmentName}-${resourceToken}'
    }
  }
}

// Network Interface for VM
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: networkInterfaceName
  location: location
  tags: {
    Environment: environmentName
    Purpose: 'Developer VM Network Interface'
    'azd-env-name': environmentName
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
          subnet: !empty(subnetId) ? {
            id: subnetId
          } : null
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

// Virtual Machine
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: {
    Environment: environmentName
    Purpose: 'Developer VM'
    'azd-env-name': environmentName
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSizes[environmentName]
    }
    osProfile: {
      computerName: 'dev-${environmentName}-vm'
      adminUsername: adminUsername
      disablePasswordAuthentication: true
      linuxConfiguration: {
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
      customData: base64(loadTextContent('scripts/vm-setup.sh'))
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
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
  }
}

// VM Extension for custom setup
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: virtualMachine
  name: 'customScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix: false
    }
    protectedSettings: {
      script: base64(loadTextContent('scripts/vm-post-setup.sh'))
    }
  }
}

// Outputs
output vmName string = virtualMachine.name
output vmComputerName string = virtualMachine.properties.osProfile.computerName
output publicIPAddress string = publicIP.properties.ipAddress
output fqdn string = publicIP.properties.dnsSettings.fqdn
output sshCommand string = 'ssh ${adminUsername}@${publicIP.properties.ipAddress}'
output vmResourceId string = virtualMachine.id
output vmPrincipalId string = virtualMachine.identity.principalId
