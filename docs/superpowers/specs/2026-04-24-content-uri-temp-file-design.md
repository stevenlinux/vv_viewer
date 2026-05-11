# Content URI Temp File 处理方案

## 问题

当从文件管理器打开 .vv 文件时，Android 发送的是 `content://...` URI，而不是文件路径。

### 根因链路

1. 文件管理器打开 .vv → Android 发送 `content://...` URI
2. `_handleUri()` 调用 `uri.toFilePath()` → 返回 `/document/primary:...`（content URI 路径，非真实文件路径）
3. `file.exists()` → false
4. `filePath.value = filePathStr` **不执行**
5. `connection.value` IS set（VVParser 成功解析）→ ViewerScreen 显示
6. 用户点击"内嵌连接" → `widget.filePath` = null
7. `launchEmbeddedSpice(connection)` 被调用（不是 WithFile）→ 只有 spice:// URI，没有 .vv 文件内容
8. App crash（SPICE URI 缺少 CA 证书等信息）

## 解决方案：最小改动

在 Flutter 的 `_handleUri()` 中，当 `file.exists()` 为 false 时（content URI 的特征），调用原生 Platform Channel 方法解析 content URI 并写入临时文件。

### 修改点

#### 1. MainActivity.kt — 新增 `resolveContentUri` 方法

```kotlin
"resolveContentUri" -> {
    val uriString = call.argument<String>("uri")
    resolveContentUri(uriString, result)
}
```

实现：
- 接收 content URI 字符串
- 用 `ContentResolver` 读取输入流
- 写入 `cacheDir/vv_temp_<timestamp>.vv`
- 返回真实文件路径

#### 2. spice_launcher_service.dart — 新增 Dart 端调用

```dart
static Future<String?> resolveContentUri(String uriString) async {
  try {
    final result = await _channel.invokeMethod<String>('resolveContentUri', {'uri': uriString});
    return result;
  } on PlatformException {
    return null;
  }
}
```

#### 3. main.dart — 修改 `_handleUri` 兜底逻辑

```dart
Future<void> _handleUri(Uri uri, ...) async {
  try {
    final filePathStr = uri.toFilePath();
    final file = File(filePathStr);
    if (await file.exists()) {
      // 已有逻辑
    } else {
      // 兜底：尝试用原生方法解析 content URI
      final realPath = await SpiceLauncherService.resolveContentUri(uri.toString());
      if (realPath != null) {
        final content = await File(realPath).readAsString();
        final parsed = VVParser.parse(content);
        if (parsed.isValid) {
          connection.value = parsed;
          filePath.value = realPath;
        }
      }
    }
  } catch (e) { ... }
}
```

## 修改文件清单

- `android/app/src/main/kotlin/com/vvviewer/vv_viewer/MainActivity.kt`
- `lib/services/spice_launcher_service.dart`
- `lib/main.dart`

## 验证方法

1. 从文件管理器打开 .vv 文件
2. 确认 ViewerScreen 显示正常
3. 点击"内嵌连接"
4. 确认 RemoteCanvasActivity 收到完整 .vv 文件内容（不再 crash）
