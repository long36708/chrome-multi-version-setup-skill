# 基于 7-Zip 的 Chrome 多版本安装脚本（使用集中式架构）
# 使用方法: 
#   .\install-chrome-structured.ps1 -Version "127.0.6533.120" -InstallerPath "C:\Downloads\chrome_127.exe" -BaseDir "D:\Chrome_Testing"

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$true)]
    [string]$InstallerPath,
    
    [string]$BaseDir = ""
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

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Find-7Zip {
    $paths = @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe",
        "$env:ProgramFiles\7-Zip\7z.exe"
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
        Write-Error-Custom "未找到 7-Zip，请先安装: https://www.7-zip.org/"
        exit 1
    }
    
    Write-Info "使用 7-Zip 解压: $File"
    
    try {
        & $7zPath x $File -o"$OutputDir" -y | Out-Null
        Write-Success "解压完成: $OutputDir"
        return $true
    }
    catch {
        Write-Error-Custom "解压失败: $_"
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
    
    Write-Success "创建快捷方式: $ShortcutFile"
}

function Main {
    Write-Info "========================================="
    Write-Info "Chrome $Version 安装程序 (集中式架构)"
    Write-Info "========================================="
    
    # 检查安装包是否存在
    if (-not (Test-Path $InstallerPath)) {
        Write-Error-Custom "安装包不存在: $InstallerPath"
        exit 1
    }
    
    # 确定根目录
    if ([string]::IsNullOrWhiteSpace($BaseDir)) {
        if (Test-Path "D:\") {
            $BaseDir = "D:\Chrome_Testing"
        }
        else {
            $BaseDir = Join-Path $env:USERPROFILE "Chrome_Testing"
            Write-Warning-Custom "D 盘不存在，使用用户目录作为默认路径"
        }
    }
    
    # 定义目录结构
    $downloadsDir = Join-Path $BaseDir "downloads"
    $versionsDir = Join-Path $BaseDir "versions"
    $versionDir = Join-Path $versionsDir $Version
    $chromeBinDir = Join-Path $versionDir "Chrome-bin"
    $userDataDir = Join-Path $BaseDir "user_data\$Version"
    $shortcutsDir = Join-Path $BaseDir "shortcuts"
    
    # 显示配置并等待确认
    Write-Host ""
    Write-Host "安装配置:" -ForegroundColor Cyan
    Write-Host "  版本: $Version" -ForegroundColor White
    Write-Host "  根目录: $BaseDir" -ForegroundColor White
    Write-Host "  版本目录: $versionDir" -ForegroundColor White
    Write-Host "  数据目录: $userDataDir" -ForegroundColor White
    Write-Host ""
    Write-Host "是否继续？(Y/N): " -NoNewline -ForegroundColor Yellow
    
    $confirm = Read-Host
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Info "安装已取消"
        exit 0
    }
    
    # 创建必要的目录结构
    Write-Info "创建目录结构..."
    @($downloadsDir, $versionsDir, $versionDir, $userDataDir, $shortcutsDir) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
    Write-Success "目录结构创建完成"
    
    # 复制安装包到 downloads 目录（可选）
    $installerDest = Join-Path $downloadsDir (Split-Path $InstallerPath -Leaf)
    if (-not (Test-Path $installerDest)) {
        Copy-Item $InstallerPath $installerDest -Force
        Write-Info "安装包已复制到: $installerDest"
    }
    
    # 创建临时工作目录
    $workDir = Join-Path $env:TEMP "chrome-install-$Version"
    if (Test-Path $workDir) {
        Remove-Item $workDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    
    try {
        # 步骤 1: 解压安装包
        Write-Info "步骤 1: 解压安装包..."
        $extractedDir = Join-Path $workDir "extracted"
        if (-not (Extract-With7Zip -File $InstallerPath -OutputDir $extractedDir)) {
            exit 1
        }
        
        # 步骤 2: 查找并解压 updater.zip
        Write-Info "步骤 2: 解压 updater.zip..."
        $updaterZip = Get-ChildItem $extractedDir -Filter "updater.zip" -Recurse | Select-Object -First 1
        
        if (-not $updaterZip) {
            Write-Error-Custom "未找到 updater.zip"
            exit 1
        }
        
        $updaterDir = Join-Path $workDir "updater"
        if (-not (Extract-With7Zip -File $updaterZip.FullName -OutputDir $updaterDir)) {
            exit 1
        }
        
        # 步骤 3: 查找 chrome_installer
        Write-Info "步骤 3: 查找 chrome_installer..."
        $offlineDir = Get-ChildItem $updaterDir -Filter "Offline" -Recurse -Directory | Select-Object -First 1
        
        if (-not $offlineDir) {
            Write-Error-Custom "未找到 Offline 目录"
            exit 1
        }
        
        $chromeInstaller = Get-ChildItem $offlineDir.Parent.Parent -Filter "*${Version}*installer*" -File | Select-Object -First 1
        
        if (-not $chromeInstaller) {
            Write-Error-Custom "未找到 chrome_installer 文件"
            exit 1
        }
        
        Write-Info "找到 installer: $($chromeInstaller.Name)"
        
        # 步骤 4: 解压 chrome_installer
        Write-Info "步骤 4: 解压 chrome_installer..."
        $installerExtractDir = Join-Path $workDir "installer_extracted"
        if (-not (Extract-With7Zip -File $chromeInstaller.FullName -OutputDir $installerExtractDir)) {
            exit 1
        }
        
        # 步骤 5: 解压 chrome.zip
        Write-Info "步骤 5: 解压 chrome.zip..."
        $chromeZip = Get-ChildItem $installerExtractDir -Filter "chrome.zip" -Recurse | Select-Object -First 1
        
        if (-not $chromeZip) {
            Write-Error-Custom "未找到 chrome.zip"
            exit 1
        }
        
        $chromeBinTempDir = Join-Path $workDir "chrome_bin"
        if (-not (Extract-With7Zip -File $chromeZip.FullName -OutputDir $chromeBinTempDir)) {
            exit 1
        }
        
        # 步骤 6: 查找 Chrome-bin 目录
        Write-Info "步骤 6: 准备安装目录..."
        $chromeBinFolder = Get-ChildItem $chromeBinTempDir -Filter "Chrome-bin" -Directory | Select-Object -First 1
        
        if (-not $chromeBinFolder) {
            Write-Error-Custom "未找到 Chrome-bin 目录"
            exit 1
        }
        
        # 步骤 7: 复制文件到 versions 目录
        Write-Info "步骤 7: 复制 Chrome 文件到 $chromeBinDir..."
        Copy-Item "$($chromeBinFolder.FullName)\*" -Destination $chromeBinDir -Recurse -Force
        Write-Success "文件复制完成"
        
        # 步骤 8: 验证安装
        $chromeExe = Join-Path $chromeBinDir "chrome.exe"
        if (Test-Path $chromeExe) {
            Write-Success "Chrome $Version 安装成功！"
            Write-Info "可执行文件: $chromeExe"
            
            # 获取版本信息
            try {
                $versionInfo = & $chromeExe --version
                Write-Info "版本信息: $versionInfo"
            }
            catch {
                Write-Info "无法获取版本信息"
            }
        }
        else {
            Write-Error-Custom "安装可能失败，未找到 chrome.exe"
            exit 1
        }
        
        # 步骤 9: 创建快捷方式
        Write-Info "步骤 9: 创建快捷方式..."
        Create-Shortcut -ChromeExe $chromeExe -UserDataDir $userDataDir -Version $Version -ShortcutsDir $shortcutsDir
        
        Write-Info "========================================="
        Write-Success "安装完成！"
        Write-Info "========================================="
        Write-Info ""
        Write-Info "目录结构:"
        Write-Info "  版本文件: $chromeBinDir"
        Write-Info "  用户数据: $userDataDir"
        Write-Info "  快捷方式: $shortcutsDir\Chrome_${Version}.lnk"
        Write-Info ""
        Write-Info "启动命令:"
        Write-Info "& `"$chromeExe`" --user-data-dir=`"$userDataDir`""
        
    }
    finally {
        # 清理临时文件
        if (Test-Path $workDir) {
            Write-Info "清理临时文件..."
            Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Main
