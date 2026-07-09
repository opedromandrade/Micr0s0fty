<#
.SYNOPSIS
    Disables Windows Copilot (the AI sidebar) by removing its Registry entries,
    stopping the associated background service, and deleting the Start‑Menu tile.
#>
$LogFolder = "$PSScriptRoot\logs"
$LogFile   = Join-Path $LogFolder ("disable-copilot_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder | Out-Null }
function Write-Log { param([string]$Msg) "$(Get-Date -Format 'u') | $Msg" | Tee-Object -FilePath $LogFile -Append }

Write-Log "🚀 Starting Copilot disable routine."

# 1. Stop the Copilot background service (if present)
$svcName = "WindowsCopilotServer"
if (Get-Service -Name $svcName -ErrorAction SilentlyContinue) {
    try {
        Stop-Service -Name $svcName -Force -ErrorAction Stop
        Set-Service -Name $svcName -StartupType Disabled -ErrorAction Stop
        Write-Log "✅ Stopped and disabled service $svcName."
    } catch { Write-Log "⚠️ Service $svcName could not be stopped/disabled: $_" }
}

# 2. Remove Copilot tab registration (registry)
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FeatureControl\FEATURE_AUTO_TAB_CREATION"
if (Test-Path $regPath) {
    try {
        Remove-ItemProperty -Path $regPath -Name "Copilot" -ErrorAction SilentlyContinue
        Write-Log "✅ Removed Copilot feature flag from registry."
    } catch { Write-Log "⚠️ Registry cleanup failed: $_" }
}

# 3. Delete the Start‑Menu tile (if it exists)
$tilePath = "$env:LOCALAPPDATA\Microsoft\Windows\InboxApps\CopilotApp"
if (Test-Path $tilePath) {
    try {
        Remove-Item -Path $tilePath -Recurse -Force -ErrorAction Stop
        Write-Log "✅ Deleted Copilot tile folder."
    } catch { Write-Log "⚠️ Could not delete tile folder: $_" }
}

Write-Log "✅ Copilot disable routine finished."
