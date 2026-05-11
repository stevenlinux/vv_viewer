# VV Viewer 技术文档

欢迎来到 VV Viewer 项目的技术文档中心！这里是修改和魔改此项目的起点。

## 项目状态

✅ **已实现整合方案**：Flutter UI + aSPICE 原生连接能力  
✅ **已实现内嵌 aSPICE**：将 aSPICE Pro 作为库模块直接内置（开发中）

## 快速开始

| 文档 | 说明 | 适用场景 |
|------|------|----------|
| **[SETUP.md](./SETUP.md)** | 开发环境搭建指南 | 第一次接触项目，需要配置开发环境 |
| **[DEVELOPMENT_PRACTICE.md](./DEVELOPMENT_PRACTICE.md)** | 大型项目开发实践 | 开发流程、速查命令、检查清单 |
| **[VV_FILE_FORMAT.md](./VV_FILE_FORMAT.md)** | .vv 文件格式详解 | 需要处理或解析 .vv 配置文件 |
| **[MODIFICATION_GUIDE.md](./MODIFICATION_GUIDE.md)** | aSPICE 魔改指南 | 修改 aSPICE Pro 源码 |
| **[INTEGRATION.md](./INTEGRATION.md)** | 整合项目开发指南 | 使用已实现的 Flutter + aSPICE 整合方案 ⭐ |
| **[EMBEDDED_SPICE.md](./EMBEDDED_SPICE.md)** | 内置 aSPICE 开发文档 ⭐ | 内置 aSPICE Pro 的完整开发指南 |

## 项目概览

本项目包含三个主要部分：

### 1. vv_viewer (Flutter) ⭐
跨平台 .vv 文件查看器 + aSPICE 调用能力。

**已实现功能**：
- ✅ .vv 文件解析和显示
- ✅ 连接历史管理
- ✅ 检查 aSPICE 安装状态
- ✅ 一键启动 SPICE 连接
- ✅ 自动跳转应用商店安装 aSPICE

**位置**: `/Users/steve/ClaudeProjects/vv_viewer/`

### 2. remote-desktop-clients (Android)
aSPICE Pro 源码，包含完整的 SPICE 协议实现和 .vv 文件支持。

**位置**: `/Users/steve/ClaudeProjects/remote-desktop-clients/`

## 文档导航

### 新手入门（推荐）
1. 阅读 [INTEGRATION.md](./INTEGRATION.md) 了解整合方案
2. 阅读 [SETUP.md](./SETUP.md) 配置开发环境
3. 运行项目测试

### 修改项目
1. 参考 [INTEGRATION.md](./INTEGRATION.md)（整合方案）
2. 或参考 [MODIFICATION_GUIDE.md](./MODIFICATION_GUIDE.md)（魔改 aSPICE）
3. 查阅 [VV_FILE_FORMAT.md](./VV_FILE_FORMAT.md) (如涉及 .vv 文件)

### 常见任务

