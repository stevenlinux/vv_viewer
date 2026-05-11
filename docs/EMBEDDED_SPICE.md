# 内置 aSPICE Pro 开发文档

## 概述

本文档记录如何将 aSPICE Pro 的开源版本直接内置到 vv_viewer 中，实现无需外部应用即可使用的完整 SPICE 客户端。

## 架构说明

### 两种集成方式

vv_viewer 现在支持两种 SPICE 连接方式：

1. **外部调用模式**（原有）：通过 Intent 调用独立的 aSPICE 应用
2. **内嵌模式**（新增）：将 aSPICE 作为库模块嵌入，直接在应用内使用

### 目录结构

```
vv_viewer/android/
├── app/                              # Flutter 应用主模块
├── remoteClientLib/                  # ⭐ 核心 SPICE 协议库
│   ├── src/main/java/com/undatech/opaque/
│   │   ├── SpiceCommunicator.java   # SPICE 协议核心
│   │   └── Connection.java          # 连接接口
│   └── src/main/jniLibs/            # 原生库 (.so 文件)
│       ├── armeabi-v7a/
│       ├── arm64-v8a/
│       ├── x86/
│       └── x86_64/
├── bVNC/                             # ⭐ UI 组件库
│   └── src/main/java/com/iiordanov/bVNC/
│       ├── protocol/
│       │   └── RemoteSpiceConnection.kt  # SPICE 连接管理
│       └── input/
│           ├── RemoteSpiceKeyboard.java
│           └── RemoteSpicePointer.java
├── common/                           # 通用工具库
├── pubkeyGenerator/                  # SSH 密钥生成库
└── remoteClientLib/jni/libs/deps/FreeRDP/client/Android/Studio/freeRDPCore/
```

## 库模块依赖关系

```
app
├── bVNC
│   ├── pubkeyGenerator
│   ├── remoteClientLib
│   ├── common
│   └── freeRDPCore
├── remoteClientLib
│   └── freeRDPCore
├── common
└── pubkeyGenerator
    └── common
```

### 关键模块说明

**remoteClientLib**
- 核心协议库，包含 SPICE 的 Java 实现和 JNI 绑定
- `SpiceCommunicator.java` 是主要的 SPICE 通信类
- 预编译的原生库在 `jniLibs/` 目录下

**bVNC**
- UI 层和连接管理
- `RemoteSpiceConnection.kt` 管理 SPICE 连接生命周期
- 包含输入处理（键盘、鼠标）

## Gradle 配置

### 版本配置

所有模块使用统一版本：
- **Kotlin**: 2.2.21
- **Android Gradle Plugin**: 8.13.2
- **compileSdk**: 35
- **targetSdk**: 35
- **minSdk**: 21
- **Java**: 21

### settings.gradle.kts

```kotlin
include(":app")
include(":remoteClientLib")
include(":remoteClientLib:jni:libs:deps:FreeRDP:client:Android:Studio:freeRDPCore")
include(":bVNC")
include(":common")
include(":pubkeyGenerator")
```

### app/build.gradle.kts 依赖

```kotlin
dependencies {
    implementation(project(":bVNC"))
    implementation(project(":remoteClientLib"))
    implementation(project(":common"))
    implementation(project(":pubkeyGenerator"))
}
```

## 关键类和接口

### SpiceCommunicator.java

**路径**: `remoteClientLib/src/main/java/com/undatech/opaque/SpiceCommunicator.java`

这是 SPICE 协议的核心类，主要方法：

```java
// 连接 SPICE 服务器
public void connectSpice(String address, String port, String tlsPort,
                         String password, String caCertPath,
                         String caCert, String certSubject, boolean enableSound)

// 断开连接
public void disconnect()

// 发送鼠标事件
public void SpiceButtonEvent(int button, int state, int x, int y)

// 发送键盘事件
public void SpiceKeyEvent(int key, boolean down)

// 请求分辨率变更
public void requestResolution(int x, int y)

// 从 .vv 文件启动会话
public void StartSessionFromVvFile(String vvFile)
```

**原生方法（JNI）**：
```java
private native boolean SpiceClientConnect(String host, int port, String tlsPort, ...);
private native void SpiceClientDisconnect();
private native void SpiceButtonEvent(int button, int state, int x, int y);
private native void SpiceKeyEvent(int key, boolean down);
private native void UpdateBitmap();
```

### RemoteSpiceConnection.kt

