# =============================================================================
# INFRASTRUCTURE COMMAND LOGGING STANDARD - POWERSHELL MODULE
# =============================================================================
# Based on scsm-vault-server-setup-smart.sh logging standards
# Usage: . .\logging-standard-powershell.ps1 at the beginning of any PowerShell script
# =============================================================================

# Find project root by looking for script-execution.registry
$ProjectRoot = $PSScriptRoot
while (-not (Test-Path (Join-Path $ProjectRoot "script-execution.registry")) -and $ProjectRoot -ne (Split-Path $ProjectRoot -Parent)) {
    $ProjectRoot = Split-Path $ProjectRoot -Parent
}

# Ensure logs directory exists
$LogsDir = Join-Path $ProjectRoot "logs"
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

# Setup logging
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$ScriptName = Split-Path $PSCommandPath -Leaf
$LogFile = Join-Path $LogsDir "$($ScriptName -replace '\.[^.]*$', '')-$Timestamp.log"

# Set script start time
$Script:ScriptStartTime = Get-Date

# Script execution tracking function
function Track-ScriptExecution {
    param([int]$ExitCode = 0)
    
    $ScriptExecutionTracker = Join-Path $ProjectRoot "script-execution.registry"
    
    # Initialize registry file with headers if it doesn't exist
    if (-not (Test-Path $ScriptExecutionTracker)) {
        "TIMESTAMP|EXECUTION_ID|SCRIPT_NAME|SCRIPT_PATH|USER|WORKING_DIR|LOG_FILE|EXIT_CODE|DURATION|ORGNM|PLTNM|ENVNM" | Out-File -FilePath $ScriptExecutionTracker -Encoding UTF8
    }
    
    # Calculate execution duration
    $ScriptEndTime = Get-Date
    $ScriptDuration = [math]::Round(($ScriptEndTime - $Script:ScriptStartTime).TotalSeconds, 2)
    $ExecutionId = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$PID"
    
    # Capture environment variables (with defaults)
    $OrgName = if ($env:ORGNM) { $env:ORGNM } else { "UNKNOWN" }
    $PlatformName = if ($env:PLTNM) { $env:PLTNM } else { "UNKNOWN" }
    $EnvName = if ($env:ENVNM) { $env:ENVNM } else { "UNKNOWN" }
    
    # Log execution to registry
    $LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')|$ExecutionId|$(Split-Path $PSCommandPath -Leaf)|$PSCommandPath|$env:USERNAME|$(Get-Location)|$LogFile|$ExitCode|${ScriptDuration}s|$OrgName|$PlatformName|$EnvName"
    $LogEntry | Out-File -FilePath $ScriptExecutionTracker -Append -Encoding UTF8
}

# Setup logging function
function Setup-Logging {
    $HeaderMessage = @"
=============================================================================
📜 $(Split-Path $PSCommandPath -Leaf) - Infrastructure Command Logging Standard
=============================================================================
Script: $PSCommandPath
Log File: $LogFile
Timestamp: $(Get-Date)
=============================================================================

"@
    
    Write-Host $HeaderMessage
    $HeaderMessage | Out-File -FilePath $LogFile -Encoding UTF8
}

# Function to write output to both console and log file
function Write-LoggedOutput {
    param([string]$Message, [string]$Level = "INFO")
    
    $TimestampedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Host $TimestampedMessage
    $TimestampedMessage | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# Setup exit handler to track execution
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Track-ScriptExecution -ExitCode $LASTEXITCODE
} | Out-Null

# Export variables
$Global:ProjectRoot = $ProjectRoot
$Global:LogsDir = $LogsDir
$Global:LogFile = $LogFile
$Global:ScriptStartTime = $Script:ScriptStartTime