# VV Viewer + aSPICE 整合项目开发指南

## 项目概述

这是一个免费开源的整合方案：**Flutter UI + aSPICE 原生连接能力**。

### 架构设计

```
┌─────────────────────────────────────────────────────┐
│              Flutter UI 层                          │
│  - .vv 文件解析                                       │
│  - 连接历史管理                                       │
│  - 用户界面                                          │
└────────────────────┬────────────────────────────────┘
                     │ Platform Channel
                     │ (Method Channel)
┌────────────────────▼────────────────────────────────┐
│           Android 原生层 (Kotlin)                    │
│  - 检查 aSPICE 安装状态                              │
│  - 构建 spice:// URI                                 │
│  - 通过 Intent 调用 aSPICE                           │
│  - FileProvider 共享文件                              │
└────────────────────┬────────────────────────────────┘
                     │ Intent
                     │
┌────────────────────▼────────────────────────────────┐
│              aSPICE (独立应用)                       │
│  - SPICE 协议实现                                    │
│  - 远程桌面渲染                                      │
│  - 来自 remote-desktop-clients 项目                  │
└─────────────────────────────────────────────────────┘
```

## 已实现的功能

### 1. Flutter 端

#### Platform Channel 服务
**文件**: `lib/services/spice_launcher_service.dart`

功能：
- `isAspiceInstalled()` - 检查 aSPICE 是否已安装
- `openAspiceStore()` - 打开应用商店下载页面
- `launchSpice()` - 使用连接信息启动 SPICE
- `launchSpiceWithFile()` - 使用 .vv 文件启动 SPICE

#### 增强的查看器页面
**文件**: `lib/screens/viewer_screen.dart`

新增功能：
- aSPICE 安装状态检测
- 一键启动 SPICE 连接
- 安装引导对话框
- 连接状态反馈

### 2. Android 原生层

#### MainActivity
**文件**: `android/app/src/main/kotlin/com/vvviewer/vv_viewer/MainActivity.kt`

功能：
- Method Channel 处理器
- aSPICE 包管理（支持付费版和免费版）
- spice:// URI 构建
- FileProvider 文件共享
- Intent 跳转

#### FileProvider 配置
**文件**: `android/app/src/main/res/xml/file_paths.xml`

支持的路径：
- `external-path` - 外部存储
- `external-cache-path` - 外部缓存
- `cache-path` - 应用缓存
- `files-path` - 应用文件

#### AndroidManifest 更新
新增：
- FileProvider 声明
- 更多权限（VIBRATE, MODIFY_AUDIO_SETTINGS, RECORD_AUDIO）
- 增强的 .vv 文件 intent filter

## 工作流程

### 场景 1: 点击 .vv 文件打开

```
用户点击 .vv 文件
    ↓
Android 系统分发 Intent
    ↓
MainActivity.onNewIntent()
    ↓
Flutter 接收文件路径
    ↓
解析 .vv 文件 (VVParser)
    ↓
显示连接详情 (ViewerScreen)
    ↓
用户点击"立即连接"
    ↓
检查 aSPICE 安装状态
    ↓
构建 spice:// URI
    ↓
通过 Intent 启动 aSPICE
    ↓
aSPICE 显示远程桌面
```

### 场景 2: 从历史记录连接

```
用户打开应用
    ↓
显示连接历史
    ↓
用户选择历史连接
    ↓
显示连接详情
    ↓
（同场景 1 后续步骤）
```

## API 参考

### Platform Channel 方法

#### `isAspiceInstalled`
检查 aSPICE 是否已安装。

**返回**: `bool`

```dart
final installed = await SpiceLauncherService.isAspiceInstalled();
```

#### `openAspiceStore`
打开应用商店的 aSPICE 下载页面。

**返回**: `bool` - 是否成功打开

```dart
await SpiceLauncherService.openAspiceStore();
```

#### `launchSpice`
使用连接信息启动 SPICE。

**参数**:
- `host` (String): 主机地址
- `port` (int?): 端口
- `tlsPort` (int?): TLS 端口
- `password` (String?): 密码
- `title` (String?): 连接标题

**返回**: `SpiceLaunchResult`

```dart
final result = await SpiceLauncherService.launchSpice(
  connection: vvConnection,
);
```

#### `launchSpiceWithFile`
使用 .vv 文件启动 SPICE。

**参数**:
- `filePath` (String): .vv 文件路径

**返回**: `SpiceLaunchResult`

```dart
final result = await SpiceLauncherService.launchSpiceWithFile(
  '/path/to/file.vv',
);
```

### SpiceLaunchResult

