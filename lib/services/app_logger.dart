/// 应用日志模块
/// 提供结构化日志输出，支持 DEBUG/INFO/WARN/ERROR 级别
class AppLogger {
  static void debug(String tag, String msg) {
    _log('DEBUG', tag, msg);
  }

  static void info(String tag, String msg) {
    _log('INFO', tag, msg);
  }

  static void warn(String tag, String msg) {
    _log('WARN', tag, msg);
  }

  static void error(String tag, String msg, [Object? e, StackTrace? st]) {
    final buffer = StringBuffer('[${DateTime.now()}][ERROR][$tag] $msg');
    if (e != null) {
      buffer.write(' | Error: $e');
    }
    if (st != null) {
      buffer.write('\nStackTrace: $st');
    }
    print(buffer.toString());
  }

  static void _log(String level, String tag, String msg) {
    print('[${DateTime.now()}][$level][$tag] $msg');
  }
}

/// 各模块对应的日志 Tag
class LogTags {
  static const String main = 'Main';
  static const String spiceLauncher = 'SpiceLauncher';
  static const String vvParser = 'VvParser';
  static const String connection = 'Connection';
  static const String platformChannel = 'PlatformChannel';
}
