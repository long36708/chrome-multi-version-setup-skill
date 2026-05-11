# Chrome 版本启动脚本
# 使用方法: .\launch-chrome.ps1 -Version "127" -Url "https://example.com" -InstallBaseDir "D:\ChromeVersions" -DataBaseDir "D:\ChromeData"

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [string]$Url,
    
    [string]$InstallBaseDir = "",
    
    [string]$DataBaseDir = "",
    
    [switch]$Incognito,
    
    [switch]$Headless,
    
    [switch]$DevTools,
    
    [int]$RemoteDebuggingPort,
    
    [switch]$CreateShortcut
)

$ErrorActionPreference = "Continue"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Get-ChromeVersion {
    param([string]$ChromeExe)
    
    try {
        $Version = & $ChromeExe --version
        return $Version.Trim()
    }
    catch {
        return "未知版本"
    }
}

function Create-DesktopShortcut {
    param(
        [string]$ChromeExe,
        [string]$UserDataDir,
        [string]$VersionName
    )
    
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    $ShortcutFile = Join-Path $DesktopPath "Chrome $VersionName.lnk"
    
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
    $Shortcut.TargetPath = $ChromeExe
    $Shortcut.Arguments = "--user-data-dir=`"$UserDataDir`""
    $Shortcut.WorkingDirectory = Split-Path $ChromeExe
    $Shortcut.Save()
    
    Write-Info "快捷方式已创建: $ShortcutFile"
}

function Main {
    # 确定默认路径
    if ([string]::IsNullOrWhiteSpace($InstallBaseDir)) {
        if (Test-Path "D:\") {
            $InstallBaseDir = "D:\ChromeVersions"
        }
        else {
            $InstallBaseDir = Join-Path $env:USERPROFILE "Apps\ChromeVersions"
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
    
    # 构建路径
    $appDir = Join-Path $InstallBaseDir "Chrome${Version}\Application"
    $ChromeExe = Join-Path $appDir "chrome.exe"
    $UserDataDir = Join-Path $DataBaseDir "Chrome${Version}"
    
    if (-not (Test-Path $ChromeExe)) {
        Write-Error-Custom "Chrome 版本 $Version 未找到: $ChromeExe"
        Write-Info "请先运行安装脚本: .\install-chrome-7zip.ps1 -Version <版本号> -InstallerPath <安装包路径>"
        exit 1
    }
    
    # 创建数据目录（如果不存在）
    if (-not (Test-Path $UserDataDir)) {
        New-Item -ItemType Directory -Path $UserDataDir -Force | Out-Null
        Write-Info "创建用户数据目录: $UserDataDir"
    }
    
    # 构建启动参数
    $Arguments = @("--user-data-dir=$UserDataDir")
    
    if ($Incognito) {
        $Arguments += "--incognito"
    }
    
    if ($Headless) {
        $Arguments += "--headless"
    }
    
    if ($DevTools) {
        $Arguments += "--auto-open-devtools-for-tabs"
    }
    
    if ($RemoteDebuggingPort) {
        $Arguments += "--remote-debugging-port=$RemoteDebuggingPort"
    }
    
    if ($Url) {
        $Arguments += $Url
    }
    
    # 获取版本信息
    $VersionInfo = Get-ChromeVersion -ChromeExe $ChromeExe
    Write-Info "启动 Chrome 版本 $Version ($VersionInfo)"
    Write-Info "用户数据: $UserDataDir"
    
    # 创建快捷方式（如果需要）
    if ($CreateShortcut) {
        Create-DesktopShortcut -ChromeExe $ChromeExe -UserDataDir $UserDataDir -VersionName $Version
    }
    
    # 启动 Chrome
    try {
        Start-Process -FilePath $ChromeExe -ArgumentList $Arguments
        Write-Info "Chrome 版本 $Version 已启动"
    }
    catch {
        Write-Error-Custom "启动失败: $_"
        exit 1
    }
}

Main
