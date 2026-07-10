<# SYNOPSIS
📌 Reduce Windows telemetry to the absolute minimum.
🔧 Safe for most desktop installations; does not break core OS functionality.
#>

# --------------------------------------------------------------------
# Log helper – writes to console AND to privacy‑armor.log (same folder)
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logDir = Join-Path $PSScriptRoot "logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
    $logPath = Join-Path $logDir "01‑Telemetry‑Ninja.log"
    Add-Content -Path $logPath -Value "$timestamp  $Message"
    Write-Host $Message
}
# --------------------------------------------------------------------
# Must run as Administrator
if (-not ([Security.Principal.WindowsPrincipal]::new(
          [Security.Principal.WindowsIdentity]::GetCurrent()
      )).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "⚠️  Abort – script must be run from an elevated PowerShell."
    exit 1
}
Write-Log "🚀  01‑Telemetry‑Ninja started."

function Set-Registry {
    param($Path, $Name, $Value)
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
}

Write-Log "🔧 Applying telemetry‑related registry tweaks…"

# Core telemetry switches
Set-Registry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" `
              "AllowTelemetry" 0
Set-Registry "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
              "AllowTelemetry" 0

# Additional privacy‑focused keys
Set-Registry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
              "EnableActivityFeed" 0
Set-Registry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
              "ShowTelemetryOptionalFeatures" 0
Set-Registry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" `
              "Enabled" 0
Set-Registry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
              "DisableCEIP" 1
Set-Registry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
              "AllowDeviceHealthTelemetry" 0
Set-Registry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
              "DiagnosticData" 0
Set-Registry "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
              "PublishUserActivities" 0

# Stop telemetry‑related services
$telemetrySvcs = @(
    "DiagTrack",          # Connected User Experiences & Telemetry
    "dmwappushservice",   # Push notifications
    "WpnUserService",     # Windows Push Notifications (often telemetry)
    "OneSyncSvc",         # Sync service (optional)
    "SysMain",            # SuperFetch – frequently disabled for privacy
    "WSearch"             # Search indexing (can leak metadata)
)

foreach ($svc in $telemetrySvcs) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        Write-Log "🛑 Stopping & disabling $svc"
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

Write-Log "✅ 01‑Telemetry‑Ninja completed."
