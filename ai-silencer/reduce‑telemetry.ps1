<#
.SYNOPSIS
    Lowers the amount of data Windows sends to Microsoft:
      • Disables Diagnostic Tracking Service (DiagTrack)
      • Turns off Data Collection for Windows 10/11
      • Sets Telemetry to “Basic” (Level 0)
#>
$LogFolder = "$PSScriptRoot\logs"
$LogFile   = Join-Path $LogFolder ("reduce-telemetry_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder | Out-Null }
function Write-Log { param([string]$Msg) "$(Get-Date -Format 'u') | $Msg" | Tee-Object -FilePath $LogFile -Append }

Write-Log "🚀 Starting telemetry reduction routine."

# 1. Disable the DiagTrack service
$svc = "DiagTrack"
if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction Stop
        Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
        Write-Log "✅ Stopped and disabled DiagTrack service."
    } catch { Write-Log "⚠️ Could not stop/disable DiagTrack: $_" }
}

# 2. Registry keys that control telemetry level (0 = basic, 1 = enhanced, 2 = full)
$telemetryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
if (-not (Test-Path $telemetryPath)) { New-Item -Path $telemetryPath -Force | Out-Null }

try {
    Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction Stop
    Write-Log "✅ Telemetry level set to 0 (Basic)."
} catch { Write-Log "⚠️ Failed to set telemetry level: $_" }

# 3. Turn off “Customer Experience Improvement Program”
$ceipPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (-not (Test-Path $ceipPath)) { New-Item -Path $ceipPath -Force | Out-Null }

try {
    Set-ItemProperty -Path $ceipPath -Name "NoInstrumentation" -Value 1 -Type DWord -ErrorAction Stop
    Write-Log "✅ Disabled Customer Experience Improvement Program."
} catch { Write-Log "⚠️ CEIP registry tweak failed: $_" }

# 4. Disable background data collection scheduled tasks (a few common ones)
$taskNames = @(
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\KernelCEIPTask"
)
foreach ($t in $taskNames) {
    if (Get-ScheduledTask -TaskPath $t -ErrorAction SilentlyContinue) {
        try {
            Unregister-ScheduledTask -TaskPath $t -Confirm:$false -ErrorAction Stop
            Write-Log "✅ Removed scheduled task $t."
        } catch { Write-Log "⚠️ Could not remove task $t: $_" }
    }
}

Write-Log "✅ Telemetry reduction routine finished."
