<#
.SYNOPSIS
    Deactivates the Windows “Chat” service that powers the AI chat experience.
#>
$LogFolder = "$PSScriptRoot\logs"
$LogFile   = Join-Path $LogFolder ("disable-chat_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder | Out-Null }
function Write-Log { param([string]$Msg) "$(Get-Date -Format 'u') | $Msg" | Tee-Object -FilePath $LogFile -Append }

Write-Log "🚀 Starting Windows Chat service disable routine."

$svc = "ChatService"
if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction Stop
        Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
        Write-Log "✅ Stopped and disabled $svc."
    } catch { Write-Log "⚠️ Could not stop/disable $svc: $_" }
}

# Remove the Chat UWP package (optional, uncomment if you want it gone completely)
# $package = "Microsoft.WindowsChat_8wekyb3d8bbwe"
# try {
#     Get-AppxPackage -Name $package | Remove-AppxPackage -ErrorAction Stop
#     Write-Log "✅ Removed Appx package $package."
# } catch { Write-Log "⚠️ Could not remove Appx package: $_" }

Write-Log "✅ Windows Chat disable routine finished."
