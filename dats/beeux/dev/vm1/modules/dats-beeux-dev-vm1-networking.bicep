// =============================================================================
// DATS-BEEUX-DEV VM1 - NETWORKING MODULE
// =============================================================================
// Creates VNet, subnet, and NSG for the dats-beeux-dev VM1 Ubuntu VM
// =============================================================================

@description('Location for all resources')
param location string

@description('Environment name')
param environmentName string

@description('Tags for all resources')
param tags object

@description('Your public IP address for restricted access')
param allowedSourceIP string = '136.56.79.92'

// =============================================================================
// VIRTUAL NETWORK
// =============================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-${environmentName}-${location}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-${environmentName}-default'
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

// =============================================================================
// NETWORK SECURITY GROUP
// =============================================================================

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-${environmentName}-ubuntu-vm'
  location: location
  tags: tags
  properties: {
    securityRules: [
      // Internal VM-to-VM Communication (High Priority)
      {
        name: 'AllowVMToVMCommunication'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          description: 'Allow all communication between VMs in the VNet for service discovery and inter-VM communication'
        }
      }
      // SSH Access
      {
        name: 'AllowSSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1001
          direction: 'Inbound'
          description: 'Allow SSH access'
        }
      }
      // Web Services
      {
        name: 'AllowHTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1002
          direction: 'Inbound'
          description: 'Allow HTTP access from your IP'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1003
          direction: 'Inbound'
          description: 'Allow HTTPS access from your IP'
        }
      }
      // Database Services
      {
        name: 'AllowPostgreSQL'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['5432', '5433', '5434']
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1005
          direction: 'Inbound'
          description: 'Allow PostgreSQL database access from your IP'
        }
      }
      {
        name: 'AllowMySQL'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3306'
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1004
          direction: 'Inbound'
          description: 'Allow MySQL database access from your IP'
        }
      }
      // Redis Services
      {
        name: 'AllowRedis'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['6379', '6380']
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
          description: 'Allow Redis access from your IP'
        }
      }
      {
        name: 'AllowRedisSentinel'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['26379', '26380', '26381']
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1011
          direction: 'Inbound'
          description: 'Allow Redis Sentinel access from your IP'
        }
      }
      // RabbitMQ Services
      {
        name: 'AllowRabbitMQ'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['5670', '5672', '5673', '5674']
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1012
          direction: 'Inbound'
          description: 'Allow RabbitMQ AMQP access from your IP'
        }
      }
      {
        name: 'AllowRabbitMQManagement'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['15670', '15672', '15673', '15674']
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1013
          direction: 'Inbound'
          description: 'Allow RabbitMQ Management UI from your IP'
        }
      }
      // HashiCorp Vault
      {
        name: 'AllowVault'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8200'
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1006
          direction: 'Inbound'
          description: 'Allow HashiCorp Vault access from your IP'
        }
      }
      // Development Applications
      {
        name: 'AllowDevApps1'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['8083', '8404', '8888', '8889']
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1014
          direction: 'Inbound'
          description: 'Allow development applications from your IP'
        }
      }
      {
        name: 'AllowDevApps2'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['9121', '9419', '9999']
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1015
          direction: 'Inbound'
          description: 'Allow monitoring and dev applications from your IP'
        }
      }
      // Common Development Ports
      {
        name: 'AllowCommonDevPorts'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['4000', '4001', '8000', '8001']
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1016
          direction: 'Inbound'
          description: 'Allow common development ports from your IP'
        }
      }
      // Monitoring and Observability Services
      {
        name: 'AllowMonitoring'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['3100', '9090', '9091', '9093', '9100', '9115', '9187']
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1017
          direction: 'Inbound'
          description: 'Allow Prometheus, Grafana Loki, and monitoring tools from your IP'
        }
      }
      // Grafana and Dashboard Services
      {
        name: 'AllowDashboards'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['3000', '3001', '8080', '8081', '9000', '9001']
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1018
          direction: 'Inbound'
          description: 'Allow Grafana and dashboard services from your IP'
        }
      }
      // Kubernetes Services
      {
        name: 'AllowKubernetes'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['8090', '30000', '30001', '30080', '30443', '32000']
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1019
          direction: 'Inbound'
          description: 'Allow Kubernetes Dashboard and NodePort services from your IP'
        }
      }
      // Kubernetes Ingress NodePorts (Active Services)
      {
        name: 'AllowKubernetesIngress'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['30214', '30500']
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1021
          direction: 'Inbound'
          description: 'Allow Kubernetes Ingress Controller NodePorts from your IP'
        }
      }
      // Additional Development Services
      {
        name: 'AllowAdditionalDevServices'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['5000', '5001', '5050', '5555', '7000', '7001', '8888', '8889', '9900']
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1020
          direction: 'Inbound'
          description: 'Allow additional development services and tools from your IP'
        }
      }
      // DNS Services (for development)
      {
        name: 'AllowDNS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '53'
          sourceAddressPrefix: allowedSourceIP
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1022
          direction: 'Inbound'
          description: 'Allow DNS access from your WiFi network'
        }
      }
    ]
  }
}

// =============================================================================
// OUTPUTS
// =============================================================================

@description('Virtual Network ID')
output virtualNetworkId string = virtualNetwork.id

@description('Subnet ID')
output subnetId string = virtualNetwork.properties.subnets[0].id

@description('Network Security Group ID')
output networkSecurityGroupId string = networkSecurityGroup.id
