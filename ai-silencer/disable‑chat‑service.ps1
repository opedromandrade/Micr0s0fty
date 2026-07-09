<#
.SYNOPSIS
    Turns the “Chat” service off, optionally purges the Store app, and
    leaves a tidy log for future bragging rights. 📜
#>

$LogFolder = "$PSScriptRoot\logs"
$LogFile   = Join-Path $LogFolder ("disable-chat_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder | Out-Null }
function Write-Log { param([string]$Msg) "$(Get-Date -Format 'u') | $Msg" | Tee-Object -FilePath $LogFile -Append }

Write-Log "⚡️ Shutting down the Chat gremlin…"

$svc = "ChatService"
if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction Stop
        Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
        Write-Log "✅ Service $svc halted and disabled. No more AI chatter."
    } catch { Write-Log "⚠️ Could not silence $svc: $_" }
}

# Optional: yank the Store‑delivered app (uncomment if you’re feeling reckless)
# $pkg = "Microsoft.WindowsChat_8wekyb3d8bbwe"
# try {
#     Get-AppxPackage -Name $pkg | Remove-AppxPackage -ErrorAction Stop
#     Write-Log "✅ Appx package $pkg removed."
# } catch { Write-Log "⚠️ App removal hiccup: $_" }

Write-Log "🔇 Chat service is now as quiet as a library at midnight."
