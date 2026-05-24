---
name: chrome-multi-version-setup
description: 在 Windows 电脑上使用 7-Zip 解压方式安装和管理多个版本的 Chrome 浏览器，支持自定义安装路径（默认非 C 盘），实现多版本并存用于兼容性测试。当用户需要在 Windows 上安装多个 Chrome 版本、进行浏览器兼容性测试、或管理不同版本的 Chrome 时使用。
---

# Chrome 多版本安装与管理（基于 7-Zip 方法）

通过 7-Zip 解压 Chrome 安装包的方式，在 Windows 上安装和运行多个独立的 Chrome 版本。

## 核心原理

此方法通过以下步骤实现多版本并存：

1. 下载 Chrome 旧版本安装包
2. 使用 7-Zip 解压安装包提取 chrome.exe
3. 安装到用户指定的独立目录（推荐非 C 盘）
4. 创建带独立用户数据目录的快捷方式
5. 各版本互不干扰，可同时运行

## 前置要求

- **7-Zip**: 必须安装，用于解压 Chrome 安装包
    - 下载地址: https://www.7-zip.org/
- **管理员权限**: 如果安装到 Program Files 需要，其他路径可选
- **足够的磁盘空间**: 每个版本约 300-500 MB

## 安装路径选择

### 推荐的目录架构

**⚠️ 重要**: 默认不要安装在 C 盘，除非用户明确要求。

#### 推荐架构：集中式管理

```
D:\Chrome_Testing\              # 根目录（统一管理）
├── downloads\                  # 存放下载的离线安装包
│   ├── 127.0.6533.120.exe
│   ├── 120.0.6099.130.exe
│   └── ...
├── versions\                   # 每个版本的独立运行目录
│   ├── 127.0.6533.120\
│   │   └── Chrome-bin\        # 从安装包解压的核心文件
│   │       ├── chrome.exe
│   │       └── ...
│   ├── 120.0.6099.130\
│   │   └── Chrome-bin\
│   └── ...
├── user_data\                  # 各个版本的独立用户数据
│   ├── 127.0.6533.120\
│   ├── 120.0.6099.130\
│   └── ...
└── shortcuts\                  # (可选) 存放生成的快捷方式
    ├── Chrome_127.0.6533.120.lnk
    └── Chrome_120.0.6099.130.lnk
```

**优势**：
- ✅ 所有相关文件集中管理，便于备份和迁移
- ✅ 清晰的目录分离（下载、版本、数据、快捷方式）
- ✅ 使用完整版本号，避免混淆
- ✅ 易于清理不需要的版本

### 路径选择建议

| 考虑因素      | 建议           |
|-----------|--------------|
| **系统盘空间** | 优先选择非 C 盘    |
| **读写速度**  | 选择 SSD 盘符    |
| **备份需求**  | 易于备份的位置      |
| **权限管理**  | 避免需要管理员权限的路径 |
| **团队协作**  | 统一的路径规范      |

## 快速开始

### 安装前准备

在安装之前，需要确认以下信息：

```
安装配置确认:
- [ ] 确认要安装的 Chrome 版本号
- [ ] 确认安装包下载路径
- [ ] 确认安装目标路径（避免 C 盘）
- [ ] 确认用户数据目录路径
- [ ] 确认是否有足够的磁盘空间
```

### 与用户确认安装配置

在开始安装前，**必须**向用户确认以下信息：

1. **Chrome 版本**: 需要安装哪个版本？（例如：127.0.6533.120）
2. **安装包位置**: 安装包在哪里？（如果尚未下载，提供下载链接）
3. **安装路径**: 希望安装到哪个目录？（**推荐非 C 盘**）
4. **数据目录**: 用户数据存放在哪里？（可以与安装路径同盘）

**示例对话**（使用推荐架构）:

> "我将帮您安装 Chrome 版本 127.0.6533.120。
>
> 请确认以下配置：
> - 根目录: D:\Chrome_Testing
> - 版本目录: D:\Chrome_Testing\versions\127.0.6533.120
> - 数据目录: D:\Chrome_Testing\user_data\127.0.6533.120
>
> 这些路径是否合适？或者您希望使用其他路径？"

### 安装步骤详解

以安装版本 127.0.6533.120 到 `D:\Chrome_Testing` 为例：

```
安装进度:
- [ ] 步骤 1: 下载 Chrome 安装包到 downloads/
- [ ] 步骤 2: 使用 7-Zip 解压安装包
- [ ] 步骤 3: 提取 chrome_installer
- [ ] 步骤 4: 解压 chrome.zip
- [ ] 步骤 5: 创建版本目录 versions/127.0.6533.120/
- [ ] 步骤 6: 复制 Chrome-bin 文件
- [ ] 步骤 7: 创建用户数据目录 user_data/127.0.6533.120/
- [ ] 步骤 8: 创建快捷方式到 shortcuts/
```

