<#
.SYNOPSIS
    Updates all Winget‑installed apps silently.
.NOTES
    Requires admin rights.
#>

$LogFolder = "$PSScriptRoot\logs"
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile   = Join-Path $LogFolder "update-all_$TimeStamp.log"

if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder | Out-Null }

function Write-Log {
    param([string]$Message)
    $entry = "$(Get-Date -Format 'u') | $Message"
    $entry | Tee-Object -FilePath $LogFile -Append
}

Write-Log "🚀 Starting global update..."

try {
    winget upgrade --all --silent --accept-source-agreements `
        --accept-package-agreements -h 2>&1 | Tee-Object -FilePath $LogFile -Append
    Write-Log "✅ All upgrades completed."
} catch {
    Write-Log "❗ Update process failed: $_"
    exit 1
}