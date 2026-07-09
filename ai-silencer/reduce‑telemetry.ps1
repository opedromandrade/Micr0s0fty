<#
.SYNOPSIS
    Slashes Windows telemetry to the bone, disables the DiagTrack service,
    forces the “Basic” telemetry level, and wipes out a *barrage* of scheduled
    data‑collection tasks. Think of it as a privacy‑nuke with a smile. 😎
#>

$LogFolder = "$PSScriptRoot\logs"
$LogFile   = Join-Path $LogFolder ("reduce-telemetry_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder | Out-Null }
function Write-Log { param([string]$Msg) "$(Get-Date -Format 'u') | $Msg" | Tee-Object -FilePath $LogFile -Append }

Write-Log "🚀 Deploying telemetry‑reduction super‑laser…"

# -------------------------------------------------
# 1️⃣ DiagTrack service (the classic telemetry daemon)
# -------------------------------------------------
$svc = "DiagTrack"
if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction Stop
        Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
        Write-Log "✅ DiagTrack stopped and disabled."
    } catch { Write-Log "⚠️ DiagTrack rebelled: $_" }
}

# -------------------------------------------------
# 2️⃣ Registry tweak – AllowTelemetry = 0 (Basic)
# -------------------------------------------------
$telemetryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
if (-not (Test-Path $telemetryPath)) { New-Item -Path $telemetryPath -Force | Out-Null }

try {
    Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction Stop
    Write-Log "✅ Telemetry throttled to level 0 (Basic)."
} catch { Write-Log "⚠️ Failed to set telemetry level: $_" }

# -------------------------------------------------
# 3️⃣ Disable Customer Experience Improvement Program (CEIP)
# -------------------------------------------------
$ceipPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (-not (Test-Path $ceipPath)) { New-Item -Path $ceipPath -Force | Out-Null }

try {
    Set-ItemProperty -Path $ceipPath -Name "NoInstrumentation" -Value 1 -Type DWord -ErrorAction Stop
    Write-Log "✅ CEIP (aka creepy‑improvement‑program) disabled."
} catch { Write-Log "⚠️ CEIP tweak failed: $_" }

# -------------------------------------------------
# 4️⃣ Nuke *lots* of scheduled telemetry / data‑collection tasks
# -------------------------------------------------
$taskPaths = @(
    # Classic Customer‑Experience tasks
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",

    # Telemetry & diagnostics
    "\Microsoft\Windows\Diagnosis\RecommendedTroubleshooting",
    "\Microsoft\Windows\Diagnosis\Scheduled",
    "\Microsoft\Windows\Diagnosis\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Diagnosis\PUA\PUA-Policy",
    "\Microsoft\Windows\Feedback\Siuf\AutomaticAppUpdate",
    "\Microsoft\Windows\Feedback\Siuf\DmClient",

    # Updates & background scans (some folks prefer them off)
    "\Microsoft\Windows\UpdateOrchestrator\Reboot",
    "\Microsoft\Windows\UpdateOrchestrator\Schedule",
    "\Microsoft\Windows\UpdateOrchestrator\UpdateModel",

    # Data‑Collection “smart” tasks
    "\Microsoft\Windows\WDI\ResolutionHost",
    "\Microsoft\Windows\WDI\ResolutionHost\Resolution",

    # Advertising & personalization
    "\Microsoft\Windows\AdvertisingInfo\System",
    "\Microsoft\Windows\AdvertisingInfo\Automatic",
    
    # Misc “everything‑else‑kind‑of‑telemetry”
    "\Microsoft\Windows\Shell\FamilySafetyMonitor",
    "\Microsoft\Windows\Shell\FamilySafetyUi",
    "\Microsoft\Windows\Shell\PaintDesktop",
    "\Microsoft\Windows\Shell\NewAppCache",
    "\Microsoft\Windows\Shell\LockScreen",
    "\Microsoft\Windows\AppModel\Deploy\Registration",
    "\Microsoft\Windows\Time\AutomaticTimeZone",
    "\Microsoft\Windows\Time\SyncTime"
)

foreach ($tp in $taskPaths) {
    if (Get-ScheduledTask -TaskPath $tp -ErrorAction SilentlyContinue) {
        try {
            Unregister-ScheduledTask -TaskPath $tp -Confirm:$false -ErrorAction Stop
            Write-Log "✅ Zap! Removed scheduled task $tp"
        } catch {
            Write-Log "⚠️ Could not unregister $tp: $_"
        }
    } else {
        Write-Log "ℹ️ Task $tp not present on this system."
    }
}

Write-Log "🎉 Telemetry‑reduction mission accomplished. Your PC just became a lot less nosy."
