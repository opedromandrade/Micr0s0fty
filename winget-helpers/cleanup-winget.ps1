<#
.SYNOPSIS
    Cleans Winget’s local cache and temporary download folders.
.NOTES
    Requires admin rights because the cache lives under the system profile.
#>

$LogFolder = "$PSScriptRoot\logs"
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmm0s"
$LogFile   = Join-Path $LogFolder "cleanup-winget_$TimeStamp.log"

if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder | Out-Null }

function Write-Log {
    param([string]$Message)
    $entry = "$(Get-Date -Format 'u') | $Message"
    $entry | Tee-Object -FilePath $LogFile -Append
}

Write-Log "🧹 Starting Winget cache cleanup..."

# 1. Clean Winget's internal cache (if the command exists)
try {
    winget clean -h 2>&1 | Out-Null
    Write-Log "✅ winget clean succeeded."
} catch {
    Write-Log "⚠️ winget clean not available or failed: $_"
}

# 2. Delete the local cache folder
$CachePath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_*\LocalCache"
if (Test-Path $CachePath) {
    Get-ChildItem $CachePath -Recurse -Force -ErrorAction SilentlyContinue |
        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Write-Log "✅ Deleted Winget LocalCache at $CachePath"
} else {
    Write-Log "ℹ️ No LocalCache folder found."
}

Write-Log "🏁 Cleanup finished."
