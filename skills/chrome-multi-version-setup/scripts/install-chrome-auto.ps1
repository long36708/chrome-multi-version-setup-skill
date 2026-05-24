# Non-interactive Chrome Installation Script (Auto-confirm)
param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$true)]
    [string]$InstallerPath,
    
    [string]$BaseDir = "D:\Chrome_Testing"
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Find-7Zip {
    $paths = @(
        "D:\Program Files\7-Zip\7z.exe",
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    return $null
}

function Extract-With7Zip {
    param(
        [string]$File,
        [string]$OutputDir
    )
    
    $7zPath = Find-7Zip
    if (-not $7zPath) {
        Write-Error-Custom "7-Zip not found. Please install from: https://www.7-zip.org/"
        exit 1
    }
    
    Write-Info "Extracting with 7-Zip: $File"
    Write-Info "7-Zip path: $7zPath"
    
    try {
        & $7zPath x $File -o"$OutputDir" -y | Out-Null
        Write-Success "Extraction completed: $OutputDir"
        return $true
    }
    catch {
        Write-Error-Custom "Extraction failed: $_"
        return $false
    }
}

function Create-Shortcut {
    param(
        [string]$ChromeExe,
        [string]$UserDataDir,
        [string]$Version,
        [string]$ShortcutsDir
    )
    
    $ShortcutFile = Join-Path $ShortcutsDir "Chrome_${Version}.lnk"
    
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
    $Shortcut.TargetPath = $ChromeExe
    $Shortcut.Arguments = "--user-data-dir=`"$UserDataDir`""
    $Shortcut.WorkingDirectory = Split-Path $ChromeExe
    $Shortcut.Save()
    
    Write-Success "Shortcut created: $ShortcutFile"
}

function Main {
    Write-Info "========================================="
    Write-Info "Chrome $Version Installer (Auto Mode)"
    Write-Info "========================================="
    
    # Check if installer exists
    if (-not (Test-Path $InstallerPath)) {
        Write-Error-Custom "Installer not found: $InstallerPath"
        exit 1
    }
    
    # Define directory structure
    $downloadsDir = Join-Path $BaseDir "downloads"
    $versionsDir = Join-Path $BaseDir "versions"
    $versionDir = Join-Path $versionsDir $Version
    $chromeBinDir = Join-Path $versionDir "Chrome-bin"
    $userDataDir = Join-Path $BaseDir "user_data\$Version"
    $shortcutsDir = Join-Path $BaseDir "shortcuts"
    
    Write-Info "Installation Configuration:"
    Write-Info "  Version: $Version"
    Write-Info "  Base Directory: $BaseDir"
    Write-Info "  Version Directory: $versionDir"
    Write-Info "  User Data Directory: $userDataDir"
    
    # Create necessary directories
    Write-Info "Creating directory structure..."
    @($downloadsDir, $versionsDir, $versionDir, $userDataDir, $shortcutsDir) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
    Write-Success "Directory structure created"
    
    # Copy installer to downloads directory
    $installerDest = Join-Path $downloadsDir (Split-Path $InstallerPath -Leaf)
    if (-not (Test-Path $installerDest)) {
        Copy-Item $InstallerPath $installerDest -Force
        Write-Info "Installer copied to: $installerDest"
    }
    
    # Create temporary working directory
    $workDir = Join-Path $env:TEMP "chrome-install-$Version"
    if (Test-Path $workDir) {
        Remove-Item $workDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    
    try {
        # Step 1: Extract installer
        Write-Info "Step 1/9: Extracting installer..."
        $extractedDir = Join-Path $workDir "extracted"
        if (-not (Extract-With7Zip -File $InstallerPath -OutputDir $extractedDir)) {
            exit 1
        }
        
        # Step 2: Find and extract updater.zip
        Write-Info "Step 2/9: Extracting updater.zip..."
        $updaterZip = Get-ChildItem $extractedDir -Filter "updater.zip" -Recurse | Select-Object -First 1
        
        if (-not $updaterZip) {
            Write-Error-Custom "updater.zip not found"
            exit 1
        }
        
        $updaterDir = Join-Path $workDir "updater"
        if (-not (Extract-With7Zip -File $updaterZip.FullName -OutputDir $updaterDir)) {
            exit 1
        }
        
        # Step 3: Find chrome_installer
        Write-Info "Step 3/9: Finding chrome_installer..."
        $offlineDir = Get-ChildItem $updaterDir -Filter "Offline" -Recurse -Directory | Select-Object -First 1
        
        if (-not $offlineDir) {
            Write-Error-Custom "Offline directory not found"
            exit 1
        }
        
        $chromeInstaller = Get-ChildItem $offlineDir.Parent.Parent -Filter "*installer*" -File | Select-Object -First 1
        
        if (-not $chromeInstaller) {
            Write-Error-Custom "chrome_installer file not found"
            exit 1
        }
        
        Write-Info "Found installer: $($chromeInstaller.Name)"
        
        # Step 4: Extract chrome_installer
        Write-Info "Step 4/9: Extracting chrome_installer..."
        $installerExtractDir = Join-Path $workDir "installer_extracted"
        if (-not (Extract-With7Zip -File $chromeInstaller.FullName -OutputDir $installerExtractDir)) {
            exit 1
        }
        
        # Step 5: Extract chrome.zip
        Write-Info "Step 5/9: Extracting chrome.zip..."
        $chromeZip = Get-ChildItem $installerExtractDir -Filter "chrome.zip" -Recurse | Select-Object -First 1
        
        if (-not $chromeZip) {
            Write-Error-Custom "chrome.zip not found"
            exit 1
        }
        
        $chromeBinTempDir = Join-Path $workDir "chrome_bin"
        if (-not (Extract-With7Zip -File $chromeZip.FullName -OutputDir $chromeBinTempDir)) {
            exit 1
        }
        
        # Step 6: Find Chrome-bin directory
        Write-Info "Step 6/9: Preparing installation directory..."
        $chromeBinFolder = Get-ChildItem $chromeBinTempDir -Filter "Chrome-bin" -Directory | Select-Object -First 1
        
        if (-not $chromeBinFolder) {
            Write-Error-Custom "Chrome-bin directory not found"
            exit 1
        }
        
        # Step 7: Copy files to versions directory
        Write-Info "Step 7/9: Copying Chrome files to $chromeBinDir..."
        Copy-Item "$($chromeBinFolder.FullName)\*" -Destination $chromeBinDir -Recurse -Force
        Write-Success "Files copied successfully"
        
        # Step 8: Verify installation
        $chromeExe = Join-Path $chromeBinDir "chrome.exe"
        if (Test-Path $chromeExe) {
            Write-Success "Chrome $Version installed successfully!"
            Write-Info "Executable: $chromeExe"
            
            # Get version info
            try {
                $versionInfo = & $chromeExe --version
                Write-Info "Version info: $versionInfo"
            }
            catch {
                Write-Info "Unable to get version info"
            }
        }
        else {
            Write-Error-Custom "Installation may have failed, chrome.exe not found"
            exit 1
        }
        
        # Step 9: Create shortcut
        Write-Info "Step 9/9: Creating shortcut..."
        Create-Shortcut -ChromeExe $chromeExe -UserDataDir $userDataDir -Version $Version -ShortcutsDir $shortcutsDir
        
        Write-Info "========================================="
        Write-Success "Installation Complete!"
        Write-Info "========================================="
        Write-Info ""
        Write-Info "Directory Structure:"
        Write-Info "  Version Files: $chromeBinDir"
        Write-Info "  User Data: $userDataDir"
        Write-Info "  Shortcut: $shortcutsDir\Chrome_${Version}.lnk"
        Write-Info ""
        Write-Info "Launch Command:"
        Write-Info "& `"$chromeExe`" --user-data-dir=`"$userDataDir`""
        
    }
    catch {
        Write-Error-Custom "Error during installation: $_"
        throw
    }
    finally {
        # Clean up temporary files
        if (Test-Path $workDir) {
            Write-Info "Cleaning up temporary files..."
            Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Main
