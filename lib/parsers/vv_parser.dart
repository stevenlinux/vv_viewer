import '../models/connection_type.dart';
import '../models/vv_connection.dart';
import '../services/app_logger.dart';

class VVParser {
  static VVConnection parse(String content) {
    if (content.isEmpty) {
      AppLogger.warn(LogTags.vvParser, 'parse: empty content');
      throw ArgumentError('VV file content is empty');
    }

    AppLogger.debug(LogTags.vvParser, 'parse: content length = ${content.length}');

    final lines = content.split('\n');
    String? type;
    String? host;
    int? port;
    int? tlsPort;
    String? password;
    String? proxy;
    String? title;
    bool fullscreen = false;
    bool? enableUsbredir;
    bool? enableSmartcard;
    bool? enableAudio;
    bool? deleteThisFile;

    // ignore: unused_local_variable
    bool inVirtViewerSection = false;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        inVirtViewerSection = trimmed.toLowerCase() == '[virt-viewer]';
        continue;
      }

      // 即使不在 [virt-viewer] 部分，也尝试解析键值对（增加兼容性）
      if (!trimmed.contains('=')) continue;

      final parts = trimmed.split('=');
      if (parts.length < 2) continue;

      final key = parts[0].trim().toLowerCase();
      final value = parts.sublist(1).join('=').trim();

      switch (key) {
        case 'type':
          type = value;
          break;
        case 'host':
          host = value;
          break;
        case 'port':
          port = int.tryParse(value);
          break;
        case 'tls-port':
        case 'tls_port':
          tlsPort = int.tryParse(value);
          break;
        case 'password':
          password = value;
          break;
        case 'proxy':
          proxy = value;
          break;
        case 'title':
          title = value;
          break;
        case 'fullscreen':
        case 'toggle-fullscreen':
          fullscreen = value == '1' || value.toLowerCase() == 'true';
          break;
        case 'enable-usbredir':
        case 'enable_usbredir':
          enableUsbredir = value == '1' || value.toLowerCase() == 'true';
          break;
        case 'enable-smartcard':
        case 'enable_smartcard':
          enableSmartcard = value == '1' || value.toLowerCase() == 'true';
          break;
        case 'enable-audio':
        case 'enable_audio':
          enableAudio = value == '1' || value.toLowerCase() == 'true';
          break;
        case 'delete-this-file':
        case 'delete_this_file':
          deleteThisFile = value == '1' || value.toLowerCase() == 'true';
          break;
      }
    }

    // 如果没有找到 type，默认使用 spice（因为 PVE 主要使用 spice）
    if (type == null || type.isEmpty) {
      type = 'spice';
      AppLogger.debug(LogTags.vvParser, 'parse: type not found, defaulting to spice');
    }

    // 如果没有端口，使用默认端口
    final connectionType = ConnectionType.fromString(type);
    if (port == null && tlsPort == null) {
      switch (connectionType) {
        case ConnectionType.vnc:
          port = 5900;
          break;
        case ConnectionType.spice:
        case ConnectionType.unknown:
          port = 5900;
          break;
      }
      AppLogger.debug(LogTags.vvParser, 'parse: no port found, using default 5900');
    }

    AppLogger.info(LogTags.vvParser, 'parse: type=$type, host=$host, port=$port');

    return VVConnection(
      type: connectionType,
      host: host,
      port: port,
      tlsPort: tlsPort,
      password: password,
      proxy: proxy,
      title: title,
      fullscreen: fullscreen,
      enableUsbredir: enableUsbredir,
      enableSmartcard: enableSmartcard,
      enableAudio: enableAudio,
      deleteThisFile: deleteThisFile,
      rawContent: content,
    );
  }

  static String generate(VVConnection connection) {
    final buffer = StringBuffer();
    buffer.writeln('[virt-viewer]');
    buffer.writeln('type=${connection.type.name}');
    if (connection.host != null) {
      buffer.writeln('host=${connection.host}');
    }
    if (connection.port != null) {
      buffer.writeln('port=${connection.port}');
    }
    if (connection.tlsPort != null) {
      buffer.writeln('tls-port=${connection.tlsPort}');
    }
    if (connection.password != null) {
      buffer.writeln('password=${connection.password}');
    }
    if (connection.proxy != null) {
      buffer.writeln('proxy=${connection.proxy}');
    }
    if (connection.title != null) {
      buffer.writeln('title=${connection.title}');
    }
    buffer.writeln('fullscreen=${connection.fullscreen ? '1' : '0'}');
    if (connection.enableUsbredir != null) {
      buffer.writeln('enable-usbredir=${connection.enableUsbredir! ? '1' : '0'}');
    }
    if (connection.enableSmartcard != null) {
      buffer.writeln('enable-smartcard=${connection.enableSmartcard! ? '1' : '0'}');
    }
    if (connection.enableAudio != null) {
      buffer.writeln('enable-audio=${connection.enableAudio! ? '1' : '0'}');
    }
    if (connection.deleteThisFile != null) {
      buffer.writeln('delete-this-file=${connection.deleteThisFile! ? '1' : '0'}');
    }
    return buffer.toString();
  }
}
