<# SYNOPSIS
🚫 Turn off IPv6 everywhere – no more “ghost” traffic leaking over the old protocol.
🧹 Keeps your network footprint tight and your firewall rules simpler.
#>

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logDir = Join-Path $PSScriptRoot "logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
    $logPath = Join-Path $logDir "04‑Disable‑IPv6.log"
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
Write-Log "🚀  04‑Disable‑IPv6 started."

# 1️⃣ Global registry toggle
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name "DisabledComponents" -Value 0xFF -Force
Write-Log "🔧 Set DisabledComponents = 0xFF (IPv6 disabled globally)."

# 2️⃣ Disable IPv6 on each physical adapter (netsh)
$adapters = Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Up"}
foreach ($adapter in $adapters) {
    Write-Log "🛑 Disabling IPv6 on interface: $($adapter.Name)"
    netsh interface ipv6 set interface "$($adapter.Name)" admin=disable | Out-Null
}

# 3️⃣ Verify the state (optional friendly output)
$stillEnabled = (Get-NetAdapterBinding -ComponentID ms_tcpip6 |
                Where-Object {$_.Enabled -eq $true}).Count
if ($stillEnabled -eq 0) {
    Write-Log "✅ IPv6 is now fully disabled on this machine."
} else {
    Write-Log "⚠️  $stillEnabled adapter(s) still report IPv6 enabled – a reboot may be required."
}

Write-Log "✅ 04‑Disable‑IPv6 completed."