# VV Viewer

VV Viewer 是一个 Android 应用，用于打开 .vv (virt-viewer) 文件并连接到 PVE (Proxmox VE) 的 SPICE 控制台。

## 功能

- 打开和解析 .vv (virt-viewer) 文件
- 嵌入式 SPICE 连接（内置 bVNC，无需外部依赖）
- 连接历史记录管理
- 文件关联支持（直接从文件管理器打开）
- PVE Web Console (noVNC) 支持
- 生成 SPICE/VNC 连接 URI
- 一键复制连接信息

## 环境要求

- Flutter 3.x
- Android SDK 35+
- Java 17

## 构建

```bash
cd /Users/steve/ClaudeProjects/vv_viewer

# 安装依赖
flutter pub get

# Android APK (Debug)
export JAVA_HOME="/Users/steve/Library/Java/JavaVirtualMachines/jbr-17.0.14/Contents/Home"
flutter build apk --debug

# Android APK (Release)
flutter build apk --release
```

## 安装 APK

```bash
adb install -r android/app/build/outputs/apk/debug/app-debug.apk
```

## 使用

### 方式一：文件管理器打开

1. 直接在文件管理器中点击 .vv 文件
2. 选择 "用 VV Viewer 打开"
3. 应用自动解析并显示连接信息

### 方式二：应用内选择文件

1. 打开 VV Viewer
2. 点击 "打开 .vv 文件" 按钮
3. 选择 .vv 文件
4. 查看连接详情或直接连接

### 方式三：PVE 应用链接

1. 从 PVE 应用点击 SPICE 连接
2. 选择 "用 VV Viewer 打开"
3. 应用自动启动嵌入式 SPICE

## .vv 文件格式

```ini
[virt-viewer]
type=spice
host=192.168.1.100
port=3001
tls-port=3002
password=MySecretPassword
title=My Virtual Machine
fullscreen=0
enable-usbredir=1
```

## 项目结构

```
lib/
├── main.dart                          # 应用入口，URI 处理
├── models/                            # 数据模型
│   ├── connection_type.dart           # 连接类型枚举 (SPICE/VNC)
│   ├── spice_launch_result.dart       # SPICE 启动结果
│   └── vv_connection.dart             # 连接数据模型
├── parsers/                           # 解析器
│   └── vv_parser.dart                 # .vv 文件解析器
├── providers.dart                     # Riverpod providers
├── screens/                           # 页面
│   ├── home_screen.dart               # 首页
│   ├── connection_list_screen.dart    # 连接历史列表
│   ├── viewer_screen.dart             # 连接详情查看器
│   ├── embedded_spice_screen.dart     # 嵌入式 SPICE 连接
│   └── pve_console_screen.dart        # PVE Web Console
├── services/                          # 服务
│   ├── app_logger.dart                # 日志模块
│   ├── file_opened_observer.dart      # 文件打开监听
│   ├── spice_launcher_service.dart    # SPICE 启动服务
│   └── storage_service.dart           # 存储服务
└── utils/                             # 工具类
    └── constants.dart                 # 常量定义
```

## 测试

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/parsers/vv_parser_test.dart
```

## 架构

### 关键模块

- **app** - Flutter 应用 (com.vvviewer.vv_viewer)
- **bVNC** - UI 组件 (com.undatech.remoteClientUi)
- **remoteClientLib** - SPICE 协议 (com.undatech.remoteClientLib)
- **common** - 共享工具 (com.morpheusly.common)
- **pubkeyGenerator** - SSH 密钥生成 (com.iiordanov.pubkeygenerator)

### 模块依赖图

```
app
├── bVNC
│   ├── pubkeyGenerator
│   ├── remoteClientLib
│   └── common
├── remoteClientLib
├── common
└── pubkeyGenerator
    └── common
```

### 连接状态管理

两个独立的追踪器防止外部和应用内发起的连接交叉污染：
- `externalCallUri` - 追踪外部 PVE 应用调用
- `flutterCallPath` - 追踪 Flutter 调用

### 日志

使用 `AppLogger` 类进行标签式日志输出：
```dart
AppLogger.debug(LogTags.spiceLauncher, 'message');
AppLogger.info(LogTags.main, 'message');
AppLogger.error(LogTags.main, 'error', e, st);
```

## 常见问题

### 构建失败："Could not find com.undatech.sqlcipher"

修复：发布 sqlcipher AAR 到本地 maven：
```bash
mkdir -p ~/.m2/repository/com/undatech/sqlcipher/android-database-sqlcipher/4.5.4
cp android/common/aars/android-database-sqlcipher-4.5.4.aar ~/.m2/repository/com/undatech/sqlcipher/android-database-sqlcipher/4.5.4/
```

### 构建失败："Invalid source release: 21"

修复：使用 Java 17（不支持 source/target 21）

## 文档

- `docs/ARCHITECTURE.md` - 系统架构
- `docs/EMBEDDED_SPICE.md` - 嵌入式 SPICE 实现
- `docs/INTEGRATION.md` - 集成指南
- `docs/SETUP.md` - 环境配置
- `docs/TEST_PLAN.md` - 测试计划
- `docs/VV_FILE_FORMAT.md` - .vv 文件格式说明

## 许可

GPL-3.0