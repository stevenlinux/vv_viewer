# VV Viewer 项目架构文档

## 项目概述

本项目是对 aSPICE Pro 的魔改版本，主要目标是：
- 支持打开和解析 .vv (virt-viewer) 文件
- 实现远程桌面控制功能
- 跨平台支持（Android、iOS、桌面端）

## 项目结构

```
ClaudeProjects/
├── vv_viewer/                    # Flutter 项目 - .vv 文件查看器
│   ├── lib/
│   │   ├── main.dart            # 应用入口
│   │   ├── models/              # 数据模型
│   │   ├── parsers/             # .vv 文件解析器
│   │   ├── screens/             # UI 页面
│   │   └── services/            # 服务层
│   └── docs/                    # 技术文档（本目录）
│
└── remote-desktop-clients/       # aSPICE Pro 源码
    ├── aSPICE-app/              # aSPICE 应用模块
    ├── bVNC/                    # 核心库（包含 SPICE/VNC 实现）
    ├── remoteClientLib/         # 远程客户端公共库
    │   └── src/main/cpp/virt-viewer/  # virt-viewer C 实现
    └── freeaSPICE-app/          # 免费版 aSPICE
```

## 核心组件说明

### 1. vv_viewer (Flutter)

**职责**：
- 解析和显示 .vv 配置文件
- 管理连接历史
- 提供文件关联支持
- 生成连接 URI

**关键文件**：
- `lib/parsers/vv_parser.dart` - .vv 文件解析器
- `lib/models/vv_connection.dart` - 连接数据模型
- `lib/screens/viewer_screen.dart` - 连接详情页面

### 2. remote-desktop-clients (Android)

**职责**：
- 实现 SPICE 协议客户端
- 处理远程桌面渲染
- 支持 .vv 文件直接打开

**关键模块**：
- `aSPICE-app/` - aSPICE Pro 主应用
- `bVNC/src/main/java/com/iiordanov/bVNC/` - 核心实现
- `remoteClientLib/src/main/cpp/virt-viewer/` - C 语言的 virt-viewer 实现

## .vv 文件处理流程

### 流程图

```
.vv 文件
    ↓
AndroidManifest.xml  Intent Filter
    ↓
RemoteCanvasActivity.onNewIntent()
    ↓
UriIntentParser 解析
    ↓
AbstractConnectionBean 加载配置
    ↓
SpiceCommunicator 建立连接
    ↓
RemoteCanvas 渲染桌面
```

### aSPICE 中的 .vv 文件处理

**AndroidManifest.xml 配置** (aSPICE-app/src/main/AndroidManifest.xml):

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.BROWSABLE" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:host="*" android:pathPattern=".*\\.vv" android:scheme="file" />
    <data android:host="*" android:pathPattern=".*\\.vv" android:scheme="content" />
</intent-filter>
```

**关键类**：
- `RemoteCanvasActivity` - 处理 incoming intent
- `UriIntentParser` - 解析 URI 和 .vv 文件
- `AbstractConnectionBean` - 连接配置数据模型
- `SpiceCommunicator` - SPICE 协议通信

## 数据模型

### VVConnection (Flutter)

```dart
class VVConnection {
  final ConnectionType type;        // spice, vnc
  final String? host;
  final int? port;
  final int? tlsPort;
  final String? password;
  final String? proxy;
  final String? title;
  final bool fullscreen;
  final bool? enableUsbredir;
  final bool? enableSmartcard;
  final bool? enableAudio;
  final bool? deleteThisFile;
  final String? rawContent;
}
```

### AbstractConnectionBean (Android)

Android 端对应的连接配置类，包含 95 个字段，覆盖所有 SPICE/VNC 连接参数。

## 技术栈

### Flutter 项目
- **框架**: Flutter 3.11+
- **状态管理**: Hooks Riverpod
- **路由**: 原生 Navigator
- **文件处理**: file_picker, path_provider
- **文件关联**: app_links

### Android 项目
- **语言**: Java, Kotlin, C/C++ (JNI)
- **构建**: Gradle
- **SPICE 协议**: 原生 C 实现 (virt-viewer)
- **NDK**: 用于原生库集成

## 通信架构

### 层次结构

```
┌─────────────────────────────────────┐
│      UI Layer (Flutter/Android)     │
├─────────────────────────────────────┤
│    Connection Management Layer       │
├─────────────────────────────────────┤
│    Protocol Layer (SPICE/VNC)       │
├─────────────────────────────────────┤
│    Network Transport Layer           │
└─────────────────────────────────────┘
```

## 魔改点规划

### 1. 增强 .vv 文件支持
- [ ] 支持更多 .vv 文件配置项
- [ ] 添加 .vv 文件编辑器
- [ ] 支持导出/导入 .vv 文件

### 2. 集成优化
- [ ] Flutter 端调用原生 SPICE 库
- [ ] 统一连接管理界面
- [ ] 添加连接测试功能

### 3. 用户体验
- [ ] 连接历史标签页
- [ ] 快速连接面板
- [ ] 收藏夹功能

## 相关文件索引

### Flutter 项目
- `lib/main.dart` - 应用入口，文件关联处理
- `lib/parsers/vv_parser.dart` - .vv 解析器
- `lib/models/vv_connection.dart` - 数据模型
- `lib/screens/viewer_screen.dart` - 查看器 UI

### Android 项目
- `aSPICE-app/src/main/AndroidManifest.xml` -  intent 过滤器
- `bVNC/src/main/java/com/iiordanov/bVNC/RemoteCanvasActivity.java` - 主 Activity
- `bVNC/src/main/java/com/iiordanov/bVNC/AbstractConnectionBean.java` - 连接配置
- `remoteClientLib/src/main/cpp/virt-viewer/virt-viewer-file.c` - .vv 文件 C 解析器

## 下一步

参见 [MODIFICATION_GUIDE.md](./MODIFICATION_GUIDE.md) 了解如何进行魔改。
