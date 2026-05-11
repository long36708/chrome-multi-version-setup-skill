# Chrome 版本详细信息与参考

## Chrome 发布渠道详解

### Stable (稳定版)
- **更新周期**: 每 4 周 major 版本更新
- **适用场景**: 生产环境、最终用户测试
- **版本号示例**: 120.0.6099.130
- **下载大小**: ~90 MB

### Beta (测试版)
- **更新周期**: 每周更新
- **提前量**: 比稳定版提前 1-2 周
- **适用场景**: 新功能测试、兼容性预检
- **版本号示例**: 121.0.6167.50
- **下载大小**: ~90 MB

### Dev (开发版)
- **更新周期**: 每周更新
- **提前量**: 比稳定版提前 6-8 周
- **适用场景**: 早期功能测试、API 兼容性测试
- **版本号示例**: 122.0.6190.0
- **下载大小**: ~90 MB
- **注意**: 可能存在较多 bug

### Canary (金丝雀版)
- **更新周期**: 每日更新
- **提前量**: 比稳定版提前 8-12 周
- **适用场景**: 最前沿的功能测试
- **版本号示例**: 123.0.6250.0
- **下载大小**: ~90 MB
- **注意**: 
  - 自动更新，无法禁用
  - 可能与现有系统冲突
  - 仅用于测试

## 官方下载源

### Windows 安装包格式

1. **完整离线安装包** (推荐用于多版本管理)
   ```
   https://dl.google.com/tag/s/appguid%3D{8A69D345-D564-463C-AFF1-A69D9E530F96}%26iid%3D{random}%26lang%3Dzh-CN%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers/ap/installer/ChromeSetup.exe
   ```

2. **Chrome Enterprise 离线安装包**
   ```
   https://support.google.com/chrome/a/answer/9915669
   ```

3. **Chromium 快照** (用于获取特定版本)
   ```
   https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html
   ```

## 版本信息获取

### 通过注册表查询

```powershell
# 查询已安装的 Chrome 版本
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe"
Get-ItemProperty "HKCU:\Software\Google\Chrome\BLBeacon"
```

### 通过命令行查询

```powershell
# 获取版本信息
& "C:\ChromeVersions\Stable\chrome.exe" --version

# 获取详细版本信息（启动后访问）
chrome://version/
```

## 命令行参数参考

### 常用启动参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--user-data-dir` | 指定用户数据目录 | `--user-data-dir=C:\ChromeData\Test` |
| `--incognito` | 无痕模式 | `--incognito` |
| `--headless` | 无头模式 | `--headless` |
| `--remote-debugging-port` | 远程调试端口 | `--remote-debugging-port=9222` |
| `--disable-extensions` | 禁用扩展 | `--disable-extensions` |
| `--start-maximized` | 最大化启动 | `--start-maximized` |
| `--window-size` | 指定窗口大小 | `--window-size=1920,1080` |
| `--disable-gpu` | 禁用 GPU 加速 | `--disable-gpu` |

### 开发者相关参数

```powershell
# 启用 WebRTC 日志
--enable-logging --v=1

# 忽略证书错误
--ignore-certificate-errors

# 禁用安全策略（仅测试）
--disable-web-security --user-data-dir=C:\ChromeData\Unsafe

# 指定语言
--lang=en-US

# 禁用自动更新
--disable-background-networking
```

## 多版本管理的最佳实践

### 1. 目录命名规范

```
C:\ChromeVersions\
├── chrome-stable-120/      # 包含版本号
├── chrome-beta-121/
├── chrome-dev-122/
└── chrome-canary-123/

C:\ChromeData\
├── stable-default/
├── beta-testing/
├── dev-experimental/
└── canary-nightly/
```

### 2. 环境变量配置

```powershell
# 添加到 PowerShell profile ($PROFILE)
$env:CHROME_STABLE = "C:\ChromeVersions\Stable\chrome.exe"
$env:CHROME_BETA = "C:\ChromeVersions\Beta\chrome.exe"
$env:CHROME_DEV = "C:\ChromeVersions\Dev\chrome.exe"
$env:CHROME_CANARY = "C:\ChromeVersions\Canary\chrome.exe"
```

