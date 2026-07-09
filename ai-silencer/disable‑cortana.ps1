<#
.SYNOPSIS
    Stops the Cortana background task, disables the service, and removes the Start‑Menu tile.
#>
$LogFolder = "$PSScriptRoot\logs"
$LogFile   = Join-Path $LogFolder ("disable-cortana_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder | Out-Null }

function Write-Log { param([string]$Msg) "$(Get-Date -Format 'u') | $Msg" | Tee-Object -FilePath $LogFile -Append }

Write-Log "🚀 Starting Cortana disable routine."

# 1. Stop the scheduled task (if present)
$taskName = "\Microsoft\Windows\Shell\EnableCortana"
if (Get-ScheduledTask -TaskPath $taskName -ErrorAction SilentlyContinue) {
    try {
        Unregister-ScheduledTask -TaskPath $taskName -Confirm:$false -ErrorAction Stop
        Write-Log "✅ Removed scheduled task $taskName."
    } catch { Write-Log "⚠️ Could not remove task: $_" }
}

# 2. Disable the Cortana background service (cortana.exe runs as a UWP app)
# The service is called "cortana" in the Windows Service container.
$svc = Get-Service -Name "cortana" -ErrorAction SilentlyContinue
if ($svc) {
    try {
        Stop-Service -Name "cortana" -Force -ErrorAction Stop
        Set-Service -Name "cortana" -StartupType Disabled -ErrorAction Stop
        Write-Log "✅ Stopped and disabled service 'cortana'."
    } catch { Write-Log "⚠️ Failed to stop/disable service: $_" }
}

# 3. Remove Cortana from the Start menu (registry tweak)
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage"
if (Test-Path $regPath) {
    try {
        Set-ItemProperty -Path $regPath -Name "FavoritesChanges" -Value 0 -ErrorAction Stop
        Write-Log "✅ Attempted to hide Cortana tile (registry flag set)."
    } catch { Write-Log "⚠️ Registry tweak failed: $_" }
}

Write-Log "✅ Cortana disable routine finished."