**路径**: `bVNC/src/main/java/com/iiordanov/bVNC/protocol/RemoteSpiceConnection.kt`

管理 SPICE 连接的生命周期：

```kotlin
class RemoteSpiceConnection(
    context: Context,
    connection: Connection?,
    canvas: Viewable,
    hideKeyboardAndExtraKeys: Runnable,
) : RemoteOpaqueConnection(...) {

    // 初始化 SPICE 连接
    private fun initializeSpiceConnection()

    // 启动 SPICE 连接
    private fun startSpiceConnection()

    // 开始连接（对外接口）
    override fun startConnection()

    // 初始化连接线程
    override fun initializeConnection()
}
```

## PlatformView 实现

### SpiceView.kt

**路径**: `app/src/main/kotlin/com/vvviewer/vv_viewer/SpiceView.kt`

这是嵌入 Flutter 的 PlatformView 实现：

```kotlin
class SpiceView(
    context: Context,
    id: Int,
    creationParams: Map<String?, Any?>?
) : PlatformView {

    private val remoteCanvas: RemoteCanvas

    init {
        // 初始化 RemoteCanvas
        // 设置连接参数
        // 建立 SPICE 连接
    }

    override fun getView(): View {
        return remoteCanvas
    }

    override fun dispose() {
        // 清理资源，断开连接
    }
}
```

### SpiceViewFactory.kt

**路径**: `app/src/main/kotlin/com/vvviewer/vv_viewer/SpiceViewFactory.kt`

```kotlin
class SpiceViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        return SpiceView(context, viewId, args as? Map<String?, Any?>)
    }
}
```

### MainActivity.kt 更新

在 `MainActivity.kt` 中注册 PlatformView：

```kotlin
override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    // 注册 PlatformView
    flutterEngine.platformViewsController.registry.registerViewFactory(
        "com.vvviewer/spice_view",
        SpiceViewFactory()
    )

    // 原有的 MethodChannel 配置...
}
```

## Flutter 实现

### embedded_spice_screen.dart

**路径**: `lib/screens/embedded_spice_screen.dart`

使用 `AndroidView` 显示嵌入式 SPICE 视图：

```dart
class EmbeddedSpiceScreen extends StatefulWidget {
  final VVConnection connection;

  const EmbeddedSpiceScreen({super.key, required this.connection});

  @override
  State<EmbeddedSpiceScreen> createState() => _EmbeddedSpiceScreenState();
}

class _EmbeddedSpiceScreenState extends State<EmbeddedSpiceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.connection.displayTitle),
      ),
      body: AndroidView(
        viewType: 'com.vvviewer/spice_view',
        creationParams: {
          'host': widget.connection.host,
          'port': widget.connection.port,
          'tlsPort': widget.connection.tlsPort,
          'password': widget.connection.password,
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}
```

### viewer_screen.dart 更新

在查看器页面添加内嵌模式选项：

```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmbeddedSpiceScreen(
          connection: widget.connection,
        ),
      ),
    );
  },
  icon: const Icon(Icons.dvr),
  label: const Text('内嵌 SPICE 连接'),
),
```

## 权限配置

### AndroidManifest.xml

确保以下权限已添加：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## 原生库说明

### jniLibs 目录结构

```
remoteClientLib/src/main/jniLibs/
├── armeabi-v7a/
│   ├── libspice.so (~1.5MB)
│   ├── libgstreamer_android.so (~66MB)
│   └── libc++_shared.so (~1MB)
├── arm64-v8a/
│   ├── libspice.so
│   ├── libgstreamer_android.so
│   └── libc++_shared.so
├── x86/
│   ├── libspice.so
│   ├── libgstreamer_android.so
│   └── libc++_shared.so
└── x86_64/
    ├── libspice.so
    ├── libgstreamer_android.so
    └── libc++_shared.so
```

### 主要原生库

- **libspice.so**: SPICE 客户端核心库
- **libgstreamer_android.so**: GStreamer 多媒体框架（用于音频）
- **libc++_shared.so**: C++ 运行时库

这些库是预编译的，无需重新编译 NDK 代码。

## 构建指南

### 环境要求

- Flutter 3.11+
- Android Studio Hedgehog+
- JDK 21
- Android SDK API 35

### 构建步骤

```bash
# 进入项目目录
cd /Users/steve/ClaudeProjects/vv_viewer

# 获取依赖
flutter pub get

# 运行到 Android 设备
flutter run

# 构建 APK
flutter build apk --release
```

### 常见构建问题

