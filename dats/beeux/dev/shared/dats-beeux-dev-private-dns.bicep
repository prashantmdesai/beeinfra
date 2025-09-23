// =============================================================================
// DATS-BEEUX-DEV - PRIVATE DNS MODULE
// =============================================================================
// Creates Private DNS zone for internal VM communication
// Cost: ~$0.51/month (Private DNS zone + minimal query costs)
// =============================================================================

@description('Environment name')
param environmentName string

@description('Tags for all resources')
param tags object

@description('Virtual Network ID to link to the Private DNS zone')
param virtualNetworkId string

@description('Data VM private IP address')
param dataVmPrivateIp string = '10.0.1.4'

@description('Apps VM private IP address')
param appsVmPrivateIp string = '10.0.1.5'

// =============================================================================
// PRIVATE DNS ZONE
// =============================================================================

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'dats-beeux-dev.internal'
  location: 'global'
  tags: tags
  properties: {}
}

// =============================================================================
// VIRTUAL NETWORK LINK
// =============================================================================

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'vnet-link-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

// =============================================================================
// DNS RECORDS FOR VMs
// =============================================================================

resource dataVmDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZone
  name: 'data'
  properties: {
    aRecords: [
      {
        ipv4Address: dataVmPrivateIp
      }
    ]
    ttl: 300
  }
}

resource appsVmDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZone
  name: 'apps'
  properties: {
    aRecords: [
      {
        ipv4Address: appsVmPrivateIp
      }
    ]
    ttl: 300
  }
}

// Additional service-specific DNS records for common services
resource postgresqlDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZone
  name: 'postgresql'
  properties: {
    aRecords: [
      {
        ipv4Address: dataVmPrivateIp
      }
    ]
    ttl: 300
  }
}

resource redisDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZone
  name: 'redis'
  properties: {
    aRecords: [
      {
        ipv4Address: dataVmPrivateIp
      }
    ]
    ttl: 300
  }
}

resource vaultDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZone
  name: 'vault'
  properties: {
    aRecords: [
      {
        ipv4Address: dataVmPrivateIp
      }
    ]
    ttl: 300
  }
}

// =============================================================================
// OUTPUTS
// =============================================================================

@description('Private DNS Zone ID')
output privateDnsZoneId string = privateDnsZone.id

@description('Private DNS Zone Name')
output privateDnsZoneName string = privateDnsZone.name

@description('Data VM internal FQDN')
output dataVmInternalFqdn string = 'data.${privateDnsZone.name}'

@description('Apps VM internal FQDN')
output appsVmInternalFqdn string = 'apps.${privateDnsZone.name}'

@description('PostgreSQL service FQDN')
output postgresqlServiceFqdn string = 'postgresql.${privateDnsZone.name}'

@description('Redis service FQDN')
output redisServiceFqdn string = 'redis.${privateDnsZone.name}'

@description('Vault service FQDN')
output vaultServiceFqdn string = 'vault.${privateDnsZone.name}'