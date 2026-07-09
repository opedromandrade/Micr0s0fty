<#
.SYNOPSIS
    Gives Cortana the silent treatment: stops its task, disables the service,
    and hides the tile so it never dares to whisper again. 🦗
#>

$LogFolder = "$PSScriptRoot\logs"
$LogFile   = Join-Path $LogFolder ("disable-cortana_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder | Out-Null }

function Write-Log { param([string]$Msg) "$(Get-Date -Format 'u') | $Msg" | Tee-Object -FilePath $LogFile -Append }

Write-Log "🚀 Kicking Cortana out of the house…"

# ① Kill the scheduled wake‑up call
$taskPath = "\Microsoft\Windows\Shell\EnableCortana"
if (Get-ScheduledTask -TaskPath $taskPath -ErrorAction SilentlyContinue) {
    try {
        Unregister-ScheduledTask -TaskPath $taskPath -Confirm:$false -ErrorAction Stop
        Write-Log "✅ Unregistered the sneaky scheduled task $taskPath."
    } catch { Write-Log "⚠️ Oops, could not unregister $taskPath: $_" }
}

# ② Stop & disable the service that keeps Cortana alive
$svc = Get-Service -Name "cortana" -ErrorAction SilentlyContinue
if ($svc) {
    try {
        Stop-Service -Name "cortana" -Force -ErrorAction Stop
        Set-Service -Name "cortana" -StartupType Disabled -ErrorAction Stop
        Write-Log "✅ Service 'cortana' stopped & disabled. Bye‑Felicia."
    } catch { Write-Log "⚠️ Service tango failed: $_" }
}

# ③ Hide the tile – a tiny registry tweak that tells Explorer “nope, not today”
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage"
if (Test-Path $regPath) {
    try {
        Set-ItemProperty -Path $regPath -Name "FavoritesChanges" -Value 0 -ErrorAction Stop
        Write-Log "✅ Cortana tile tucked away in the registry closet."
    } catch { Write-Log "⚠️ Registry magic fizzled: $_" }
}

Write-Log "🎉 Cortana is officially on a permanent coffee break."