#### 使用整合方案（推荐）
→ [INTEGRATION.md - 工作流程](./INTEGRATION.md#工作流程)

#### 添加新功能到整合版本
→ [INTEGRATION.md - 扩展开发](./INTEGRATION.md#扩展开发)

#### 魔改 aSPICE 源码
→ [MODIFICATION_GUIDE.md - 魔改点示例](./MODIFICATION_GUIDE.md#魔改点示例)

#### 修复 .vv 文件相关问题
→ [VV_FILE_FORMAT.md](./VV_FILE_FORMAT.md)

#### 理解现有代码
→ [ARCHITECTURE.md - 相关文件索引](./ARCHITECTURE.md#相关文件索引)

#### 配置开发环境
→ [SETUP.md](./SETUP.md)

## 项目位置备忘

```
/Users/steve/ClaudeProjects/
├── vv_viewer/              # Flutter 项目（已整合 aSPICE 调用）⭐
│   ├── lib/
│   │   ├── main.dart                  # 应用入口
│   │   ├── models/                    # 数据模型
│   │   ├── parsers/                   # .vv 解析器
│   │   ├── screens/                   # UI 页面
│   │   │   └── embedded_spice_screen.dart  # ⭐ 内嵌 SPICE 屏幕
│   │   └── services/
│   │       ├── spice_launcher_service.dart  # ⭐ aSPICE 调用服务
│   │       └── storage_service.dart
│   ├── android/
│   │   ├── app/src/main/
│   │   │   ├── kotlin/com/vvviewer/vv_viewer/
│   │   │   │   ├── MainActivity.kt    # ⭐ Platform Channel 实现
│   │   │   │   ├── SpiceView.kt       # ⭐ SPICE PlatformView
│   │   │   │   └── SpiceViewFactory.kt # ⭐ PlatformView 工厂
│   │   │   ├── res/xml/
│   │   │   │   └── file_paths.xml     # ⭐ FileProvider 配置
│   │   │   └── AndroidManifest.xml     # ⭐ 更新的清单文件
│   │   ├── remoteClientLib/           # ⭐ 内嵌 SPICE 协议库
│   │   ├── bVNC/                     # ⭐ 内嵌 UI 组件库
│   │   ├── common/                   # ⭐ 通用工具库
│   │   └── pubkeyGenerator/          # ⭐ 密钥生成库
│   ├── docs/
│   │   ├── EMBEDDED_SPICE.md         # ⭐ 内置 aSPICE 开发文档
│   │   └── ... (其他文档)
│   └── pubspec.yaml        # Flutter 依赖配置
│
└── remote-desktop-clients/ # aSPICE Pro 源码（原始，参考用）
    ├── aSPICE-app/         # aSPICE 主应用
    ├── bVNC/               # 核心库
    └── remoteClientLib/    # 公共库 (含 C/C++ 代码)
```

## 快速链接

### 关键文件（整合方案 ⭐）

**Flutter 项目:**
- [lib/services/spice_launcher_service.dart](../lib/services/spice_launcher_service.dart) - Platform Channel 服务
- [lib/screens/viewer_screen.dart](../lib/screens/viewer_screen.dart) - 增强的查看器页面
- [android/app/src/main/kotlin/.../MainActivity.kt](../android/app/src/main/kotlin/com/vvviewer/vv_viewer/MainActivity.kt) - Android 原生实现
- [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) - 清单文件
- [android/app/src/main/res/xml/file_paths.xml](../android/app/src/main/res/xml/file_paths.xml) - FileProvider 配置

**aSPICE 项目:**
- [AndroidManifest.xml](../../remote-desktop-clients/aSPICE-app/src/main/AndroidManifest.xml) - aSPICE 清单文件
- [RemoteCanvasActivity.java](../../remote-desktop-clients/bVNC/src/main/java/com/iiordanov/bVNC/RemoteCanvasActivity.java) - 主 Activity
- [virt-viewer-file.c](../../remote-desktop-clients/remoteClientLib/src/main/cpp/virt-viewer/virt-viewer-file.c) - .vv 文件 C 解析器

### 文档
- [EMBEDDED_SPICE.md](./EMBEDDED_SPICE.md) - ⭐ 内置 aSPICE 开发文档（推荐先看这个）
- [INTEGRATION.md](./INTEGRATION.md) - 整合项目开发指南
- [ARCHITECTURE.md](./ARCHITECTURE.md) - 项目架构
- [VV_FILE_FORMAT.md](./VV_FILE_FORMAT.md) - .vv 文件格式
- [MODIFICATION_GUIDE.md](./MODIFICATION_GUIDE.md) - aSPICE 魔改指南
- [SETUP.md](./SETUP.md) - 环境搭建

## 更新日志

- 2026-04-20 - 内置 aSPICE Pro 到 vv_viewer，添加 EMBEDDED_SPICE.md 开发文档 ⭐
- 2026-04-20 - 实现 iOS Platform Channel，添加完整单元测试和 Widget 测试（52个测试全部通过）
- 2026-04-20 - 实现 Flutter + aSPICE 整合方案，添加 INTEGRATION.md
- 2026-04-20 - 初始文档创建，包含架构、格式、魔改指南、环境搭建

## 反馈与贡献

如有文档问题或建议，请根据实际情况更新对应的文档文件。

---

**提示**: 每次打开项目时，先看本文档索引，快速找到需要的信息！