**问题**: 库模块版本不匹配
**解决**: 确保所有模块使用相同的 compileSdk、targetSdk、minSdk

**问题**: 原生库找不到
**解决**: 检查 remoteClientLib/src/main/jniLibs/ 目录是否完整

**问题**: Kotlin 版本冲突
**解决**: 统一使用 Kotlin 2.2.21

## 测试策略

### 单元测试

- 测试 Platform Channel 方法调用
- 测试连接参数解析
- 测试错误处理

### 集成测试

- 测试嵌入式 SPICE 连接流程
- 测试断开连接
- 测试错误处理

### 手动测试用例

1. 从查看器页面启动嵌入式 SPICE
2. 连接到测试 SPICE 服务器
3. 验证显示正常
4. 验证鼠标/键盘输入
5. 断开连接并验证清理

## 后续修改同步指南

当需要修改代码时，请按照以下步骤同步更新文档：

### 1. 修改代码前
- 检查本文档是否有相关说明
- 如果涉及新的架构决策，先更新设计部分

### 2. 修改代码时
- 记录关键变更点
- 更新相关文件路径引用

### 3. 修改代码后
- 更新本文档的对应章节
- 如果是新增功能，添加到相应部分
- 更新"关键文件路径"部分

### 4. 文档检查清单
- [ ] 架构说明是否仍然准确
- [ ] 目录结构是否有变更
- [ ] 关键类和接口是否有更新
- [ ] Gradle 配置是否有变化
- [ ] 权限配置是否需要调整
- [ ] 构建步骤是否仍然有效

## 关键文件路径索引

### 核心配置
- `/Users/steve/ClaudeProjects/vv_viewer/android/settings.gradle.kts` - 模块配置
- `/Users/steve/ClaudeProjects/vv_viewer/android/build.gradle.kts` - 根构建配置
- `/Users/steve/ClaudeProjects/vv_viewer/android/app/build.gradle.kts` - 应用构建配置

### 库模块
- `/Users/steve/ClaudeProjects/vv_viewer/android/remoteClientLib/` - SPICE 协议库
- `/Users/steve/ClaudeProjects/vv_viewer/android/bVNC/` - UI 组件库
- `/Users/steve/ClaudeProjects/vv_viewer/android/common/` - 通用工具
- `/Users/steve/ClaudeProjects/vv_viewer/android/pubkeyGenerator/` - 密钥生成

### Android 原生
- `/Users/steve/ClaudeProjects/vv_viewer/android/app/src/main/kotlin/com/vvviewer/vv_viewer/MainActivity.kt`
- `/Users/steve/ClaudeProjects/vv_viewer/android/app/src/main/kotlin/com/vvviewer/vv_viewer/SpiceView.kt`
- `/Users/steve/ClaudeProjects/vv_viewer/android/app/src/main/kotlin/com/vvviewer/vv_viewer/SpiceViewFactory.kt`

### Flutter 层
- `/Users/steve/ClaudeProjects/vv_viewer/lib/screens/embedded_spice_screen.dart`
- `/Users/steve/ClaudeProjects/vv_viewer/lib/screens/viewer_screen.dart`
- `/Users/steve/ClaudeProjects/vv_viewer/lib/services/spice_launcher_service.dart`

### aSPICE 核心类
- `/Users/steve/ClaudeProjects/vv_viewer/android/remoteClientLib/src/main/java/com/undatech/opaque/SpiceCommunicator.java`
- `/Users/steve/ClaudeProjects/vv_viewer/android/bVNC/src/main/java/com/iiordanov/bVNC/protocol/RemoteSpiceConnection.kt`

## 常见问题排查

### 问题: 应用启动时崩溃，提示找不到 native 库
**检查**:
1. remoteClientLib 的 jniLibs 目录是否完整
2. 设备架构是否在支持列表中（armeabi-v7a, arm64-v8a, x86, x86_64）
3. remoteClientLib 的 build.gradle.kts 中是否正确配置了 jniLibs

### 问题: SPICE 连接失败
**检查**:
1. 网络连接是否正常
2. 主机地址和端口是否正确
3. 是否需要 TLS 端口
4. 密码是否正确

### 问题: 显示黑屏
**检查**:
1. SpiceCommunicator 是否正确初始化
2. Viewable 接口是否正确实现
3. 帧缓冲区更新回调是否正常工作

---

**最后更新**: 2026-04-20
**维护者**: 开发团队
**文档版本**: 1.0
