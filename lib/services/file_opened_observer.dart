import 'package:flutter/services.dart';

/// 监听文件打开事件
class FileOpenedObserver {
  static const MethodChannel _channel = MethodChannel('com.vvviewer/spice');

  static void Function(String uri)? onFileOpened;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onFileOpened') {
        final uri = call.arguments['uri'] as String?;
        if (uri != null && onFileOpened != null) {
          onFileOpened!(uri);
        }
      }
    });
  }
}
