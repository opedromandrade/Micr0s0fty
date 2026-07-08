<#
.SYNOPSIS
    Uninstalls a predefined set of pre‑installed Microsoft apps.
.NOTES
    Run as admin; some packages may be protected on certain editions.
#>

$BloatIds = @(
    "Microsoft.3DBuilder",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameCallableUI",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.People",
    "Microsoft.Getstarted",
    "Microsoft.SkypeApp"
)

$LogFolder = "$PSScriptRoot\logs"
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile   = Join-Path $LogFolder "uninstall-bloat_$TimeStamp.log"

if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder | Out-Null }

function Write-Log {
    param([string]$Message)
    $entry = "$(Get-Date -Format 'u') | $Message"
    $entry | Tee-Object -FilePath $LogFile -Append
}

Write-Log "🔍 Starting bloatware removal..."

foreach ($id in $BloatIds) {
    Write-Log "🗑️ Attempting to uninstall $id ..."
    try {
        winget uninstall --id $id --silent --accept-source-agreements `
            --accept-package-agreements -h 2>&1 | Out-Null
        Write-Log "✅ $id removed (or not present)."
    } catch {
        Write-Log "⚠️ Could not remove $id : $_"
    }
}

Write-Log "🏁 Bloatware purge complete."
