# aSPICE Pro 魔改指南

## 目录

1. [环境搭建](#环境搭建)
2. [项目结构理解](#项目结构理解)
3. [魔改点示例](#魔改点示例)
4. [编译与调试](#编译与调试)
5. [常见问题](#常见问题)

## 环境搭建

### 必备工具

- **Android Studio** - 最新稳定版
- **JDK 11+** - Android 开发需要
- **Android SDK** - API 21+
- **NDK** - 用于编译原生代码
- **Git** - 版本控制
- **Flutter** (可选) - 如需开发 Flutter 部分

### 快速开始

```bash
# 进入项目目录
cd /Users/steve/ClaudeProjects/remote-desktop-clients

# 下载预编译依赖
./download-prebuilt-dependencies.sh

# 准备项目
./bVNC/prepare_project.sh --skip-build libs nopath
```

### Android Studio 配置

1. 打开 Android Studio
2. 选择 "Open an existing Android Studio project"
3. 选择 `remote-desktop-clients` 目录
4. 等待 Gradle 同步完成
5. 安装缺失的 SDK 版本（通常需要 android-28, android-29, android-30）

## 项目结构理解

### 模块说明

```
remote-desktop-clients/
├── aSPICE-app/              # aSPICE Pro 付费版
│   └── src/main/
│       └── AndroidManifest.xml
├── freeaSPICE-app/          # aSPICE 免费版
├── bVNC/                    # 核心库（所有客户端共用）
│   ├── src/main/java/com/iiordanov/bVNC/
│   │   ├── RemoteCanvasActivity.java    # 主 Activity
│   │   ├── AbstractConnectionBean.java  # 连接配置
│   │   ├── aSPICE.java                  # SPICE 主类
│   │   └── protocol/                     # 协议实现
│   └── src/main/res/                     # 资源文件
├── remoteClientLib/         # 公共库（含 C/C++ 代码）
│   ├── src/main/java/com/undatech/opaque/
│   └── src/main/cpp/
│       └── virt-viewer/      # virt-viewer C 实现
│           ├── virt-viewer-file.c    # .vv 文件解析
│           └── virt-viewer-util.c
└── Opaque-app/              # oVirt/Proxmox 客户端
```

### 关键类说明

#### RemoteCanvasActivity

- **路径**: `bVNC/src/main/java/com/iiordanov/bVNC/RemoteCanvasActivity.java`
- **职责**: 主界面，处理 Intent，管理连接生命周期
- **关键方法**:
  - `onCreate()` - Activity 创建
  - `onNewIntent()` - 处理新 Intent（包括 .vv 文件打开）
  - `handleConnectionIntent()` - 处理连接 Intent

#### AbstractConnectionBean

- **路径**: `bVNC/src/main/java/com/iiordanov/bVNC/AbstractConnectionBean.java`
- **职责**: 连接配置数据模型（95个字段）
- **关键字段**:
  - `ADDRESS` - 主机地址
  - `PORT` - 端口
  - `TLSPORT` - TLS 端口
  - `PASSWORD` - 密码
  - `CONNECTIONTYPE` - 连接类型

#### aSPICE

- **路径**: `bVNC/src/main/java/com/iiordanov/bVNC/aSPICE.java`
- **职责**: SPICE 客户端主类

#### SpiceCommunicator

- **路径**: `remoteClientLib/src/main/java/com/undatech/opaque/SpiceCommunicator.java`
- **职责**: SPICE 协议通信层

## 魔改点示例

### 魔改 1: 增强 .vv 文件支持

#### 目标
添加自定义配置项支持，增强 .vv 文件解析能力。

#### 实现步骤

1. **修改 AndroidManifest.xml** (如需要新的 intent filter)

   文件位置: `aSPICE-app/src/main/AndroidManifest.xml`

2. **添加新的配置字段**

   在 `AbstractConnectionBean.java` 中添加新字段（如果需要）:

   ```java
   // 在 GEN_FIELD_* 常量区添加
   public static final String GEN_FIELD_MY_CUSTOM_FIELD = "MY_CUSTOM_FIELD";
   public static final int GEN_ID_MY_CUSTOM_FIELD = 95;

   // 在 GEN_CREATE SQL 中添加
   "MY_CUSTOM_FIELD TEXT," +
   ```

3. **修改 .vv 文件解析逻辑**

   如果需要修改 native 层解析，编辑:
   `remoteClientLib/src/main/cpp/virt-viewer/virt-viewer-file.c`

   ```c
   // 添加新的 property
   g_object_class_install_property(G_OBJECT_CLASS(klass), PROP_MY_FIELD,
       g_param_spec_string("my-field", "my-field", "my-field", NULL,
                           G_PARAM_STATIC_STRINGS | G_PARAM_READWRITE));
   ```

4. **在 Java 层读取新字段**

   在 `UriIntentParser` 或相关类中添加解析代码。

### 魔改 2: 添加连接历史标签功能

#### 目标
给连接历史添加标签，支持分类管理。

#### 实现步骤

1. **数据库升级**

   在 `AbstractConnectionBean` 中添加标签字段（参考魔改 1）。

2. **修改 UI**

   修改连接列表页面 `ConnectionListActivity.java`，添加标签显示和筛选。

3. **添加编辑界面**

   创建标签编辑对话框或 Activity。

### 魔改 3: 集成 Flutter 模块

#### 目标
在现有 Android 项目中集成 Flutter 模块，用于新功能开发。

#### 实现步骤

1. **创建 Flutter 模块**

   ```bash
   cd /Users/steve/ClaudeProjects
   flutter create -t module flutter_module
   ```

2. **在 settings.gradle 中添加**

   ```groovy
   setBinding(new Binding([gradle: this]))
   evaluate(new File(
     settingsDir.parentFile,
     'flutter_module/.android/include_flutter.groovy'
   ))
   ```

3. **在 app/build.gradle 中添加依赖**

   ```groovy
   dependencies {
     implementation project(':flutter')
   }
   ```

4. **创建 FlutterActivity**

   ```java
   public class MyFlutterActivity extends FlutterActivity {
       // 用于启动 Flutter 模块
   }
   ```

### 魔改 4: 修改启动界面和主题

#### 目标
自定义 aSPICE 的外观和品牌。

#### 实现步骤

1. **替换图标**

   位置: `aSPICE-app/src/main/res/mipmap-*/`

   - `icon_aspice.png` - 主图标
   - `banner_aspice.png` - 横幅图标

2. **修改应用名称**

   编辑 `bVNC/src/main/res/values/strings.xml`:

   ```xml
   <string name="aspice_app_name">我的 SPICE 客户端</string>
   ```

3. **自定义主题**

   编辑 `bVNC/src/main/res/values/themes.xml`:

   ```xml
   <style name="AppThemeDayNight" parent="Theme.AppCompat.DayNight">
       <item name="colorPrimary">@color/my_primary</item>
       <item name="colorPrimaryDark">@color/my_primary_dark</item>
       <item name="colorAccent">@color/my_accent</item>
   </style>
   ```

4. **修改启动画面**

   可在 `RemoteCanvasActivity.java` 中添加自定义启动画面。

### 魔改 5: 添加快速连接面板

#### 目标
在主界面添加常用连接的快速访问面板。

#### 实现步骤

1. **创建快捷方式数据库**

   新建 `QuickConnectBean.java` 存储快捷连接。

2. **修改主界面布局**

   编辑 `bVNC/src/main/res/layout/connection_grid_activity.xml`，添加快速连接面板。

3. **添加快捷方式管理界面**

   创建 Activity 用于添加/编辑快捷连接。

## 编译与调试

### 编译 aSPICE

```bash
# 使用 Gradle 编译
cd /Users/steve/ClaudeProjects/remote-desktop-clients

# Debug 版本
./gradlew aSPICE-app:assembleDebug

# Release 版本
./gradlew aSPICE-app:assembleRelease
```

### 安装到设备

```bash
# 安装 Debug 版本
./gradlew aSPICE-app:installDebug

# 或使用 adb
adb install -r aSPICE-app/build/outputs/apk/debug/aSPICE-app-debug.apk
```

### 调试技巧

1. **查看日志**

   ```bash
   adb logcat -s aSPICE:* *:S
   ```

2. **调试 .vv 文件打开**

   ```bash
   # 推送测试文件
   adb push test.vv /sdcard/

   # 模拟打开文件
   adb shell am start -a android.intent.action.VIEW \
       -d file:///sdcard/test.vv \
       -t application/x-virt-viewer \
       com.iiordanov.aSPICE/.RemoteCanvasActivity
   ```

3. **Native 调试**

   需要在 `build.gradle` 中启用 debug symbols:

   ```groovy
   android {
       buildTypes {
           debug {
               jniDebuggable true
               debuggable true
           }
       }
   }
   ```

## 常见问题

### Q: Gradle 同步失败怎么办？

A: 常见解决方案：
1. 检查 `local.properties` 中的 SDK 路径是否正确
2. 运行 `./gradlew clean` 然后重新同步
3. 确保安装了所需的 SDK 版本（android-28, 29, 30）
4. 检查网络连接（需要下载依赖）

### Q: 如何只修改 aSPICE 而不影响其他客户端？

A: aSPICE-app 是独立模块，大多数修改可以在这里进行。如需修改核心功能，注意 bVNC 模块是共用的。

### Q: Native 库编译失败怎么办？

A: 建议使用预编译库：
```bash
./download-prebuilt-dependencies.sh
```
这样不需要编译原生代码。

### Q: 如何测试 .vv 文件关联？

A: 有几种方式：
1. 在文件管理器中点击 .vv 文件
2. 使用 adb 命令模拟（见上文）
3. 在 Android Studio 的 Run Configuration 中设置 Intent

### Q: 修改后如何版本管理？

A: 建议：
1. 创建自己的分支
2. 每次魔改创建单独的 commit
3. 撰写清晰的 commit message

## 进阶魔改建议

1. **添加云同步** - 连接配置云端备份
2. **支持更多协议** - 如 RDP、SSH
3. **会话录制** - 录制远程桌面会话
4. **多窗口支持** - 同时打开多个连接
5. **插件系统** - 支持第三方扩展

## 相关文档

- [ARCHITECTURE.md](./ARCHITECTURE.md) - 项目架构详解
- [VV_FILE_FORMAT.md](./VV_FILE_FORMAT.md) - .vv 文件格式说明
- [SETUP.md](./SETUP.md) - 开发环境搭建指南