#### 步骤 1: 下载 Chrome 旧版本

访问以下网站下载所需的 Chrome 版本：
- https://vikyd.github.io/download-chromium-history-version/#/
- **Uptodown**: https://google-chrome.en.uptodown.com/windows/versions
- **GitHub**: https://github.com/Bush2021/chrome_installer
- https://www.slimjet.com/chrome/google-chrome-old-version.php
- https://google-chrome.en.uptodown.com/windows/versions
- 选择目标版本（例如：**127.0.6533.120**）
- 下载 `.exe` 文件到 `D:\Chrome_Testing\downloads\`

#### 步骤 2: 解压安装包

```powershell
# 右键点击下载的 .exe 文件
# 选择 "7-Zip" -> "提取到当前位置"
# 或使用命令行：
& "C:\Program Files\7-Zip\7z.exe" x "chrome_installer.exe" -o"./extracted"
```

解压后会看到 `updater.zip` 文件。

#### 步骤 3: 提取 Chrome Installer

```powershell
# 继续解压 updater.zip
& "C:\Program Files\7-Zip\7z.exe" x "updater.zip" -o"./updater"

# 导航到 bin\Offline 目录
cd extracted\bin\Offline

# 向上返回两级目录
cd ..\..

# 找到 chrome_installer 文件（例如：127.0.6533.120_chrome_installer）
```

#### 步骤 4: 解压 chrome.zip

```powershell
# 解压 chrome_installer
& "C:\Program Files\7-Zip\7z.exe" x "127.0.6533.120_chrome_installer" -o"./chrome_files"

# 在提取的文件中找到 chrome.zip
cd chrome_files

# 解压 chrome.zip
& "C:\Program Files\7-Zip\7z.exe" x "chrome.zip" -o"./chrome_bin"

# 现在会看到 Chrome-bin 文件夹
```

#### 步骤 5: 创建版本目录

**根据推荐架构创建目录**：

```powershell
# 示例：使用推荐的集中式架构
$BaseDir = "D:\Chrome_Testing"
$VersionDir = Join-Path $BaseDir "versions\127.0.6533.120"
New-Item -ItemType Directory -Path $VersionDir -Force

# 如果用户指定了其他根目录，相应调整
# 例如：E:\Software\Browsers\Chrome_Testing\versions\127.0.6533.120
```

目录结构：
```
D:\Chrome_Testing\
└── versions\
    └── 127.0.6533.120\
        └── Chrome-bin\    # 稍后复制到这里
```

#### 步骤 6: 复制 Chrome 文件

```powershell
# 复制 Chrome-bin 中的所有文件到版本目录
$TargetDir = "D:\Chrome_Testing\versions\127.0.6533.120\Chrome-bin"
Copy-Item ".\chrome_bin\Chrome-bin\*" -Destination $TargetDir -Recurse -Force
```

#### 步骤 7: 创建用户数据目录

```powershell
# 创建独立的用户数据目录
$UserDataDir = "D:\Chrome_Testing\user_data\127.0.6533.120"
New-Item -ItemType Directory -Path $UserDataDir -Force
```

#### 步骤 8: 创建快捷方式

```powershell
# 创建快捷方式到 shortcuts 目录
$ShortcutsDir = "D:\Chrome_Testing\shortcuts"
if (-not (Test-Path $ShortcutsDir)) {
    New-Item -ItemType Directory -Path $ShortcutsDir -Force
}

$WScriptShell = New-Object -ComObject WScript.Shell
$ShortcutFile = Join-Path $ShortcutsDir "Chrome_127.0.6533.120.lnk"
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = "D:\Chrome_Testing\versions\127.0.6533.120\Chrome-bin\chrome.exe"
$Shortcut.Arguments = '--user-data-dir="D:\Chrome_Testing\user_data\127.0.6533.120"'
$Shortcut.WorkingDirectory = "D:\Chrome_Testing\versions\127.0.6533.120\Chrome-bin"
$Shortcut.Save()
```

**重要**: `--user-data-dir` 参数确保每个版本使用独立的用户配置文件，避免冲突。

## 多版本管理

### 推荐的目录结构

**方案 A: 非系统盘（推荐）**

```
D:\ChromeVersions\            # 安装目录
├── Chrome\                   # 主版本（正常安装）
├── Chrome127\               # 版本 127
│   └── Application\
├── Chrome120\               # 版本 120
│   └── Application\
└── ChromeBeta\              # Beta 版本
    └── Application\

