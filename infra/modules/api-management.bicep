@description('API Management service name')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('API Management SKU')
@allowed(['Developer', 'Standard', 'Premium'])
param sku string

@description('Container App FQDN for backend')
param containerAppFqdn string

@description('Web App hostname for frontend')
param webAppHostName string

@description('Enable private endpoints')
param enablePrivateEndpoints bool = false

@description('User assigned managed identity ID')
param userAssignedIdentityId string

@description('Application Insights ID')
param applicationInsightsId string

@description('Environment name')
param environmentName string

@description('Tags for resources')
param tags object = {}

// API Management service with HTTPS enforcement
resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
    capacity: 1
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    publisherEmail: 'admin@beeux.com'
    publisherName: 'Beeux Spelling Bee'
    notificationSenderEmail: 'noreply@beeux.com'
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: '${name}.azure-api.net'
        negotiateClientCertificate: sku == 'Premium' ? true : false
        defaultSslBinding: true
        certificateSource: 'BuiltIn'
      }
    ]
    customProperties: {
      // Disable older TLS versions - enforce TLS 1.2+
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'False'
      // Enable only secure ciphers
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA256': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256': 'False'
    }
    virtualNetworkType: enablePrivateEndpoints ? 'Internal' : 'None'
    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
  }
}

// API for Beeux Spelling Bee backend
resource beeuxApi 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apiManagement
  name: 'beeux-api'
  properties: {
    displayName: 'Beeux Spelling Bee API'
    description: 'RESTful API for the Beeux spelling bee application'
    serviceUrl: 'https://${containerAppFqdn}' // Force HTTPS backend
    path: 'api'
    protocols: ['https'] // HTTPS only - no HTTP
    subscriptionRequired: true
    apiVersion: 'v1'
    apiVersionSetId: apiVersionSet.id
  }
}

// API Version Set
resource apiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2023-05-01-preview' = {
  parent: apiManagement
  name: 'beeux-api-versions'
  properties: {
    displayName: 'Beeux API Versions'
    versioningScheme: 'Segment'
  }
}

// Global policies for HTTPS enforcement and security
resource globalPolicy 'Microsoft.ApiManagement/service/policies@2023-05-01-preview' = {
  parent: apiManagement
  name: 'policy'
  properties: {
    value: '''
      <policies>
        <inbound>
          <!-- Force HTTPS redirect -->
          <choose>
            <when condition="@(context.Request.OriginalUrl.Scheme != "https")">
              <return-response>
                <set-status code="301" reason="Moved Permanently" />
                <set-header name="Location" exists-action="override">
                  <value>@{
                    return "https://" + context.Request.OriginalUrl.Host + context.Request.OriginalUrl.PathAndQuery;
                  }</value>
                </set-header>
              </return-response>
            </when>
          </choose>
          
          <!-- Security headers -->
          <set-header name="Strict-Transport-Security" exists-action="override">
            <value>max-age=31536000; includeSubDomains; preload</value>
          </set-header>
          <set-header name="X-Content-Type-Options" exists-action="override">
            <value>nosniff</value>
          </set-header>
          <set-header name="X-Frame-Options" exists-action="override">
            <value>DENY</value>
          </set-header>
          <set-header name="X-XSS-Protection" exists-action="override">
            <value>1; mode=block</value>
          </set-header>
          <set-header name="Content-Security-Policy" exists-action="override">
            <value>default-src 'self' https:; script-src 'self' https:; style-src 'self' 'unsafe-inline' https:; img-src 'self' data: https:; connect-src 'self' https:; font-src 'self' https:; object-src 'none'; media-src 'self' https:; frame-src 'none';</value>
          </set-header>
          
          <!-- CORS configuration for HTTPS origins only -->
          <cors allow-credentials="false">
            <allowed-origins>
              <origin>https://${webAppHostName}</origin>
              <origin>https://${name}.azure-api.net</origin>
            </allowed-origins>
            <allowed-methods preflight-result-max-age="300">
              <method>GET</method>
              <method>POST</method>
              <method>PUT</method>
              <method>DELETE</method>
              <method>OPTIONS</method>
            </allowed-methods>
            <allowed-headers>
              <header>Content-Type</header>
              <header>Authorization</header>
              <header>X-Requested-With</header>
            </allowed-headers>
          </cors>
          
          <!-- Rate limiting -->
          <rate-limit-by-key calls="100" renewal-period="60" counter-key="@(context.Request.IpAddress)" />
          
          <!-- Request logging -->
          <log-to-eventhub logger-id="analytics-logger">
            @{
              return new JObject(
                new JProperty("timestamp", DateTime.UtcNow.ToString()),
                new JProperty("method", context.Request.Method),
                new JProperty("url", context.Request.Url.ToString()),
                new JProperty("scheme", context.Request.OriginalUrl.Scheme),
                new JProperty("clientIP", context.Request.IpAddress),
                new JProperty("userAgent", context.Request.Headers.GetValueOrDefault("User-Agent",""))
              ).ToString();
            }
          </log-to-eventhub>
        </inbound>
        <backend>
          <forward-request />
        </backend>
        <outbound>
          <!-- Ensure response headers for security -->
          <set-header name="Strict-Transport-Security" exists-action="override">
            <value>max-age=31536000; includeSubDomains; preload</value>
          </set-header>
        </outbound>
        <on-error>
          <set-header name="Strict-Transport-Security" exists-action="override">
            <value>max-age=31536000; includeSubDomains; preload</value>
          </set-header>
        </on-error>
      </policies>
    '''
  }
}

// Application Insights logger
resource appInsightsLogger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = {
  parent: apiManagement
  name: 'analytics-logger'
  properties: {
    loggerType: 'applicationInsights'
    resourceId: applicationInsightsId
    credentials: {
      instrumentationKey: reference(applicationInsightsId, '2020-02-02').InstrumentationKey
    }
  }
}

// HTTPS-only backend configuration
resource backend 'Microsoft.ApiManagement/service/backends@2023-05-01-preview' = {
  parent: apiManagement
  name: 'beeux-backend'
  properties: {
    description: 'Beeux Container App Backend (HTTPS only)'
    url: 'https://${containerAppFqdn}'
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
    credentials: {
      header: {}
      query: {}
    }
  }
}

// Subscription for API access
resource apiSubscription 'Microsoft.ApiManagement/service/subscriptions@2023-05-01-preview' = {
  parent: apiManagement
  name: 'beeux-frontend-subscription'
  properties: {
    displayName: 'Beeux Frontend Access'
    scope: '/apis/${beeuxApi.id}'
    state: 'active'
  }
}

// Named values for configuration
resource httpsOnlyNamedValue 'Microsoft.ApiManagement/service/namedValues@2023-05-01-preview' = {
  parent: apiManagement
  name: 'httpsOnly'
  properties: {
    displayName: 'HTTPS Only Mode'
    value: 'true'
    secret: false
  }
}

// Outputs
output id string = apiManagement.id
output name string = apiManagement.name
output gatewayUrl string = 'https://${apiManagement.properties.gatewayUrl}'
output portalUrl string = 'https://${apiManagement.properties.portalUrl}'
output managementApiUrl string = 'https://${apiManagement.properties.managementApiUrl}'
output subscriptionKey string = listSecrets(apiSubscription.id, '2023-05-01-preview').primaryKey
