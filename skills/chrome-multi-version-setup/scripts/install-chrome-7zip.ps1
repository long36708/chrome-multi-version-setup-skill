# 基于 7-Zip 的 Chrome 多版本安装脚本（支持自定义路径）
# 使用方法:
#   .\install-chrome-7zip.ps1 -Version "127.0.6533.120" -InstallerPath "C:\Downloads\chrome_127.exe" -InstallBaseDir "D:\ChromeVersions" -DataBaseDir "D:\ChromeData"

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,

    [Parameter(Mandatory=$true)]
    [string]$InstallerPath,

    [string]$InstallBaseDir = "",

    [string]$DataBaseDir = "",

    [switch]$NoAdmin
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

function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-7Zip {
    $paths = @(
        "C:\Program Files\7-Zip\7z.exe",
        "D:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe",
        "D:\Program Files (x86)\7-Zip\7z.exe",
        "$env:ProgramFiles\7-Zip\7z.exe"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

function Check-DiskSpace {
    param(
        [string]$Path,
        [long]$RequiredMB = 500
    )

    try {
        $driveLetter = [System.IO.Path]::GetPathRoot($Path)
        $drive = Get-PSDrive $driveLetter.TrimEnd('\')

        $freeSpaceMB = [math]::Round($drive.Free / 1MB, 2)

        if ($drive.Free -lt ($RequiredMB * 1MB)) {
            Write-Warning-Custom "磁盘空间不足: ${driveLetter} 可用空间 ${freeSpaceMB} MB，需要至少 ${RequiredMB} MB"
            return $false
        }

        Write-Info "磁盘空间检查通过: ${driveLetter} 可用 ${freeSpaceMB} MB"
        return $true
    }
    catch {
        Write-Warning-Custom "无法检查磁盘空间，继续执行..."
        return $true
    }
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
        [string]$Version
    )

    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    $ShortcutFile = Join-Path $DesktopPath "Chrome $Version.lnk"

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
    Write-Info "Chrome $Version 安装程序 (7-Zip 方法)"
    Write-Info "========================================="

    # 检查管理员权限（仅在安装到 Program Files 时需要）
    $requiresAdmin = $false
    if ($InstallBaseDir -match "^C:\\Program Files") {
        $requiresAdmin = $true
        if (-not (Test-Administrator)) {
            Write-Error-Custom "安装到 Program Files 需要管理员权限，请以管理员身份运行"
            exit 1
        }
    }
    elseif (-not $NoAdmin -and -not (Test-Administrator)) {
        Write-Warning-Custom "当前没有管理员权限，如果安装到受保护目录可能会失败"
    }

    # 检查安装包是否存在
    if (-not (Test-Path $InstallerPath)) {
        Write-Error-Custom "安装包不存在: $InstallerPath"
        exit 1
    }

    # 确定安装路径
    $versionNumber = $Version.Split('.')[0]

    if ([string]::IsNullOrWhiteSpace($InstallBaseDir)) {
        # 默认使用 D 盘，如果 D 盘不存在则使用用户目录
        if (Test-Path "D:\") {
            $InstallBaseDir = "D:\ChromeVersions"
        }
        else {
            $InstallBaseDir = Join-Path $env:USERPROFILE "Apps\ChromeVersions"
            Write-Warning-Custom "D 盘不存在，使用用户目录作为默认路径"
        }
    }

    if ([string]::IsNullOrWhiteSpace($DataBaseDir)) {
        if (Test-Path "D:\") {
            $DataBaseDir = "D:\ChromeData"
        }
        else {
            $DataBaseDir = Join-Path $env:USERPROFILE "Apps\ChromeData"
        }
    }

    $installDir = Join-Path $InstallBaseDir "Chrome${versionNumber}"
    $appDir = Join-Path $installDir "Application"
    $userDataDir = Join-Path $DataBaseDir "Chrome${versionNumber}"

    # 显示配置并等待确认
    Write-Host ""
    Write-Host "安装配置:" -ForegroundColor Cyan
    Write-Host "  版本: $Version" -ForegroundColor White
    Write-Host "  安装目录: $appDir" -ForegroundColor White
    Write-Host "  用户数据: $userDataDir" -ForegroundColor White
    Write-Host ""
    Write-Host "是否继续？(Y/N): " -NoNewline -ForegroundColor Yellow

    $confirm = Read-Host
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Info "安装已取消"
        exit 0
    }

    # 检查磁盘空间
    if (-not (Check-DiskSpace -Path $installDir -RequiredMB 500)) {
        Write-Error-Custom "磁盘空间不足，请选择其他路径"
        exit 1
    }

    Write-Info "安装目录: $appDir"
    Write-Info "用户数据: $userDataDir"

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

        $chromeBinDir = Join-Path $workDir "chrome_bin"
        if (-not (Extract-With7Zip -File $chromeZip.FullName -OutputDir $chromeBinDir)) {
            exit 1
        }

        # 步骤 6: 查找 Chrome-bin 目录
        Write-Info "步骤 6: 准备安装目录..."
        $chromeBinFolder = Get-ChildItem $chromeBinDir -Filter "Chrome-bin" -Directory | Select-Object -First 1

        if (-not $chromeBinFolder) {
            Write-Error-Custom "未找到 Chrome-bin 目录"
            exit 1
        }

        # 创建目标目录
        if (-not (Test-Path $appDir)) {
            New-Item -ItemType Directory -Path $appDir -Force | Out-Null
        }

        # 步骤 7: 复制文件
        Write-Info "步骤 7: 复制 Chrome 文件到 $appDir..."
        Copy-Item "$($chromeBinFolder.FullName)\*" -Destination $appDir -Recurse -Force
        Write-Success "文件复制完成"

        # 步骤 8: 创建用户数据目录
        if (-not (Test-Path $userDataDir)) {
            New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null
            Write-Success "创建用户数据目录: $userDataDir"
        }

        # 步骤 9: 验证安装
        $chromeExe = Join-Path $appDir "chrome.exe"
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

        # 步骤 10: 创建快捷方式
        Write-Info "步骤 10: 创建桌面快捷方式..."
        Create-Shortcut -ChromeExe $chromeExe -UserDataDir $userDataDir -Version $versionNumber

        Write-Info "========================================="
        Write-Success "安装完成！"
        Write-Info "========================================="
        Write-Info ""
        Write-Info "快捷方式已创建到桌面"
        Write-Info "快捷方式目标: $chromeExe --user-data-dir=`"$userDataDir`""
        Write-Info ""
        Write-Info "如需手动创建或修改快捷方式，请参考 SKILL.md"

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
