# Chrome 多版本安装 - 目录架构说明

## 📁 推荐的集中式架构

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
│   │       ├── chrome.dll
│   │       └── ...
│   ├── 120.0.6099.130\
│   │   └── Chrome-bin\
│   └── ...
├── user_data\                  # 各个版本的独立用户数据
│   ├── 127.0.6533.120\
│   │   ├── Default\
│   │   ├── Local State
│   │   └── ...
│   ├── 120.0.6099.130\
│   └── ...
└── shortcuts\                  # (可选) 存放生成的快捷方式
    ├── Chrome_127.0.6533.120.lnk
    ├── Chrome_120.0.6099.130.lnk
    └── ...
```

## ✨ 架构优势

### 1. 集中管理
- 所有 Chrome 相关文件都在一个根目录下
- 便于备份、迁移和清理
- 一目了然的目录结构

### 2. 清晰的职责分离
- **downloads/**: 原始安装包存档
- **versions/**: 可执行文件和运行时文件
- **user_data/**: 用户配置、缓存、扩展等
- **shortcuts/**: 快速启动入口

### 3. 版本化管理
- 使用完整版本号（如 `127.0.6533.120`）作为目录名
- 避免版本混淆
- 便于查找特定版本

### 4. 易于维护
- 删除某个版本：直接删除对应目录
- 备份用户数据：只需备份 `user_data/` 目录
- 清理空间：可以安全删除不需要的版本

## 🔧 使用脚本

### 安装新版本

```powershell
# 使用新的集中式架构脚本
.\scripts\install-chrome-structured.ps1 `
  -Version "127.0.6533.120" `
  -InstallerPath "C:\Downloads\chrome_127.exe" `
  -BaseDir "D:\Chrome_Testing"
```

脚本会自动：
1. 创建完整的目录结构
2. 解压并安装到 `versions/127.0.6533.120/Chrome-bin/`
3. 创建用户数据目录 `user_data/127.0.6533.120/`
4. 生成快捷方式到 `shortcuts/Chrome_127.0.6533.120.lnk`

### 启动特定版本

```powershell
# 方法 1: 使用快捷方式
# 双击 D:\Chrome_Testing\shortcuts\Chrome_127.0.6533.120.lnk

# 方法 2: 命令行启动
& "D:\Chrome_Testing\versions\127.0.6533.120\Chrome-bin\chrome.exe" `
  --user-data-dir="D:\Chrome_Testing\user_data\127.0.6533.120"

# 方法 3: 使用启动脚本（需要更新以支持新架构）
.\scripts\launch-chrome.ps1 -Version "127.0.6533.120" -BaseDir "D:\Chrome_Testing"
```

### 查看已安装的版本

```powershell
# 列出所有已安装的版本
Get-ChildItem "D:\Chrome_Testing\versions" -Directory | Select-Object Name

# 查看详细信息
Get-ChildItem "D:\Chrome_Testing\versions" -Directory | ForEach-Object {
    $version = $_.Name
    $exe = Join-Path $_.FullName "Chrome-bin\chrome.exe"
    if (Test-Path $exe) {
        $ver = & $exe --version
        [PSCustomObject]@{
            Version = $version
            Executable = $exe
            Info = $ver
        }
    }
} | Format-Table -AutoSize
```

## 📊 对比：旧架构 vs 新架构

### 旧架构（分散式）
```
D:\ChromeVersions\
├── Chrome127\Application\
└── Chrome120\Application\

D:\ChromeData\
├── Chrome127\
└── Chrome120\

C:\Users\User\Desktop\
├── Chrome 127.lnk
└── Chrome 120.lnk
```

**缺点**：
- ❌ 文件分散在多个位置
- ❌ 目录命名不统一（Chrome127 vs 127.0.6533.120）
- ❌ 快捷方式散落在桌面
- ❌ 难以整体备份和迁移

### 新架构（集中式）✅
```
D:\Chrome_Testing\
├── downloads\
├── versions\
├── user_data\
└── shortcuts\
```

**优点**：
- ✅ 所有文件集中管理
- ✅ 使用完整版本号，清晰明确
- ✅ 快捷方式统一管理
- ✅ 一键备份整个目录即可

## 🎯 最佳实践

### 1. 定期清理 downloads 目录
```powershell
# 保留最近 3 个月的安装包，删除旧的
$cutoffDate = (Get-Date).AddMonths(-3)
Get-ChildItem "D:\Chrome_Testing\downloads\*.exe" | Where-Object {
    $_.LastWriteTime -lt $cutoffDate
} | Remove-Item -Force
```

### 2. 备份用户数据
```powershell
# 压缩备份所有用户数据
Compress-Archive -Path "D:\Chrome_Testing\user_data\*" `
  -DestinationPath "D:\Backup\Chrome_UserData_$(Get-Date -Format 'yyyyMMdd').zip"
```

### 3. 清理不需要的版本
```powershell
# 删除特定版本（包括版本文件和用户数据）
$versionToRemove = "120.0.6099.130"
Remove-Item "D:\Chrome_Testing\versions\$versionToRemove" -Recurse -Force
Remove-Item "D:\Chrome_Testing\user_data\$versionToRemove" -Recurse -Force
Remove-Item "D:\Chrome_Testing\shortcuts\Chrome_${versionToRemove}.lnk" -Force
```

### 4. 检查磁盘使用情况
```powershell
# 查看每个版本占用的空间
Get-ChildItem "D:\Chrome_Testing\versions" -Directory | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{
        Version = $_.Name
        SizeMB = [math]::Round($size / 1MB, 2)
    }
} | Sort-Object SizeMB -Descending | Format-Table -AutoSize
```

## 🚀 快速开始

### 首次设置

```powershell
# 1. 创建根目录
New-Item -ItemType Directory -Path "D:\Chrome_Testing" -Force

# 2. 下载 Chrome 安装包到 downloads/
# 访问: https://google-chrome.en.uptodown.com/windows/versions

# 3. 安装第一个版本
.\scripts\install-chrome-structured.ps1 `
  -Version "127.0.6533.120" `
  -InstallerPath "D:\Chrome_Testing\downloads\127.0.6533.120.exe" `
  -BaseDir "D:\Chrome_Testing"

# 4. 完成！快捷方式已创建在 shortcuts/ 目录
```

### 添加更多版本

重复步骤 2-3，使用不同的版本号即可。所有版本都会自动组织在统一的目录结构中。

## 📝 注意事项

1. **路径长度**: Windows 有最大路径长度限制（260 字符），建议使用较短的根目录路径
2. **权限**: 确保对 `D:\Chrome_Testing` 有读写权限
3. **磁盘空间**: 每个版本约占用 300-500 MB，加上用户数据可能更多
4. **版本兼容性**: 某些旧版本可能不兼容最新的操作系统

## 🔗 相关资源

- SKILL.md: 详细的安装和使用指南
- reference.md: Chrome 版本信息和命令行参数
- scripts/: 自动化安装和管理脚本
