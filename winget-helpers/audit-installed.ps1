<#
.SYNOPSIS
    Create both emoji-enriched CSV and ASCII-art TXT inventories of apps.
    Outputs are sorted alphabetically by application name.
    Primary method: `winget export` → JSON with flat file conversions.
.NOTES
    Run from an elevated PowerShell session.
    Automatically purges items older than 30 days.
#>

# -------------------------------------------------
#   Configuration
# -------------------------------------------------
$RootPath     = if ($PSScriptRoot) { $PSScriptRoot } else { $pwd.Path }
$ExportFolder = Join-Path $RootPath "reports"
$LogFolder    = Join-Path $RootPath "logs"
$TimeStamp    = Get-Date -Format "yyyyMMdd_HHmmss"

$CsvPath  = Join-Path $ExportFolder "winget-inventory_$TimeStamp.csv"
$TxtPath  = Join-Path $ExportFolder "winget-inventory_$TimeStamp.txt"
$LogPath  = Join-Path $LogFolder    "audit-winget_$TimeStamp.log"

# -------------------------------------------------
#   Helper – Pretty Logging
# -------------------------------------------------
if (-not (Test-Path $LogFolder))   { New-Item -ItemType Directory -Path $LogFolder   | Out-Null }
if (-not (Test-Path $ExportFolder)) { New-Item -ItemType Directory -Path $ExportFolder | Out-Null }

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
    $entry | Tee-Object -FilePath $LogPath -Append
}

# -------------------------------------------------
#   Helper – Dynamic Emoji Mapping
# -------------------------------------------------
function Get-AppEmoji {
    param([string]$Id, [string]$Name)
    $lowerId = $Id.ToLower()
    $lowerName = $Name.ToLower()

    if ($lowerId -match 'python|git|powertoys|docker|vscode|visualstudio|terminal|developer|sdk|node') { return "💻" } # Dev/Sys Tools
    if ($lowerId -match 'browser|chrome|edge|firefox|opera|brave|vivaldi') { return "🌐" }                          # Browsers
    if ($lowerId -match 'discord|teams|zoom|slack|whatsapp|messenger|telegram') { return "💬" }                     # Chat/Comms
    if ($lowerId -match 'spotify|vlc|music|video|player|plex|netflix|obs') { return "🎵" }                          # Media
    if ($lowerId -match 'office|excel|word|notion|adobe|reader|pdf|7zip|winrar') { return "📄" }                    # Office/Utility
    if ($lowerId -match 'steam|epic|xbox|game|gog|origin') { return "🎮" }                                          # Gaming
    if ($lowerId -match 'nvidia|amd|intel|driver|hardware|logitech') { return "⚙️" }                                # Drivers/Hardware
    return "📦"                                                                                                     # Generic App
}

# -------------------------------------------------
#   Helper – ASCII Art Title Generator
# -------------------------------------------------
function Get-AsciiHeader {
    $art = @"
========================================================================
 __          __ _         __      __             _                    
 \ \        / /(_)        \ \    / /            | |                   
  \ \  /\  / /  _  _ __    \ \  / /___  _ __  _ | |_  ___   _ __  _   _ 
   \ \/  \/ /  | || '_ \    \ \/ // _ \| '__|| \| __|/ _ \ | '__|| | | |
    \  /\  /   | || | | |    \  /|  __/| |   | | |_| (_) | |     | |_| |
     \/  \/    |_||_| |_|     \/  \___||_|   |_|\__|\___/|_|      \__, |
                                                                   __/ |
                                                                  |___/ 
========================================================================
 Inventory Created : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
 Target Scope      : WinGet Managed Repository Sources Only
 Status            : Verified Consistent & Alphabetized
========================================================================

"@
    return $art
}


Write-Log "Initializing automated WinGet asset tracking pipeline." -Level INFO

# -------------------------------------------------
#   Retention Cleanup (Older than 30 Days)
# -------------------------------------------------
Write-Log "Scanning directories for files older than 30 days..." -Level INFO
$CutoffDate = (Get-Date).AddDays(-30)

$TargetPaths = @($ExportFolder, $LogFolder)
$PurgeCount  = 0

foreach ($Target in $TargetPaths) {
    if (Test-Path $Target) {
        $ExpiredFiles = Get-ChildItem -Path $Target -File | Where-Object { $_.LastWriteTime -lt $CutoffDate }
        foreach ($File in $ExpiredFiles) {
            try {
                Remove-Item $File.FullName -Force -ErrorAction Stop
                $PurgeCount++
            }
            catch {
                Write-Log "Failed to purge obsolete file: $($File.Name) ($($_.Exception.Message))" -Level WARN
            }
        }
    }
}
if ($PurgeCount -gt 0) {
    Write-Log "Retention check complete. Purged $PurgeCount expired file(s)." -Level SUCCESS
} else {
    Write-Log "Retention check complete. No expired files found." -Level INFO
}

