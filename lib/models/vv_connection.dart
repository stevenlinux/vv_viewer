import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'connection_type.dart';

class VVConnection extends Equatable {
  final ConnectionType type;
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
  final DateTime? lastUsed;

  const VVConnection({
    required this.type,
    this.host,
    this.port,
    this.tlsPort,
    this.password,
    this.proxy,
    this.title,
    this.fullscreen = false,
    this.enableUsbredir,
    this.enableSmartcard,
    this.enableAudio,
    this.deleteThisFile,
    this.rawContent,
    this.lastUsed,
  });

  /// 序列化到 JSON Map
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'host': host,
    'port': port,
    'tlsPort': tlsPort,
    'password': password,
    'proxy': proxy,
    'title': title,
    'fullscreen': fullscreen,
    'enableUsbredir': enableUsbredir,
    'enableSmartcard': enableSmartcard,
    'enableAudio': enableAudio,
    'deleteThisFile': deleteThisFile,
    'rawContent': rawContent,
    'lastUsed': lastUsed?.toIso8601String(),
  };

  /// 从 JSON Map 反序列化
  factory VVConnection.fromJson(Map<String, dynamic> json) {
    return VVConnection(
      type: ConnectionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ConnectionType.unknown,
      ),
      host: json['host'] as String?,
      port: json['port'] as int?,
      tlsPort: json['tlsPort'] as int?,
      password: json['password'] as String?,
      proxy: json['proxy'] as String?,
      title: json['title'] as String?,
      fullscreen: json['fullscreen'] as bool? ?? false,
      enableUsbredir: json['enableUsbredir'] as bool?,
      enableSmartcard: json['enableSmartcard'] as bool?,
      enableAudio: json['enableAudio'] as bool?,
      deleteThisFile: json['deleteThisFile'] as bool?,
      rawContent: json['rawContent'] as String?,
      lastUsed: json['lastUsed'] != null
          ? DateTime.tryParse(json['lastUsed'] as String)
          : null,
    );
  }

  /// 序列化到 JSON 字符串
  String toJsonString() => jsonEncode(toJson());

  /// 从 JSON 字符串反序列化
  factory VVConnection.fromJsonString(String json) =>
      VVConnection.fromJson(jsonDecode(json) as Map<String, dynamic>);

  VVConnection copyWith({
    ConnectionType? type,
    String? host,
    int? port,
    int? tlsPort,
    String? password,
    String? proxy,
    String? title,
    bool? fullscreen,
    bool? enableUsbredir,
    bool? enableSmartcard,
    bool? enableAudio,
    bool? deleteThisFile,
    String? rawContent,
    DateTime? lastUsed,
  }) {
    return VVConnection(
      type: type ?? this.type,
      host: host ?? this.host,
      port: port ?? this.port,
      tlsPort: tlsPort ?? this.tlsPort,
      password: password ?? this.password,
      proxy: proxy ?? this.proxy,
      title: title ?? this.title,
      fullscreen: fullscreen ?? this.fullscreen,
      enableUsbredir: enableUsbredir ?? this.enableUsbredir,
      enableSmartcard: enableSmartcard ?? this.enableSmartcard,
      enableAudio: enableAudio ?? this.enableAudio,
      deleteThisFile: deleteThisFile ?? this.deleteThisFile,
      rawContent: rawContent ?? this.rawContent,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  bool get isValid => host != null && host!.isNotEmpty && (port != null || tlsPort != null);

  int? get effectivePort => tlsPort ?? port;

  String get displayTitle {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    if (host != null) {
      return '$host${effectivePort != null ? ':$effectivePort' : ''}';
    }
    return 'Unknown Connection';
  }

  @override
  List<Object?> get props => [
        type,
        host,
        port,
        tlsPort,
        password,
        proxy,
        title,
        fullscreen,
        enableUsbredir,
        enableSmartcard,
        enableAudio,
        deleteThisFile,
      ];
}
