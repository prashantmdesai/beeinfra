#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Setup script for Developer VM SSH access

.DESCRIPTION
    This script helps users set up SSH keys and environment variables
    required for the Developer VM functionality in all environments.

.EXAMPLE
    .\setup-developer-vm-access.ps1
#>

Write-Host "🔐🔐🔐 DEVELOPER VM ACCESS SETUP 🔐🔐🔐" -ForegroundColor Cyan -BackgroundColor Black
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "This script will help you set up SSH access for Developer VMs in all environments." -ForegroundColor Cyan
Write-Host ""

# Check if SSH key already exists
$sshKeyPath = "$env:USERPROFILE\.ssh\id_rsa"
$sshPublicKeyPath = "$env:USERPROFILE\.ssh\id_rsa.pub"

if (Test-Path $sshPublicKeyPath) {
    Write-Host "✅ SSH key pair found at: $sshKeyPath" -ForegroundColor Green
    
    # Read the public key
    $publicKey = Get-Content $sshPublicKeyPath -Raw
    $publicKey = $publicKey.Trim()
    
    Write-Host "🔑 Your SSH public key:" -ForegroundColor Yellow
    Write-Host "$publicKey" -ForegroundColor Gray
    Write-Host ""
    
    $useExisting = Read-Host "Do you want to use this existing SSH key? (y/n)"
    
    if ($useExisting -eq 'y' -or $useExisting -eq 'Y' -or $useExisting -eq '') {
        Write-Host "✅ Using existing SSH key" -ForegroundColor Green
    } else {
        Write-Host "Creating new SSH key..." -ForegroundColor Yellow
        $generateNew = $true
    }
} else {
    Write-Host "🔑 No SSH key found. Generating new SSH key pair..." -ForegroundColor Yellow
    $generateNew = $true
}

if ($generateNew) {
    # Ensure .ssh directory exists
    $sshDir = "$env:USERPROFILE\.ssh"
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
        Write-Host "📁 Created SSH directory: $sshDir" -ForegroundColor Green
    }
    
    # Generate SSH key pair
    Write-Host "🔨 Generating SSH key pair..." -ForegroundColor Yellow
    
    $email = Read-Host "Enter your email address for the SSH key"
    if ([string]::IsNullOrEmpty($email)) {
        $email = "developer@beeux.com"
    }
    
    # Use ssh-keygen to generate the key pair
    $generateCommand = "ssh-keygen -t rsa -b 4096 -C `"$email`" -f `"$sshKeyPath`" -N `"`""
    
    try {
        Invoke-Expression $generateCommand
        Write-Host "✅ SSH key pair generated successfully!" -ForegroundColor Green
        
        # Read the newly generated public key
        $publicKey = Get-Content $sshPublicKeyPath -Raw
        $publicKey = $publicKey.Trim()
        
        Write-Host "🔑 Your new SSH public key:" -ForegroundColor Yellow
        Write-Host "$publicKey" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Failed to generate SSH key. Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "💡 Please ensure OpenSSH is installed and available in PATH" -ForegroundColor Cyan
        exit 1
    }
}

Write-Host ""
Write-Host "📝 Setting up environment variables..." -ForegroundColor Yellow

# Set the SSH_PUBLIC_KEY environment variable
Write-Host "Setting SSH_PUBLIC_KEY environment variable..." -ForegroundColor Gray

try {
    # Set for current session
    $env:SSH_PUBLIC_KEY = $publicKey
    
    # Set permanently for the user
    [Environment]::SetEnvironmentVariable("SSH_PUBLIC_KEY", $publicKey, "User")
    
    Write-Host "✅ SSH_PUBLIC_KEY environment variable set successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to set environment variable. Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 You may need to run this script as Administrator" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🎯 Quick verification:" -ForegroundColor Cyan
Write-Host "SSH Public Key: $($publicKey.Substring(0, 50))..." -ForegroundColor Gray
Write-Host "Environment Variable: $($env:SSH_PUBLIC_KEY.Substring(0, 50))..." -ForegroundColor Gray

Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Green
Write-Host "1. You can now deploy environments with Developer VMs" -ForegroundColor Cyan
Write-Host "2. Run startup scripts to deploy environments:" -ForegroundColor Cyan
Write-Host "   • IT: .\infra\scripts\startup\complete-startup-it.ps1" -ForegroundColor White
Write-Host "   • QA: .\infra\scripts\startup\complete-startup-qa.ps1" -ForegroundColor White
Write-Host "   • Prod: .\infra\scripts\startup\complete-startup-prod.ps1" -ForegroundColor White
Write-Host "3. After deployment, use the provided SSH command or VS Code URL to access your VM" -ForegroundColor Cyan

Write-Host ""
Write-Host "🔐 SSH Connection Info:" -ForegroundColor Yellow
Write-Host "Private Key: $sshKeyPath" -ForegroundColor Gray
Write-Host "Public Key: $sshPublicKeyPath" -ForegroundColor Gray
Write-Host "Username: devuser" -ForegroundColor Gray

Write-Host ""
Write-Host "💡 Tips:" -ForegroundColor Cyan
Write-Host "• Keep your private key secure and never share it" -ForegroundColor Gray
Write-Host "• Each VM comes with VS Code Server accessible via HTTPS" -ForegroundColor Gray
Write-Host "• All development tools are pre-installed (Azure CLI, Git, Docker, etc.)" -ForegroundColor Gray
Write-Host "• VMs have managed identity access to Azure resources in their environment" -ForegroundColor Gray
Write-Host "• VS Code Server runs on HTTPS://VM_IP:8080 for secure web access" -ForegroundColor Gray
Write-Host "• All Azure service connections from VMs use HTTPS/TLS encryption" -ForegroundColor Gray

Write-Host ""
Write-Host "🔐🔐🔐 DEVELOPER VM ACCESS SETUP COMPLETE 🔐🔐🔐" -ForegroundColor Cyan -BackgroundColor Black
