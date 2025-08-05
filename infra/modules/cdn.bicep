@description('CDN Profile name')
param profileName string

@description('Location for CDN profile (global resource)')
param location string = 'Global'

@description('Storage Account hostname for origin')
param storageAccountHostName string

@description('Tags for resources')
param tags object = {}

// CDN Profile with HTTPS enforcement
resource cdnProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: profileName
  location: location
  tags: tags
  sku: {
    name: 'Standard_Microsoft'
  }
  properties: {
    originResponseTimeoutSeconds: 60
  }
}

// CDN Endpoint with HTTPS-only configuration
resource cdnEndpoint 'Microsoft.Cdn/profiles/endpoints@2023-05-01' = {
  parent: cdnProfile
  name: '${profileName}-endpoint'
  location: location
  tags: tags
  properties: {
    originHostHeader: storageAccountHostName
    isHttpAllowed: false // Block HTTP traffic
    isHttpsAllowed: true // Allow HTTPS only
    queryStringCachingBehavior: 'IgnoreQueryString'
    contentTypesToCompress: [
      'text/plain'
      'text/html'
      'text/css'
      'application/x-javascript'
      'text/javascript'
      'application/javascript'
      'application/json'
      'audio/mpeg'
      'audio/mp3'
      'audio/wav'
    ]
    isCompressionEnabled: true
    origins: [
      {
        name: 'storage-origin'
        properties: {
          hostName: storageAccountHostName
          httpPort: 80
          httpsPort: 443
          originHostHeader: storageAccountHostName
          priority: 1
          weight: 1000
          enabled: true
        }
      }
    ]
    originGroups: []
    defaultOriginGroup: null
    deliveryPolicy: {
      description: 'HTTPS enforcement and security headers'
      rules: [
        {
          name: 'HTTPSRedirect'
          order: 1
          conditions: [
            {
              name: 'RequestScheme'
              parameters: {
                typeName: 'DeliveryRuleRequestSchemeConditionParameters'
                matchValues: [
                  'HTTP'
                ]
                operator: 'Equal'
                negateCondition: false
                transforms: []
              }
            }
          ]
          actions: [
            {
              name: 'UrlRedirect'
              parameters: {
                typeName: 'DeliveryRuleUrlRedirectActionParameters'
                redirectType: 'PermanentRedirect'
                destinationProtocol: 'Https'
                customPath: null
                customHostname: null
                customQueryString: null
                customFragment: null
              }
            }
          ]
        }
        {
          name: 'SecurityHeaders'
          order: 2
          conditions: [
            {
              name: 'RequestScheme'
              parameters: {
                typeName: 'DeliveryRuleRequestSchemeConditionParameters'
                matchValues: [
                  'HTTPS'
                ]
                operator: 'Equal'
                negateCondition: false
                transforms: []
              }
            }
          ]
          actions: [
            {
              name: 'ModifyResponseHeader'
              parameters: {
                typeName: 'DeliveryRuleHeaderActionParameters'
                headerAction: 'Append'
                headerName: 'Strict-Transport-Security'
                value: 'max-age=31536000; includeSubDomains; preload'
              }
            }
            {
              name: 'ModifyResponseHeader'
              parameters: {
                typeName: 'DeliveryRuleHeaderActionParameters'
                headerAction: 'Append'
                headerName: 'X-Content-Type-Options'
                value: 'nosniff'
              }
            }
            {
              name: 'ModifyResponseHeader'
              parameters: {
                typeName: 'DeliveryRuleHeaderActionParameters'
                headerAction: 'Append'
                headerName: 'X-Frame-Options'
                value: 'DENY'
              }
            }
            {
              name: 'ModifyResponseHeader'
              parameters: {
                typeName: 'DeliveryRuleHeaderActionParameters'
                headerAction: 'Append'
                headerName: 'Content-Security-Policy'
                value: "default-src 'self' https:; media-src 'self' https: data:; img-src 'self' https: data:; script-src 'self' https:; style-src 'self' 'unsafe-inline' https:;"
              }
            }
          ]
        }
        {
          name: 'CacheAudioFiles'
          order: 3
          conditions: [
            {
              name: 'RequestUri'
              parameters: {
                typeName: 'DeliveryRuleRequestUriConditionParameters'
                matchValues: [
                  '*.mp3'
                  '*.wav'
                  '*.m4a'
                ]
                operator: 'Any'
                negateCondition: false
                transforms: [
                  'Lowercase'
                ]
              }
            }
          ]
          actions: [
            {
              name: 'CacheExpiration'
              parameters: {
                typeName: 'DeliveryRuleCacheExpirationActionParameters'
                cacheBehavior: 'Override'
                cacheType: 'All'
                cacheDuration: '30.00:00:00' // 30 days for audio files
              }
            }
          ]
        }
      ]
    }
    geoFilters: []
    urlSigningKeys: []
  }
}

// Custom domain for HTTPS (optional, requires domain ownership verification)
resource customDomain 'Microsoft.Cdn/profiles/endpoints/customDomains@2023-05-01' = {
  parent: cdnEndpoint
  name: 'beeux-cdn-domain'
  properties: {
    hostName: '${cdnEndpoint.name}.azureedge.net'
    httpsParameters: {
      certificateSource: 'Cdn'
      protocolType: 'TLSv12'
      minimumTlsVersion: 'TLS12'
    }
  }
}

// Origin for the CDN endpoint
resource origin 'Microsoft.Cdn/profiles/endpoints/origins@2023-05-01' = {
  parent: cdnEndpoint
  name: 'storage-origin'
  properties: {
    hostName: storageAccountHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: storageAccountHostName
    priority: 1
    weight: 1000
    enabled: true
  }
}

// Outputs
output cdnProfileId string = cdnProfile.id
output cdnProfileName string = cdnProfile.name
output cdnEndpointId string = cdnEndpoint.id
output cdnEndpointName string = cdnEndpoint.name
output cdnEndpointHostName string = cdnEndpoint.properties.hostName
output httpsUrl string = 'https://${cdnEndpoint.properties.hostName}'
output customDomainHttpsUrl string = 'https://${customDomain.properties.hostName}'
