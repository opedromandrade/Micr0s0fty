<# 
.SYNOPSIS
    Installs multiple Winget packages listed in packages.txt.
.DESCRIPTION
    Reads each line of packages.txt (one Winget package ID per line) and runs
    winget install silently with automatic source‑agreement acceptance.
.NOTES
    Run this script from an elevated PowerShell session.
#>

# ----- Paths ---------------------------------------------------------
$PackageFile = "$PSScriptRoot\packages.txt"   # one Winget ID per line
$LogFolder    = "$PSScriptRoot\logs"
$TimeStamp    = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile      = Join-Path $LogFolder "install-batch_$TimeStamp.log"

# ----- Prepare logging ------------------------------------------------
if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder | Out-Null }

function Write-Log {
    param([string]$Message)
    $entry = "$(Get-Date -Format 'u') | $Message"
    $entry | Tee-Object -FilePath $LogFile -Append
}

# ----- Verify packages.txt exists ------------------------------------
if (-not (Test-Path $PackageFile)) {
    Write-Log "❌ packages.txt not found at $PackageFile – aborting."
    exit 1
}

Write-Log "🚀 Starting app installation. Feel free to grab a coffee."

# ----- Load the list of apps (as objects for easy access) -------------
$apps = Get-Content $PackageFile | ForEach-Object {
    $id = $_.Trim()
    if ($id) { [pscustomobject]@{ name = $id } }
}

# ----- Process each app ------------------------------------------------
Foreach ($app in $apps) {
    # Query Winget for an exact match (quiet, no headers)
    $listApp = winget list --exact -q $app.name 2>$null

    # If the output contains the app name, it’s already installed
    if ([String]::Join("", $listApp).Contains($app.name)) {
        Write-Host "Skipping $($app.name) (app already installed)"
        Write-Log "ℹ️ $($app.name) – app already installed"
    }
    else {
        Write-Host "Installing $($app.name)"
        Write-Log "🔧 Installing $($app.name)"
        try {
            winget install -e -h --accept-source-agreements `
                --accept-package-agreements --id $app.name 2>$null
            Write-Log "✅ Successfully installed $($app.name)"
        }
        catch {
            Write-Log "❗ Failed to install $($app.name) : $_"
        }
    }
}

Write-Log "🏁 Bulk‑install run complete."