# -------------------------------------------------
#   1️⃣ Primary Engine – Winget JSON Parser
# -------------------------------------------------
$tempJson = [IO.Path]::GetTempFileName()
try {
    winget export --source winget --output $tempJson --include-versions --accept-source-agreements 2>$null

    if (Test-Path $tempJson) {
        $jsonContent = Get-Content $tempJson -Raw
        $data = $jsonContent | ConvertFrom-Json
        $packages = $data.Sources.Packages
        
        if ($null -ne $packages -and $packages.Count -gt 0) {
            Write-Log "WinGet parsed metadata accurately. found $($packages.Count) managed installations." -Level SUCCESS
            
            # Map object dataset, SORT, and prepend categorical emojis
            $normalizedOutput = $packages | ForEach-Object {
                $rawId   = $_.PackageIdentifier
                $rawName = $_.PackageIdentifier.Split('.')[-1]
                $ico     = Get-AppEmoji -Id $rawId -Name $rawName
                
                [PSCustomObject]@{
                    Type      = $ico
                    Name      = $rawName
                    Id        = $rawId
                    Version   = $_.PackageVersion
                    Publisher = $_.PackageIdentifier.Split('.')[0]
                }
            } | Sort-Object Name

            # Export #1: CSV Document Structure with dedicated Type Emoji column
            $normalizedOutput | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
            Write-Log "Structured alphabetical CSV catalog generated at: $CsvPath" -Level SUCCESS

            # Export #2: Pretty-aligned TXT Document View with an ASCII header banner
            $asciiHeader = Get-AsciiHeader
            $tableData = $normalizedOutput | Format-Table -AutoSize | Out-String
            
            Set-Content -Path $TxtPath -Value ($asciiHeader + $tableData) -Encoding UTF8
            Write-Log "Readable alphabetical TXT snapshot generated at: $TxtPath" -Level SUCCESS

            Remove-Item $tempJson -Force
            exit 0
        }
        else {
            Write-Log "WinGet engine emitted an empty manifest block." -Level WARN
        }
    }
}
catch {
    Write-Log "Core script module failure: ($($_.Exception.Message)). Dropping down to fallback loop." -Level ERROR
}
finally {
    if (Test-Path $tempJson) { Remove-Item $tempJson -Force }
}

# -------------------------------------------------
#   2️⃣ Emergency Fallback Engine – Text Intercept
# -------------------------------------------------
Write-Log "Executing textual fall-back diagnostic scrape." -Level WARN

$raw = winget list --source winget --accept-source-agreements 2>$null

if ($raw) {
    $cleanLines = $raw | Where-Object { $_ -match '\S' }
    
    # Process text output, skip header fields, inject emoji attributes, and sort
    $fallbackObjects = $cleanLines | Select-Object -Skip 2 | ForEach-Object {
        $parts = $_ -split '\s{2,}'
        if ($parts.Count -ge 3) {
            $rawId   = $parts[1].Trim()
            $rawName = $parts[0].Trim()
            $ico     = Get-AppEmoji -Id $rawId -Name $rawName

            [PSCustomObject]@{
                Type      = $ico
                Name      = $rawName
                Id        = $rawId
                Version   = $parts[2].Trim()
                Publisher = $rawId.Split('.')[0]
            }
        }
    } | Sort-Object Name

    if ($fallbackObjects.Count -gt 0) {
        # Fallback Export #1: CSV
        $fallbackObjects | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Fallback alphabetical CSV approximation built successfully." -Level SUCCESS

        # Fallback Export #2: Pretty TXT layout with ASCII title
        $asciiHeader = Get-AsciiHeader
        $tableData = $fallbackObjects | Format-Table -AutoSize | Out-String
        
        Set-Content -Path $TxtPath -Value ($asciiHeader + $tableData) -Encoding UTF8
        Write-Log "Fallback alphabetical TXT snapshot built successfully." -Level SUCCESS
    } else {
        Write-Log "Fallback loop failed to extract meaningful text tokens." -Level ERROR
        exit 1
    }
}
else {
    Write-Log "Terminal execution breakdown. WinGet interface was totally unreachable." -Level ERROR
    exit 1
}
