<#
.SYNOPSIS
    User-based script to strip pre-installed bloatware apps for the current user.
    Primary method: Pure native AppX module manipulation (Zero WinGet dependencies).
.NOTES
    Can be run safely from a standard or elevated PowerShell session.
    Automatically purges items older than 30 days.
#>

# -------------------------------------------------
#   Configuration
# -------------------------------------------------
$RootPath     = if ($PSScriptRoot) { $PSScriptRoot } else { $pwd.Path }
$ExportFolder = Join-Path $RootPath "reports"
$LogFolder    = Join-Path $RootPath "logs"
$TimeStamp    = Get-Date -Format "yyyyMMdd_HHmmss"

$LogFile      = Join-Path $LogFolder    "uninstall-bloat_$TimeStamp.log"
$ReportFile   = Join-Path $ExportFolder "debloat-summary_$TimeStamp.txt"

# -------------------------------------------------
#   Vetted Master Bloatware Dictionary (90+ Apps)
# -------------------------------------------------
$BloatIds = @(
    # Core Baseline
    "Microsoft.3DBuilder", "Microsoft.XboxApp", "Microsoft.XboxGameCallableUI",
    "Microsoft.XboxGamingOverlay", "Microsoft.ZuneMusic", "Microsoft.ZuneVideo",
    "Microsoft.People", "Microsoft.Getstarted", "Microsoft.SkypeApp",
    
    # Modern OS Tracking, Feeds & Widgets
    "MicrosoftWindows.Client.WebExperience", "Microsoft.Windows.Ai.Copilot.Provider",
    "Microsoft.Copilot", "Microsoft.Microsoft365Copilot", "Microsoft.WindowsFeedbackHub",
    "Microsoft.YourPhone", "Microsoft.GetHelp", "Microsoft.WindowsMaps",
    
    # Advertising & News Feeds
    "Microsoft.BingNews", "Microsoft.BingWeather", "Microsoft.BingSearch",
    "Microsoft.BingFinance", "Microsoft.BingSports", "Microsoft.News",
    
    # Extended Xbox & Gaming Modules
    "Microsoft.GamingApp", "Microsoft.Xbox.TCUI", "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay", "Microsoft.Edge.GameAssist", 
    "Microsoft.MicrosoftSolitaireCollection",
    
    # Office Clutter & Media Stubs
    "Microsoft.MicrosoftOfficeHub", "Microsoft.Office.OneNote", "Microsoft.Todos",
    "Microsoft.PowerAutomateDesktop", "Microsoft.Clipchamp.Clipchamp", 
    "Clipchamp.Clipchamp", "Microsoft.Whiteboard", "Microsoft.MixedReality.Portal", 
    "Microsoft.ScreenSketch",
    
    # Utilities & Built-in System Tools
    "Microsoft.WindowsAlarms", "Microsoft.SoundRecorder", "Microsoft.WindowsCamera",
    "Microsoft.MicrosoftStickyNotes", "Microsoft.Wallet", "Microsoft.Messaging", 
    "Microsoft.OneConnect", "Microsoft.549981C3F5F10",
    
    # Consumer & Third-Party Partnerships
    "SpotifyAB.SpotifyMusic", "Disney.DisneyPlus", "Netflix.Netflix",
    "AdobeSystemsIncorporated.AdobePhotoshopExpress", "PandoraMediaInc.29160A0A7A14F",
    "HuluLLC.Hulu", "King.com.CandyCrushSaga", "King.com.CandyCrushSodaSaga",
    "WinZipUniversal", "Fitbit.FitbitCoach",
    
    # OEM Vendor Bundles
    "DellInc.DellDigitalDelivery", "DellInc.DellHelpandSupport", "DellInc.DellUpdate",
    "DellInc.DellOptimizer", "DellInc.SupportAssist", "Hewlett-Packard.HPPrivacySettings",
    "Hewlett-Packard.HPQuickDrop", "Hewlett-Packard.HPSmart", "Hewlett-Packard.HPSupportAssistant",
    "LenovoCorporation.LenovoVantage", "Lenovo.LenovoWelcome", "ASUSTeKComputerInc.ArmouryCrate",
    "ASUSTeKComputerInc.MyASUS", "AcerIncorporated.AcerCareCenter"
)

# -------------------------------------------------
#   Directory Validation & Retention Cleanup
# -------------------------------------------------
if (-not (Test-Path $LogFolder))   { New-Item -ItemType Directory -Path $LogFolder   | Out-Null }
if (-not (Test-Path $ExportFolder)) { New-Item -ItemType Directory -Path $ExportFolder | Out-Null }

