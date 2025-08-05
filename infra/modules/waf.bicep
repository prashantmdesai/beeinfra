@description('WAF Policy name')
param wafPolicyName string

@description('Application Gateway name')
param applicationGatewayName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Public IP resource ID')
param publicIPId string

@description('Subnet ID for Application Gateway')
param subnetId string

@description('Web App hostname for backend')
param webAppHostName string

@description('Environment name')
param environmentName string

@description('Tags for resources')
param tags object = {}

// WAF Policy with HTTPS enforcement
resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-09-01' = {
  name: wafPolicyName
  location: location
  tags: tags
  properties: {
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: environmentName == 'prod' ? 'Prevention' : 'Detection'
      requestBodyInspectLimitInKB: 128
      fileUploadEnforcement: true
      requestBodyEnforcement: true
    }
    customRules: [
      // Block non-HTTPS traffic
      {
        name: 'BlockHTTP'
        priority: 1
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RequestUri'
              }
            ]
            operator: 'BeginsWith'
            matchValues: [
              'http://'
            ]
            negationConditon: false
            transforms: [
              'Lowercase'
            ]
          }
        ]
      }
      // Force HTTPS redirect for known patterns
      {
        name: 'RedirectToHTTPS'
        priority: 2
        ruleType: 'MatchRule'
        action: 'Allow'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RequestHeaders'
                selector: 'X-Forwarded-Proto'
              }
            ]
            operator: 'Equal'
            matchValues: [
              'http'
            ]
            negationConditon: false
            transforms: [
              'Lowercase'
            ]
          }
        ]
      }
      // Rate limiting for API endpoints
      {
        name: 'RateLimitAPI'
        priority: 10
        ruleType: 'RateLimitRule'
        action: 'Block'
        rateLimitDurationInMinutes: 1
        rateLimitThreshold: 100
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RequestUri'
              }
            ]
            operator: 'BeginsWith'
            matchValues: [
              '/api/'
            ]
            negationConditon: false
            transforms: [
              'Lowercase'
            ]
          }
        ]
      }
    ]
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
          ruleGroupOverrides: []
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '0.1'
          ruleGroupOverrides: []
        }
      ]
      exclusions: []
    }
  }
}

// Application Gateway with HTTPS enforcement
resource applicationGateway 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: applicationGatewayName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: environmentName == 'prod' ? 3 : 2
    }
    gatewayIPConfigurations: [
      {
        name: 'gatewayIP'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendIP'
        properties: {
          publicIPAddress: {
            id: publicIPId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'webAppBackend'
        properties: {
          backendAddresses: [
            {
              fqdn: webAppHostName
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpsSettings'
        properties: {
          port: 443
          protocol: 'Https' // Force HTTPS to backend
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'httpsProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'frontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port80')
          }
          protocol: 'Http'
        }
      }
      {
        name: 'httpsListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'frontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port443')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, 'appGatewaySslCert')
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'httpRedirectRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'httpListener')
          }
          redirectConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', applicationGatewayName, 'httpsRedirect')
          }
        }
      }
      {
        name: 'httpsRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 200
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'httpsListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'webAppBackend')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'httpsSettings')
          }
        }
      }
    ]
    redirectConfigurations: [
      {
        name: 'httpsRedirect'
        properties: {
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'httpsListener')
          }
          includePath: true
          includeQueryString: true
        }
      }
    ]
    probes: [
      {
        name: 'httpsProbe'
        properties: {
          protocol: 'Https'
          path: '/health'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
        }
      }
    ]
    sslCertificates: [
      {
        name: 'appGatewaySslCert'
        properties: {
          data: ''
          password: ''
          // In production, this should reference Key Vault certificate
          keyVaultSecretId: ''
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: environmentName == 'prod' ? 'Prevention' : 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      disabledRuleGroups: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    firewallPolicy: {
      id: wafPolicy.id
    }
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: environmentName == 'prod' ? 10 : 5
    }
  }
}

// SSL Policy for enhanced security
resource sslPolicy 'Microsoft.Network/applicationGateways/sslPolicies@2023-09-01' = {
  parent: applicationGateway
  name: 'default'
  properties: {
    policyType: 'Custom'
    minProtocolVersion: 'TLSv1_2'
    cipherSuites: [
      'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384'
      'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
      'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384'
      'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256'
      'TLS_RSA_WITH_AES_256_GCM_SHA384'
      'TLS_RSA_WITH_AES_128_GCM_SHA256'
    ]
  }
}

// Outputs
output applicationGatewayId string = applicationGateway.id
output applicationGatewayName string = applicationGateway.name
output wafPolicyId string = wafPolicy.id
output publicFqdn string = reference(publicIPId, '2023-09-01').dnsSettings.fqdn
output httpsUrl string = 'https://${reference(publicIPId, '2023-09-01').dnsSettings.fqdn}'
