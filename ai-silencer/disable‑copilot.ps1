<#
.SYNOPSIS
    Removes Windows Copilot from the cockpit: stops its daemon, erases the UI
    and smashes the registry flag. The AI side‑kick never sees the sky again. 🌥️
#>

$LogFolder = "$PSScriptRoot\logs"
$LogFile   = Join-Path $LogFolder ("disable-copilot_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder | Out-Null }
function Write-Log { param([string]$Msg) "$(Get-Date -Format 'u') | $Msg" | Tee-Object -FilePath $LogFile -Append }

Write-Log "🚀 Initiating Copilot ejection sequence…"

# ① Kill the background service
$svcName = "WindowsCopilotServer"
if (Get-Service -Name $svcName -ErrorAction SilentlyContinue) {
    try {
        Stop-Service -Name $svcName -Force -ErrorAction Stop
        Set-Service -Name $svcName -StartupType Disabled -ErrorAction Stop
        Write-Log "✅ Service $svcName stopped & disabled."
    } catch { Write-Log "⚠️ Service $svcName gave a tantrum: $_" }
}

# ② Clear the feature‑flag registry entry (if it exists)
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FeatureControl\FEATURE_AUTO_TAB_CREATION"
if (Test-Path $regPath) {
    try {
        Remove-ItemProperty -Path $regPath -Name "Copilot" -ErrorAction SilentlyContinue
        Write-Log "✅ Removed Copilot flag from $regPath."
    } catch { Write-Log "⚠️ Registry pruning failed: $_" }
}

# ③ Delete the Start‑Menu tile (the eye‑candy)
$tilePath = "$env:LOCALAPPDATA\Microsoft\Windows\InboxApps\CopilotApp"
if (Test-Path $tilePath) {
    try {
        Remove-Item -Path $tilePath -Recurse -Force -ErrorAction Stop
        Write-Log "✅ Copilot tile shredded."
    } catch { Write-Log "⚠️ Tile demolition aborted: $_" }
}

Write-Log "🛬 Copilot has safely crash‑landed on the moon."
