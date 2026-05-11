# 列出可用的 Chrome 版本
# 使用方法: .\list-versions.ps1 -InstallBaseDir "D:\ChromeVersions" -DataBaseDir "D:\ChromeData"

param(
    [string]$InstallBaseDir = "",
    
    [string]$DataBaseDir = ""
)

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Get-ChromeVersion {
    param([string]$ChromeExe)
    
    try {
        $Version = & $ChromeExe --version
        return $Version.Trim()
    }
    catch {
        return "无法获取"
    }
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
    
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "Chrome 版本信息" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "安装目录: $InstallBaseDir" -ForegroundColor Gray
    Write-Host "数据目录: $DataBaseDir" -ForegroundColor Gray
    Write-Host ""
    
    # 检查安装目录是否存在
    if (-not (Test-Path $InstallBaseDir)) {
        Write-Host "安装目录不存在: $InstallBaseDir" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "请先安装 Chrome 版本:" -ForegroundColor Cyan
        Write-Host ".\install-chrome-7zip.ps1 -Version <版本号> -InstallerPath <安装包路径>" -ForegroundColor White
        exit 0
    }
    
    # 获取所有已安装的版本
    $chromeDirs = Get-ChildItem $InstallBaseDir -Directory | Where-Object { $_.Name -match "^Chrome\d+" }
    
    if ($chromeDirs.Count -eq 0) {
        Write-Host "未找到已安装的 Chrome 版本" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "请先安装 Chrome 版本:" -ForegroundColor Cyan
        Write-Host ".\install-chrome-7zip.ps1 -Version <版本号> -InstallerPath <安装包路径>" -ForegroundColor White
        exit 0
    }
    
    foreach ($dir in $chromeDirs) {
        $versionNumber = $dir.Name -replace "Chrome", ""
        $appDir = Join-Path $dir.FullName "Application"
        $chromeExe = Join-Path $appDir "chrome.exe"
        $dataDir = Join-Path $DataBaseDir "Chrome${versionNumber}"
        
        Write-Host "版本: $versionNumber" -ForegroundColor Yellow
        
        # 检查安装状态
        if (Test-Path $chromeExe) {
            Write-Host "  ✓ 已安装" -ForegroundColor Green
            Write-Host "  路径: $appDir" -ForegroundColor Gray
            
            # 获取版本号
            $versionInfo = Get-ChromeVersion -ChromeExe $chromeExe
            Write-Host "  版本: $versionInfo" -ForegroundColor Cyan
        }
        else {
            Write-Host "  ✗ 未安装或安装不完整" -ForegroundColor Red
            Write-Host "  预期路径: $appDir" -ForegroundColor Gray
        }
        
        # 检查数据目录
        if (Test-Path $dataDir) {
            Write-Host "  ✓ 数据目录: $dataDir" -ForegroundColor Green
        }
        else {
            Write-Host "  - 数据目录: 不存在" -ForegroundColor Gray
        }
        
        Write-Host ""
    }
    
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "使用示例:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "# 启动特定版本" -ForegroundColor Gray
    Write-Host ".\launch-chrome.ps1 -Version <版本号>" -ForegroundColor White
    Write-Host ""
    Write-Host "# 安装新版本" -ForegroundColor Gray
    Write-Host ".\install-chrome-7zip.ps1 -Version <版本号> -InstallerPath <安装包路径>" -ForegroundColor White
    Write-Host "=========================================" -ForegroundColor Cyan
}

Main