```dart
class SpiceLaunchResult {
  final bool success;        // 是否成功
  final String? error;       // 错误代码
  final String? message;     // 错误消息
  final String? package;     // 使用的 aSPICE 包名

  bool get needsInstall;     // 是否需要安装 aSPICE
}
```

**错误代码**:
- `ASPICE_NOT_INSTALLED` - aSPICE 未安装
- `INVALID_FILE` - 文件路径无效
- `FILE_NOT_FOUND` - 文件不存在
- `LAUNCH_ERROR` - 启动错误
- `PLATFORM_ERROR` - Platform Channel 错误

## Android 包名

支持的 aSPICE 包：

| 包名 | 说明 |
|------|------|
| `com.iiordanov.aSPICE` | aSPICE Pro (付费版) |
| `com.iiordanov.freeaSPICE` | aSPICE (免费版) |

优先使用付费版，如果未安装则使用免费版。

## URI 格式

### spice:// URI 结构

```
spice://<host>:<port>[?<param1>=<value1>&<param2>=<value2>]
```

**支持的参数**:
- `tls-port` - TLS 端口
- `port` - 普通端口（当使用 tls-port 时）
- `password` - 密码（URL 编码）
- `title` - 连接标题（URL 编码）

**示例**:
```
spice://192.168.1.100:3002?tls-port=3002&password=secret&title=MyVM
```

## 编译与运行

### 环境要求

- Flutter 3.11+
- Android Studio Hedgehog+
- JDK 17
- Android SDK API 21+

### 编译步骤

```bash
# 进入项目目录
cd /Users/steve/ClaudeProjects/vv_viewer

# 获取依赖
flutter pub get

# 运行到 Android 设备
flutter run

# 编译 APK
flutter build apk --release
```

### 测试步骤

1. 安装 aSPICE Free（从 Play Store）
2. 运行 VV Viewer
3. 打开示例 .vv 文件或手动输入连接信息
4. 点击"立即连接"
5. 验证是否跳转到 aSPICE 并成功连接

## 扩展开发

### 添加更多连接参数

需要修改三个地方：

1. **Flutter 模型** (`lib/models/vv_connection.dart`)
   - 添加新字段

2. **Platform Channel 接口** (`lib/services/spice_launcher_service.dart`)
   - 在 `launchSpice` 方法中添加新参数

3. **Android 原生** (`android/app/src/main/kotlin/.../MainActivity.kt`)
   - 在 `launchSpice` 方法中接收并处理新参数
   - 在 URI 构建代码中添加新参数

### 支持直接嵌入 aSPICE View

如果需要更深度的集成（在 Flutter 中直接显示 SPICE 画面，而不是跳转到独立应用），需要：

1. 将 aSPICE 作为 library module 导入
2. 使用 `PlatformView` 嵌入 SPICE 视图
3. 处理生命周期和通信

参考：
- `remote-desktop-clients/bVNC/` - 核心库
- `remote-desktop-clients/remoteClientLib/` - 公共库

### 支持 iOS

iOS 版本需要：

1. 使用 iOS 版 aSPICE Pro（App Store 有售）
2. 通过 URL Scheme 调用
3. 或使用 `WKWebView` + spice-html5（需要 WebSocket 代理）

## 注意事项

### aSPICE 必须独立安装

当前方案需要用户先安装 aSPICE。这是因为：
- aSPICE 是 GPL 许可，需要保持独立
- 避免复杂的 NDK 编译
- 简化维护工作

### 文件权限

Android 10+ 需要使用 FileProvider 共享文件，不能直接使用 `file://` URI。

### URI 编码

密码和标题等参数需要 URL 编码，避免特殊字符导致问题。

## 相关文件索引

### Flutter
- `lib/services/spice_launcher_service.dart` - Platform Channel 服务
- `lib/screens/viewer_screen.dart` - 查看器页面
- `lib/models/vv_connection.dart` - 连接模型

### Android
- `android/app/src/main/kotlin/.../MainActivity.kt` - 主 Activity
- `android/app/src/main/AndroidManifest.xml` - 清单文件
- `android/app/src/main/res/xml/file_paths.xml` - FileProvider 配置
- `android/app/build.gradle.kts` - Gradle 配置

### 文档
- `ARCHITECTURE.md` - 项目架构
- `VV_FILE_FORMAT.md` - .vv 文件格式
- `MODIFICATION_GUIDE.md` - 魔改指南
- `SETUP.md` - 环境搭建

## 许可证说明

- **VV Viewer**: MIT 许可证（本项目）
- **aSPICE**: GPL v2 许可证（需保持独立）
- **virt-viewer**: GPL v2 许可证

整合方案通过 Intent 调用独立 aSPICE 应用，符合 GPL 许可要求。