### 3. 注册表隔离

不同版本的 Chrome 会共享部分注册表项，建议：
- 使用独立的 Windows 用户账户进行彻底隔离
- 或使用组策略限制注册表写入

### 4. 扩展管理

每个版本需要单独安装扩展：
```powershell
# 预装扩展（通过策略）
# 位置: C:\ChromeVersions\[Version]\policies\
```

## 常见问题 FAQ

### Q: 如何完全禁用自动更新？

**A**: Chrome 稳定版、Beta、Dev 可以通过以下方式禁用：

```powershell
# 方法 1: 删除更新服务
sc delete gupdate
sc delete gupdatem

# 方法 2: 组策略（专业版）
# gpedit.msc -> 计算机配置 -> 管理模板 -> Google -> Google Update

# 方法 3: 重命名更新目录
Rename-Item "C:\Program Files (x86)\Google\Update" "Update.disabled"
```

**注意**: Canary 版本无法禁用自动更新。

### Q: 如何在 CI/CD 中使用多版本 Chrome？

**A**: 
```yaml
# GitHub Actions 示例
- name: Setup Chrome versions
  run: |
    choco install googlechrome --version=120.0.6099.130
    choco install googlechrome-beta
    
- name: Test on multiple versions
  run: |
    npm test -- --browser=chrome-stable
    npm test -- --browser=chrome-beta
```

### Q: 版本冲突如何解决？

**A**: 
1. 确保每个版本使用独立的用户数据目录
2. 不要同时运行相同用户数据的多个实例
3. 清理临时文件：`%LOCALAPPDATA%\Google\Chrome`

### Q: 如何获取历史版本？

**A**: 
- Chromium 快照: https://chromium.cypress.io/
- Chrome Enterprise: 联系企业管理员
- 第三方存档: https://www.slimjet.com/chrome/google-chrome-old-version.php

### Q: 性能优化建议？

**A**:
```powershell
# 禁用不必要的功能
--disable-background-timer-throttling
--disable-renderer-backgrounding
--disable-backgrounding-occluded-windows

# 限制内存使用
--js-flags="--max-old-space-size=2048"
```

## 安全注意事项

1. **Canary 和 Dev 版本安全性较低**
   - 仅在隔离环境中运行
   - 不要登录重要账号
   - 定期清理数据

2. **禁用安全选项仅用于测试**
   ```powershell
   # ⚠️ 危险：仅在内网测试使用
   --disable-web-security
   --allow-running-insecure-content
   ```

3. **定期更新稳定版和 Beta 版**
   - 至少每月更新一次
   - 关注安全公告

## 工具和资源

### 官方资源
- [Chrome 发布说明](https://chromereleases.googleblog.com/)
- [Chrome Enterprise 下载](https://support.google.com/chrome/a/answer/9915669)
- [Chromium 每日构建](https://download-chromium.appspot.com/)

### 第三方工具
- **ChromeDriver**: 用于自动化测试
- **Selenium Grid**: 多版本并行测试
- **BrowserStack**: 云端多浏览器测试

### 监控和诊断
```powershell
# 查看 Chrome 进程树
Get-Process chrome | Format-Table Id, ProcessName, Path, StartTime

# 监控内存使用
Get-Process chrome | Measure-Object WorkingSet -Sum

# 查看网络连接
Get-NetTCPConnection -OwningProcess (Get-Process chrome).Id
```

## 版本兼容性矩阵

| Web API | Stable | Beta | Dev | Canary |
|---------|--------|------|-----|--------|
| View Transitions | ✅ | ✅ | ✅ | ✅ |
| CSS Nesting | ✅ | ✅ | ✅ | ✅ |
| Web Components v1 | ✅ | ✅ | ✅ | ✅ |
| Origin Private File System | ✅ | ✅ | ✅ | ✅ |
| 实验性 API | ❌ | ⚠️ | ✅ | ✅ |

*注: ✅ 完全支持, ⚠️ 部分支持, ❌ 不支持*
