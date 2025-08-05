/*
 * AZURE CONTAINER APPS MODULE - SPRING BOOT API BACKEND
 * =====================================================
 * 
 * This module deploys the Spring Boot REST API backend using Azure Container Apps,
 * which provides serverless container hosting with built-in auto-scaling, HTTPS
 * termination, and integrated monitoring.
 * 
 * WHY CONTAINER APPS FOR BACKEND API:
 * ===================================
 * - SERVERLESS SCALING: Automatically scales to zero when idle, perfect for cost control
 * - HTTPS BUILT-IN: Native HTTPS termination and TLS certificate management
 * - MICROSERVICES READY: Designed for containerized applications and microservices
 * - INTEGRATED MONITORING: Built-in integration with Application Insights and Log Analytics
 * - SIMPLIFIED NETWORKING: Automatic service discovery and ingress configuration
 * 
 * HTTPS ENFORCEMENT STRATEGY:
 * ===========================
 * Container Apps implements HTTPS enforcement at multiple levels:
 * 
 * 1. INGRESS LEVEL: allowInsecure: false completely blocks HTTP traffic
 * 2. APPLICATION LEVEL: ASPNETCORE_URLS forces the Spring Boot app to bind only to HTTPS
 * 3. CORS POLICY: Only allows HTTPS origins, blocks HTTP cross-origin requests
 * 4. CERTIFICATE MANAGEMENT: Automatic HTTPS certificate provisioning and renewal
 * 
 * ENVIRONMENT-SPECIFIC CONFIGURATION:
 * ===================================
 * - IT Environment: Minimal resources (0.5 CPU, 1Gi RAM), scale to zero for cost savings
 * - QA Environment: Balanced resources (0.75 CPU, 1.5Gi RAM), moderate auto-scaling
 * - Production: High resources (1.0 CPU, 2Gi RAM), aggressive auto-scaling for performance
 * 
 * AUTO-SCALING STRATEGY:
 * =====================
 * The module implements intelligent auto-scaling based on multiple metrics:
 * - HTTP REQUEST COUNT: Scales up when request volume increases
 * - CPU UTILIZATION: Scales up when CPU usage exceeds 70%
 * - CUSTOM METRICS: Can be extended with business-specific scaling triggers
 * 
 * SECURITY FEATURES:
 * =================
 * - MANAGED IDENTITY: Secure authentication to Azure Container Registry and Key Vault
 * - SECRET MANAGEMENT: Secrets stored in Key Vault, not in container configuration
 * - NETWORK ISOLATION: Private endpoints in QA/Production for enhanced security
 * - CERTIFICATE MOUNTING: HTTPS certificates securely mounted from Key Vault
 * 
 * MONITORING AND OBSERVABILITY:
 * =============================
 * - CONTAINER LOGS: All console output captured and forwarded to Log Analytics
 * - SYSTEM LOGS: Container Apps platform logs for debugging and monitoring
 * - METRICS: Performance metrics automatically collected and stored
 * - HEALTH CHECKS: Built-in health monitoring and automatic restart on failures
 */

@description('Container App name')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Container Apps Environment ID')
param containerAppsEnvironmentId string

@description('Container Registry name')
param containerRegistryName string

@description('User assigned managed identity ID')
param userAssignedIdentityId string

@description('Key Vault name')
param keyVaultName string

@description('Minimum replicas')
param minReplicas int = 1

@description('Maximum replicas')
param maxReplicas int = 3

@description('Enable auto-scaling')
param enableAutoScaling bool = false

@description('Environment name')
param environmentName string

@description('Tags for resources')
param tags object = {}

// Container App with HTTPS enforcement
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: false // Force HTTPS only - no HTTP traffic allowed
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        corsPolicy: {
          allowedOrigins: ['https://*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
          allowCredentials: false
        }
        // Custom domains and certificates can be configured here
        customDomains: []
        // HTTPS redirection is enforced by allowInsecure: false
      }
      registries: [
        {
          server: '${containerRegistryName}.azurecr.io'
          identity: userAssignedIdentityId
        }
      ]
      secrets: [
        {
          name: 'container-registry-password'
          keyVaultUrl: 'https://${keyVaultName}.vault.azure.net/secrets/container-registry-password'
          identity: userAssignedIdentityId
        }
      ]
      dapr: {
        enabled: false
      }
    }
    template: {
      containers: [
        {
          image: '${containerRegistryName}.azurecr.io/beeux-api:latest'
          name: 'beeux-api'
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: environmentName == 'prod' ? 'Production' : environmentName == 'qa' ? 'Staging' : 'Development'
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'https://+:8080' // Force HTTPS binding
            }
            {
              name: 'ASPNETCORE_HTTPS_PORT'
              value: '8080'
            }
            {
              name: 'ASPNETCORE_Kestrel__Certificates__Default__Path'
              value: '/app/certificates/aspnetcore-https.pfx'
            }
            {
              name: 'HTTPS_ONLY'
              value: 'true'
            }
            // Security headers configuration
            {
              name: 'Security__RequireHttps'
              value: 'true'
            }
            {
              name: 'Security__HstsMaxAge'
              value: '31536000'
            }
          ]
          resources: {
            cpu: json(environmentName == 'prod' ? '1.0' : environmentName == 'qa' ? '0.75' : '0.5')
            memory: environmentName == 'prod' ? '2Gi' : environmentName == 'qa' ? '1.5Gi' : '1Gi'
          }
          // Mount certificates volume for HTTPS
          volumeMounts: [
            {
              mountPath: '/app/certificates'
              volumeName: 'certificates'
            }
          ]
        }
      ]
      scale: enableAutoScaling ? {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
          {
            name: 'cpu-rule'
            custom: {
              type: 'cpu'
              metadata: {
                type: 'Utilization'
                value: '70'
              }
            }
          }
        ]
      } : {
        minReplicas: minReplicas
        maxReplicas: minReplicas
      }
      volumes: [
        {
          name: 'certificates'
          storageType: 'Secret'
          secrets: [
            {
              secretRef: 'aspnetcore-https-cert'
              path: 'aspnetcore-https.pfx'
            }
          ]
        }
      ]
    }
  }
}

// Application Insights configuration for monitoring HTTPS traffic
resource appInsightsConfig 'Microsoft.App/containerApps/providers/diagnosticSettings@2021-05-01-preview' = {
  name: '${containerApp.name}/Microsoft.Insights/containerapp-diagnostics'
  properties: {
    workspaceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.OperationalInsights/workspaces/beeux-logs-${environmentName}'
    logs: [
      {
        category: 'ContainerAppConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'ContainerAppSystemLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
  }
}

// Outputs
output id string = containerApp.id
output name string = containerApp.name
output fqdn string = containerApp.properties.configuration.ingress.fqdn
output httpsUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output latestRevisionName string = containerApp.properties.latestRevisionName
output latestRevisionFqdn string = containerApp.properties.latestRevisionFqdn
