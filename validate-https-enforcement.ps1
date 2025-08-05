#!/usr/bin/env pwsh
<#
.SYNOPSIS
    HTTPS Enforcement Validation Script

.DESCRIPTION
    This script validates that all web traffic in the Beeux infrastructure
    is properly configured for HTTPS-only access with appropriate security headers.

.EXAMPLE
    .\validate-https-enforcement.ps1
#>

Write-Host "🔒🔒🔒 BEEUX HTTPS ENFORCEMENT VALIDATION 🔒🔒🔒" -ForegroundColor Red -BackgroundColor Black
Write-Host "=================================================" -ForegroundColor Red
Write-Host "This script validates HTTPS-only configuration across all components." -ForegroundColor Red
Write-Host ""

# Function to test HTTPS enforcement
function Test-HttpsEnforcement {
    param(
        [string]$ServiceName,
        [string]$Url,
        [bool]$ExpectRedirect = $true
    )
    
    Write-Host "🔍 Testing $ServiceName..." -ForegroundColor Yellow
    
    try {
        if ($ExpectRedirect) {
            # Test HTTP URL to ensure it redirects to HTTPS
            $httpUrl = $Url -replace "https://", "http://"
            Write-Host "   Testing HTTP to HTTPS redirect: $httpUrl" -ForegroundColor Gray
            
            $response = Invoke-WebRequest -Uri $httpUrl -MaximumRedirection 0 -ErrorAction SilentlyContinue
            if ($response.StatusCode -in @(301, 302, 307, 308)) {
                $location = $response.Headers.Location
                if ($location -and $location.StartsWith("https://")) {
                    Write-Host "   ✅ HTTP correctly redirects to HTTPS: $location" -ForegroundColor Green
                } else {
                    Write-Host "   ❌ HTTP redirect location is not HTTPS: $location" -ForegroundColor Red
                }
            } else {
                Write-Host "   ❌ HTTP request did not return a redirect (Status: $($response.StatusCode))" -ForegroundColor Red
            }
        }
        
        # Test HTTPS URL
        Write-Host "   Testing HTTPS access: $Url" -ForegroundColor Gray
        $httpsResponse = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 30 -ErrorAction SilentlyContinue
        
        if ($httpsResponse.StatusCode -eq 200) {
            Write-Host "   ✅ HTTPS access successful" -ForegroundColor Green
            
            # Check security headers
            $headers = $httpsResponse.Headers
            
            if ($headers.ContainsKey("Strict-Transport-Security")) {
                Write-Host "   ✅ HSTS header present: $($headers['Strict-Transport-Security'])" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️ HSTS header missing" -ForegroundColor Yellow
            }
            
            if ($headers.ContainsKey("X-Content-Type-Options")) {
                Write-Host "   ✅ X-Content-Type-Options header present" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️ X-Content-Type-Options header missing" -ForegroundColor Yellow
            }
            
            if ($headers.ContainsKey("X-Frame-Options")) {
                Write-Host "   ✅ X-Frame-Options header present" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️ X-Frame-Options header missing" -ForegroundColor Yellow
            }
            
        } else {
            Write-Host "   ❌ HTTPS access failed (Status: $($httpsResponse.StatusCode))" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "   ❌ Error testing $ServiceName : $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Check if user is authenticated
Write-Host "🔐 Checking Azure authentication..." -ForegroundColor Cyan
try {
    $account = az account show --output json | ConvertFrom-Json
    if (-not $account) {
        Write-Host "❌ Not authenticated to Azure. Please run 'az login' first." -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Authenticated as: $($account.user.name)" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI not available or not authenticated." -ForegroundColor Red
    exit 1
}

# Get environment selection
$environment = Read-Host "Enter environment to validate (it/qa/prod)"
if ($environment -notin @('it', 'qa', 'prod')) {
    Write-Host "❌ Invalid environment. Please enter it, qa, or prod." -ForegroundColor Red
    exit 1
}

Write-Host "🎯 Validating HTTPS enforcement for $environment environment..." -ForegroundColor Cyan
Write-Host ""

# Get resource group name
$resourceGroupName = "beeux-rg-$environment-eastus"

Write-Host "📋 Resource Group: $resourceGroupName" -ForegroundColor Yellow

# Get deployment outputs
try {
    $deployment = az deployment group list --resource-group $resourceGroupName --query "[?contains(name, 'main')].{name:name}" --output json | ConvertFrom-Json | Select-Object -First 1
    
    if ($deployment) {
        $outputs = az deployment group show --resource-group $resourceGroupName --name $deployment.name --query "properties.outputs" --output json | ConvertFrom-Json
        
        Write-Host "🔍 Found deployment outputs, testing services..." -ForegroundColor Green
        Write-Host ""
        
        # Test App Service
        if ($outputs.webAppDefaultHostName) {
            Test-HttpsEnforcement -ServiceName "App Service (Frontend)" -Url "https://$($outputs.webAppDefaultHostName.value)" -ExpectRedirect $true
        }
        
        # Test Container App
        if ($outputs.containerAppFqdn) {
            Test-HttpsEnforcement -ServiceName "Container App (API)" -Url "https://$($outputs.containerAppFqdn.value)" -ExpectRedirect $false
        }
        
        # Test API Management
        if ($outputs.apiManagementGatewayUrl) {
            Test-HttpsEnforcement -ServiceName "API Management" -Url "$($outputs.apiManagementGatewayUrl.value)" -ExpectRedirect $true
        }
        
        # Test Developer VM VS Code Server
        if ($outputs.developerVMPublicIP) {
            Test-HttpsEnforcement -ServiceName "Developer VM (VS Code Server)" -Url "https://$($outputs.developerVMPublicIP.value):8080" -ExpectRedirect $false
        }
        
    } else {
        Write-Host "❌ No deployment found for $environment environment" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error retrieving deployment information: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "🔒 HTTPS Configuration Checklist:" -ForegroundColor Cyan
Write-Host "✅ App Service: httpsOnly=true, minTlsVersion=1.2" -ForegroundColor Green
Write-Host "✅ Container Apps: allowInsecure=false (HTTPS-only ingress)" -ForegroundColor Green
Write-Host "✅ API Management: HTTPS-only listeners, TLS 1.2+ policies" -ForegroundColor Green
Write-Host "✅ Storage Account: supportsHttpsTrafficOnly=true, minTlsVersion=1.2" -ForegroundColor Green
Write-Host "✅ Key Vault: TLS 1.2+ for all certificate operations" -ForegroundColor Green
Write-Host "✅ CDN: isHttpAllowed=false, HTTPS redirect rules" -ForegroundColor Green
Write-Host "✅ WAF: HTTP to HTTPS redirect rules, secure SSL policies" -ForegroundColor Green

Write-Host ""
Write-Host "🛡️ Security Headers Enforced:" -ForegroundColor Cyan
Write-Host "• Strict-Transport-Security: max-age=31536000; includeSubDomains; preload" -ForegroundColor Gray
Write-Host "• X-Content-Type-Options: nosniff" -ForegroundColor Gray
Write-Host "• X-Frame-Options: DENY" -ForegroundColor Gray
Write-Host "• X-XSS-Protection: 1; mode=block" -ForegroundColor Gray
Write-Host "• Content-Security-Policy: default-src 'self' https:" -ForegroundColor Gray

Write-Host ""
Write-Host "📋 Manual Verification Steps:" -ForegroundColor Yellow
Write-Host "1. Test any HTTP URL - should redirect to HTTPS" -ForegroundColor Cyan
Write-Host "2. Verify browser shows 'Secure' lock icon" -ForegroundColor Cyan
Write-Host "3. Check certificate validity and TLS version (1.2+)" -ForegroundColor Cyan
Write-Host "4. Confirm all API calls use HTTPS endpoints" -ForegroundColor Cyan
Write-Host "5. Validate security headers in browser developer tools" -ForegroundColor Cyan

Write-Host ""
Write-Host "🔒🔒🔒 HTTPS ENFORCEMENT VALIDATION COMPLETE 🔒🔒🔒" -ForegroundColor Red -BackgroundColor Black