D:\ChromeData\                # 独立用户数据目录
├── Chrome127\
├── Chrome120\
└── ChromeBeta\
```

**方案 B: 用户目录**

```
C:\Users\[用户名]\Apps\ChromeVersions\
├── Chrome127\
│   └── Application\
└── Chrome120\
    └── Application\

C:\Users\[用户名]\Apps\ChromeData\
├── Chrome127\
└── Chrome120\
```

### 启动不同版本

为每个版本创建独立的快捷方式，目标分别为：

``powershell
# 版本 127 (D 盘)
"D:\ChromeVersions\Chrome127\Application\chrome.exe" --user-data-dir="D:\ChromeData\Chrome127"

# 版本 120 (D 盘)
"D:\ChromeVersions\Chrome120\Application\chrome.exe" --user-data-dir="D:\ChromeData\Chrome120"

# Beta 版本 (E 盘)
"E:\Software\Browsers\ChromeBeta\Application\chrome.exe" --user-data-dir="E:\Software\Browsers\ChromeBetaData"
```

### 同时运行多个版本

由于每个版本使用独立的用户数据目录，可以**同时运行**多个版本而不会冲突。

## 常用操作

### 查看 Chrome 版本

启动 Chrome 后访问：

```
chrome://version/
```

或在 PowerShell 中：

```powershell
& "D:\ChromeVersions\Chrome127\Application\chrome.exe" --version
```

### 清理用户数据

```powershell
# 删除某个版本的用户数据
Remove-Item "D:\ChromeData\Chrome127\*" -Recurse -Force
```

### 备份配置

```powershell
# 备份用户数据目录
Copy-Item "D:\ChromeData\Chrome127" "D:\ChromeData\Chrome127_Backup" -Recurse
```

### 迁移到其他路径

如果需要将已安装的 Chrome 版本移动到其他位置：

```
# 1. 停止所有 Chrome 进程
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue

# 2. 移动安装目录
Move-Item "D:\ChromeVersions\Chrome127" "E:\NewLocation\Chrome127"

# 3. 移动数据目录
Move-Item "D:\ChromeData\Chrome127" "E:\NewLocation\ChromeData127"

# 4. 更新快捷方式（重新创建）
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut("$env:USERPROFILE\Desktop\Chrome 127.lnk")
$Shortcut.TargetPath = "E:\NewLocation\Chrome127\Application\chrome.exe"
$Shortcut.Arguments = '--user-data-dir="E:\NewLocation\ChromeData127"'
$Shortcut.WorkingDirectory = "E:\NewLocation\Chrome127\Application"
$Shortcut.Save()
```

## 兼容性测试技巧

### 1. 使用不同的用户配置

为每个测试场景创建独立的数据目录：

```powershell
# 测试场景 A
"D:\Chrome_Testing\versions\127.0.6533.120\Chrome-bin\chrome.exe" --user-data-dir="D:\Chrome_Testing\user_data\TestA"

# 测试场景 B
"D:\Chrome_Testing\versions\127.0.6533.120\Chrome-bin\chrome.exe" --user-data-dir="D:\Chrome_Testing\user_data\TestB"
```

### 2. 启用开发者工具

```powershell
# 自动打开开发者工具
"D:\Chrome_Testing\versions\127.0.6533.120\Chrome-bin\chrome.exe" --user-data-dir="D:\Chrome_Testing\user_data\127.0.6533.120" --auto-open-devtools-for-tabs
```

### 3. 远程调试

```powershell
# 启用远程调试端口
"D:\Chrome_Testing\versions\127.0.6533.120\Chrome-bin\chrome.exe" --user-data-dir="D:\Chrome_Testing\user_data\127.0.6533.120" --remote-debugging-port=9222
```

然后可以在其他工具中连接到 `http://localhost:9222` 进行自动化测试。

### 4. 无头模式测试

```powershell
# 无头模式运行（适合自动化脚本）
"D:\Chrome_Testing\versions\127.0.6533.120\Chrome-bin\chrome.exe" --user-data-dir="D:\Chrome_Testing\user_data\127.0.6533.120" --headless --disable-gpu
```

## 故障排查

### 问题: 快捷方式无法启动

**症状**: 双击快捷方式没有反应

**解决方案**:

1. 检查路径是否正确
2. 确认 chrome.exe 存在
3. 尝试直接运行 chrome.exe

```powershell
# 验证文件存在
Test-Path "D:\Chrome_Testing\versions\127.0.6533.120\Chrome-bin\chrome.exe"
```

### 问题: 版本冲突

**症状**: 启动时提示配置文件损坏

**解决方案**:

```powershell
# 清理用户数据目录
Remove-Item "D:\Chrome_Testing\user_data\127.0.6533.120\*" -Recurse -Force

# 重新启动
```

### 问题: 缺少 DLL 文件

