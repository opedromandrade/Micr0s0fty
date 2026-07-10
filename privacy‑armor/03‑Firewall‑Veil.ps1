<# SYNOPSIS
🛡️ Build a “stealth” Windows Firewall profile.
🚫 Block outbound traffic by default, whitelist essential Windows services, and explicitly block known telemetry endpoints.
#>

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logDir = Join-Path $PSScriptRoot "logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
    $logPath = Join-Path $logDir "03‑Firewall‑Veil.log"
    Add-Content -Path $logPath -Value "$timestamp  $Message"
    Write-Host $Message
}

# Must run as Administrator
if (-not ([Security.Principal.WindowsPrincipal]::new(
          [Security.Principal.WindowsIdentity]::GetCurrent()
      )).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "⚠️  Abort – script must be run from an elevated PowerShell."
    exit 1
}
Write-Log "🚀  03‑Firewall‑Veil started."

# Default to block everything
Write-Log "🛡️  Setting default firewall posture to Block"
Set-NetFirewallProfile -Profile Domain,Public,Private `
    -DefaultInboundAction Block -DefaultOutboundAction Block

# Essential outbound allow rules
$allowRules = @(
    @{Name="Core Network";      Protocol="TCP"; LocalPort="Any"; RemotePort="Any"},
    @{Name="DNS (UDP)";         Protocol="UDP"; LocalPort="53"; RemotePort="Any"},
    @{Name="DNS (TCP)";         Protocol="TCP"; LocalPort="53"; RemotePort="Any"},
    @{Name="DHCP (UDP)";        Protocol="UDP"; LocalPort="67,68"; RemotePort="Any"},
    @{Name="Windows Update";    Protocol="TCP"; LocalPort="Any"; RemotePort="80,443";
      RemoteAddress="13.107.0.0/16,13.76.0.0/16,172.217.0.0/16"},
    @{Name="Time Sync (NTP)";   Protocol="UDP"; LocalPort="123"; RemotePort="Any"},
    @{Name="Microsoft Store";   Protocol="TCP"; LocalPort="Any"; RemotePort="80,443";
      RemoteAddress="13.64.0.0/12"}
)

foreach ($r in $allowRules) {
    $params = @{
        DisplayName   = $r.Name
        Direction     = "Outbound"
        Action        = "Allow"
        Enabled       = "True"
        Protocol      = $r.Protocol
        LocalPort     = $r.LocalPort
        RemotePort    = $r.RemotePort
    }
    if ($r.RemoteAddress) { $params.RemoteAddress = $r.RemoteAddress }
    New-NetFirewallRule @params | Out-Null
    Write-Log "✅  Rule “$($r.Name)” added"
}

# Block known telemetry endpoints
$telemetryHosts = @(
    "vortex.data.microsoft.com",
    "settings-win.data.microsoft.com",
    "telemetry.microsoft.com",
    "watson.telemetry.microsoft.com",
    "collector.update.microsoft.com"
)

foreach ($host in $telemetryHosts) {
    $ips = Resolve-DnsName $host -ErrorAction SilentlyContinue |
           Where-Object {$_.IPAddress -match '\d+\.\d+\.\d+\.\d+'} |
           Select-Object -ExpandProperty IPAddress
    if ($ips) {
        New-NetFirewallRule -DisplayName "Block Telemetry → $host" `
            -Direction Outbound -Action Block -Enabled True `
            -RemoteAddress $ips -Protocol Any -Profile Any | Out-Null
        Write-Log "🚫  Telemetry host $host blocked"
    }
}

Write-Log "✅ 03‑Firewall‑Veil completed."