<#
.SYNOPSIS
    Deploys Sysmon and Winlogbeat, configures security logging, and sends logs to Logstash.
.DESCRIPTION
    This script downloads Sysmon, Sysmon config, and Winlogbeat, installs them as services,
    enables security-related logs, and configures Winlogbeat to send logs to Logstash.
.PARAMETER LogstashIP
    The IP address of the Logstash server.
.PARAMETER LogstashPort
    The port of the Logstash server.
.EXAMPLE
    .\Deploy-Sysmon-Winlogbeat.ps1 -LogstashIP "192.168.1.100" -LogstashPort 5044
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$LogstashIP,

    [Parameter(Mandatory=$true)]
    [int]$LogstashPort
)

# Check for admin rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges. Please run as Administrator."
    exit 1
}

# Bypass execution policy for this script
Set-ExecutionPolicy Bypass -Scope Process -Force

# Define URLs for downloads
$SysmonURL = "https://download.sysinternals.com/files/Sysmon.zip"
$SysmonConfigURL = "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml"
$WinlogbeatURL = "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-8.12.0-windows-x86_64.zip"

# Define local paths
$TempDir = "$env:TEMP\SysmonWinlogbeat"
$SysmonZip = "$TempDir\Sysmon.zip"
$SysmonConfig = "$TempDir\sysmonconfig-export.xml"
$WinlogbeatZip = "$TempDir\winlogbeat.zip"
$WinlogbeatDir = "C:\Program Files\Winlogbeat\winlogbeat-8.12.0-windows-x86_64"

# Create temp directory
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force
}

# Download Sysmon
Write-Host "Downloading Sysmon..."
Invoke-WebRequest -Uri $SysmonURL -OutFile $SysmonZip
Expand-Archive -Path $SysmonZip -DestinationPath $TempDir -Force
$SysmonPath = "$TempDir\Sysmon64.exe"

# Download Sysmon config
Write-Host "Downloading Sysmon config..."
Invoke-WebRequest -Uri $SysmonConfigURL -OutFile $SysmonConfig

# Download Winlogbeat
Write-Host "Downloading Winlogbeat..."
Invoke-WebRequest -Uri $WinlogbeatURL -OutFile $WinlogbeatZip
Expand-Archive -Path $WinlogbeatZip -DestinationPath "C:\Program Files\Winlogbeat" -Force

# Install Sysmon
Write-Host "Installing Sysmon..."
& $SysmonPath -i $SysmonConfig -accepteula

# Enable security-related logs
Write-Host "Enabling security-related logs..."
# Enable RDP logins (TerminalServices-RemoteConnectionManager)
wevtutil sl "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational" /e:true
# Enable PowerShell logging
wevtutil sl "Microsoft-Windows-PowerShell/Operational" /e:true
# Enable Security log (already enabled by default, but ensure it's set to a large size)
wevtutil sl Security /ms:1073741824

# Configure Winlogbeat
Write-Host "Configuring Winlogbeat..."
$WinlogbeatConfig = @"
output.logstash:
  hosts: ["${LogstashIP}:${LogstashPort}"]

winlogbeat.event_logs:
  - name: Application
  - name: Security
  - name: System
  - name: "Microsoft-Windows-PowerShell/Operational"
  - name: "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational"
  - name: "Microsoft-Windows-Sysmon/Operational"
"@

$WinlogbeatConfig | Out-File -FilePath "$WinlogbeatDir\winlogbeat.yml" -Encoding ASCII -Force

# Install Winlogbeat as a service
Write-Host "Installing Winlogbeat as a service..."
Push-Location
cd "$WinlogbeatDir"
.\install-service-winlogbeat.ps1
Pop-Location

# Start Winlogbeat service
Write-Host "Starting Winlogbeat service..."
Start-Service winlogbeat

Write-Host "Deployment completed successfully!"