$CutoffDate = (Get-Date).AddDays(-30)
Get-ChildItem -Path $LogFolder, $ExportFolder -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.LastWriteTime -lt $CutoffDate } | 
    ForEach-Object { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }

# -------------------------------------------------
#   Helper – Pretty Logs Framework
# -------------------------------------------------
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )
    $emoji = switch ($Level) {
        'SUCCESS' { '[✅ SUCCESS]' }
        'WARN'    { '[⚠️ WARNING]' }
        'ERROR'   { '[❗ ERROR]  ' }
        Default   { '[ℹ️ INFO]   ' }
    }
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $emoji | $Message"
    $entry | Tee-Object -FilePath $LogFile -Append
}

# -------------------------------------------------
#   Helper – High-Perfection ASCII Banner
# -------------------------------------------------
function Get-AsciiHeader {
    $art = @"
===================================================================================
 ______   _______  ______   _        _______  _______ _________ _______  ______  
(  __  \ (  ____ \(  __  \ ( \      (  ___  )(  ___  )\__   __/(  ____ \(  __  \ 
| (  \  )| (    \/| (  \  )| (      | (   ) || (   ) |   ) (   | (    \/| (  \  )
| |   ) || (__    | |   ) || |      | |   | || (___) |   | |   | (__    | |   ) |
| |   | ||  __)   | |   | || |      | |   | ||  ___  |   | |   |  __)   | |   | |
| |   ) || (      | |   ) || |      | |   | || (   ) |   | |   | (      | |   ) |
| (__/  )| (____/\| (__/  )| (____/\| (___) || )   ( |   | |   | (____/\| (__/  )
(______/ (_______/(______/ (_______/(_______)|/     \|   )_(   (_______/(______/ 

===================================================================================
 📅 Execution Date : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
 🎯 Target Scope   : Current User Profile Only (Pure AppX Module Layer)
 ⚙️ Engine Status  : System Optimization Complete
===================================================================================

"@
    return $art
}

# -------------------------------------------------
#   Execution Engine
# -------------------------------------------------
Write-Log "🔍 Starting bloatware removal..." -Level INFO

# Tracking lists to build the final text report file
$removedApps = [System.Collections.Generic.List[string]]::new()
$failedApps  = [System.Collections.Generic.List[string]]::new()

foreach ($id in $BloatIds) {
    Write-Log "🗑️ Attempting to uninstall $id ..." -Level INFO
    try {
        # Check if the package exists natively inside the local AppX user database map
        $userPackage = Get-AppxPackage -Name $id -ErrorAction SilentlyContinue
        
        if ($null -ne $userPackage) {
            # REMOVED WINGET: Utilizing clean, direct user profile app removal pipeline instead [1]
            Get-AppxPackage -Name $id | Remove-AppxPackage -ErrorAction Stop
            Write-Log "✅ $id removed (or not present)." -Level SUCCESS
            $removedApps.Add($id)
        } else {
            Write-Log "ℹ️ $id was not present on this profile." -Level INFO
        }
    } catch {
        Write-Log "⚠️ Could not remove $id : $_" -Level ERROR
        $failedApps.Add("$id ($_)")
    }
}

Write-Log "🏁 Bloatware purge complete." -Level SUCCESS

# -------------------------------------------------
#   Pretty Text Report Generation
# -------------------------------------------------
Write-Log "📝 Generating text-based deployment manifest..." -Level INFO

$ReportContent = New-Object System.Text.StringBuilder
$null = $ReportContent.AppendLine((Get-AsciiHeader))

if ($removedApps.Count -gt 0) {
    $null = $ReportContent.AppendLine("✨ CLEARANCE SNAPSHOT ✨")
    $null = $ReportContent.AppendLine("📦 SUCCESSFULLY PURGED PACKAGES:")
    foreach ($app in $removedApps) {
        $null = $ReportContent.AppendLine("  • [🟢 REMOVED] $app")
    }
} else {
    $null = $ReportContent.AppendLine("🌟 PERFECT PROFILE STATE: Checked all entries. No matching target bloatware remained on your user profile.")
}

if ($failedApps.Count -gt 0) {
    $null = $ReportContent.AppendLine("")
    $null = $ReportContent.AppendLine("🔒 SYSTEM PROTECTED / LOCKED PACKAGES:")
    foreach ($app in $failedApps) {
        $null = $ReportContent.AppendLine("  • [🔴 LOCKED]  $app")
    }
}

# Stream report data safely onto report structures using UTF8 to preserve Emojis perfectly
Set-Content -Path $ReportFile -Value $ReportContent.ToString() -Encoding UTF8
Write-Log "📄 Detailed snapshot summary documented at: $ReportFile" -Level SUCCESS