**症状**: 启动时提示缺少依赖

**解决方案**:

- 确保完整复制了 Chrome-bin 的所有文件
- 安装最新的 Visual C++ Redistributable

### 问题: 无法下载旧版本

**替代下载源**:

- https://www.slimjet.com/chrome/google-chrome-old-version.php
- https://chromium.cypress.io/ (Chromium 快照)

### 问题: 磁盘空间不足

**解决方案**:

```powershell
# 检查磁盘空间
Get-PSDrive D | Select-Object Used,Free

# 清理不需要的版本
Remove-Item "D:\Chrome_Testing\versions\120.0.6099.130\" -Recurse -Force
Remove-Item "D:\Chrome_Testing\user_data\120.0.6099.130\" -Recurse -Force
```

## 高级用法

### 批量安装脚本

```
# 批量安装多个版本的示例脚本（使用集中式架构）
$BaseDir = "D:\Chrome_Testing"

$versions = @(
    @{ Version = "127.0.6533.120"; Installer = "D:\Chrome_Testing\downloads\chrome_127.exe" },
    @{ Version = "120.0.6099.130"; Installer = "D:\Chrome_Testing\downloads\chrome_120.exe" }
)

foreach ($item in $versions) {
    $version = $item.Version
    $installerPath = $item.Installer
    
    Write-Host "Installing Chrome $version..."
    
    # 使用自动化脚本安装
    & ".\scripts\install-chrome-structured.ps1" -Version $version -InstallerPath $installerPath -BaseDir $BaseDir
    
    Write-Host "Chrome $version installed"
}
```

### 使用 Selenium 测试

```
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

# 配置特定版本的 Chrome（使用集中式架构）
options = Options()
options.binary_location = r"D:\Chrome_Testing\versions\127.0.6533.120\Chrome-bin\chrome.exe"
options.add_argument('--user-data-dir=D:\\Chrome_Testing\\user_data\\127.0.6533.120')

driver = webdriver.Chrome(options=options)
driver.get("https://example.com")
```

### 使用 Puppeteer

```
const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({
        executablePath: 'D:\\Chrome_Testing\\versions\\127.0.6533.120\\Chrome-bin\\chrome.exe',
        userDataDir: 'D:\\Chrome_Testing\\user_data\\127.0.6533.120',
        headless: false
    });

    const page = await browser.newPage();
    await page.goto('https://example.com');

    await browser.close();
})();
```

### 路径配置模板

创建一个配置文件来管理所有路径：

```
# config.ps1
$ChromeConfig = @{
    BaseDir = "D:\Chrome_Testing"
    VersionsDir = "D:\Chrome_Testing\versions"
    UserDataDir = "D:\Chrome_Testing\user_data"
    ShortcutsDir = "D:\Chrome_Testing\shortcuts"
    Versions = @(
        @{ Number = "127.0.6533.120"; Path = "D:\Chrome_Testing\versions\127.0.6533.120\Chrome-bin" },
        @{ Number = "120.0.6099.130"; Path = "D:\Chrome_Testing\versions\120.0.6099.130\Chrome-bin" }
    )
}

# 在其他脚本中引用
. .\config.ps1
```

## 注意事项

1. **始终确认安装路径**: 在安装前与用户确认路径，**默认避免 C 盘**
2. **每个版本必须使用独立的用户数据目录**: 这是避免冲突的关键
3. **定期备份重要配置**: 测试过程中可能会破坏配置文件
4. **注意安全性**: 旧版本可能存在安全漏洞，仅用于测试
5. **不要登录重要账号**: 测试版本建议使用独立的测试账号
6. **Canary 版本会自动更新**: 如果需要固定版本，使用稳定版的旧版本
7. **路径命名规范**: 使用清晰的版本号和用途标识
8. **磁盘空间管理**: 定期检查并清理不需要的版本

## 相关资源

- 详细的版本信息和命令行参数，参见 [reference.md](reference.md)
- 项目 README: 参见项目根目录的 README.md

## 优势对比

| 特性    | 7-Zip 方法 | 官方安装器  |
|-------|----------|--------|
| 多版本并存 | ✅ 完全隔离   | ❌ 会覆盖  |
| 无需安装  | ✅ 解压即用   | ❌ 需要安装 |
| 版本控制  | ✅ 精确控制   | ❌ 自动更新 |
| 系统污染  | ✅ 最小化    | ❌ 注册表等 |
| 自定义路径 | ✅ 灵活配置   | ❌ 固定路径 |
| 复杂度   | ⚠️ 中等    | ✅ 简单   |

**7-Zip 方法的优势**: 完全隔离、可精确控制版本、不会自动更新、适合同时测试多个版本、**支持灵活的 path 配置**。
