<# SYNOPSIS
🛡️ Disable background services that most users never need.
⚙️ Reduces attack surface and eliminates unnecessary background data collection.
#>

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logDir = Join-Path $PSScriptRoot "logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
    $logPath = Join-Path $logDir "02‑Services‑Shuriken.log"
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
Write-Log "🚀  02‑Services‑Shuriken started."

# Services safe to disable for a typical desktop
$servicesToKill = @(
    # Cloud & sync
    "OneDrive",                 # Cloud storage sync
    "WSearch",                  # Search indexing (already stopped in script 1)
    # Advertising / telemetry
    "RetailDemo",               # Retail demo mode
    "dmwappushservice",         # Push notifications
    # Compatibility / legacy
    "Spooler",                  # Print Spooler (disable only if you never print)
    "Fax",                      # Fax service
    # Gaming / Xbox
    "XblGameSave",              # Xbox Live Game Save
    "XblAuthManager",           # Xbox Live Auth Manager
    "XboxGipSvc",               # Xbox Live Networking
    # Mixed Reality / Sensors
    "MixedRealityOpenXRVService",
    "SensorService",            # Sensors (if you have no hardware sensors)
    # Maps & location
    "MapsBroker",               # Windows Maps
    # Defender ancillary
    "WdNisSvc",                 # Defender Network Inspection Service (if using third‑party firewall)
    # Performance hogs
    "SysMain",                  # SuperFetch / SysMain
    "DcomLaunch",               # DCOM Server Process Launcher (only if you don’t use COM‑based apps)
    # Misc background tasks
    "WpcMonSvc",                # Windows Parental Controls Monitoring
    "PcaSvc",                   # Program Compatibility Assistant Service
    "Power"                     # Power Service (disable only on always‑plugged PCs)
)

foreach ($svc in $servicesToKill) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        Write-Log "🗡️  Stopping & disabling $svc"
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

Write-Log "✅ 02‑Services‑Shuriken completed."
