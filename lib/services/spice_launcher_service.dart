import 'dart:async';
import 'package:flutter/services.dart';
import '../models/vv_connection.dart';
import '../models/spice_launch_result.dart';
import 'app_logger.dart';

/// SPICE 连接启动服务
/// 通过 Platform Channel 调用原生 aSPICE 应用
class SpiceLauncherService {
  static const MethodChannel _channel = MethodChannel('com.vvviewer/spice');

  /// 检查 aSPICE 是否已安装
  static Future<bool> isAspiceInstalled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAspiceInstalled');
      final installed = result ?? false;
      AppLogger.debug(LogTags.spiceLauncher, 'isAspiceInstalled: $installed');
      return installed;
    } on PlatformException catch (e) {
      AppLogger.warn(LogTags.spiceLauncher, 'isAspiceInstalled failed: ${e.message}');
      return false;
    }
  }

  /// 打开应用商店下载 aSPICE
  static Future<bool> openAspiceStore() async {
    try {
      final result = await _channel.invokeMethod<bool>('openAspiceStore');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 使用连接信息启动 SPICE
  static Future<SpiceLaunchResult> launchSpice({
    required VVConnection connection,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'launchSpice',
        {
          'host': connection.host,
          'port': connection.port,
          'tlsPort': connection.tlsPort,
          'password': connection.password,
          'title': connection.title,
        },
      );

      return SpiceLaunchResult.fromMap(result);
    } on PlatformException catch (e) {
      return SpiceLaunchResult(
        success: false,
        error: 'PLATFORM_ERROR',
        message: e.message ?? '未知错误',
      );
    }
  }

  /// 使用 .vv 文件启动 SPICE
  static Future<SpiceLaunchResult> launchSpiceWithFile(String filePath) async {
    try {
      AppLogger.debug(LogTags.spiceLauncher, 'launchSpiceWithFile: $filePath');
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'launchSpiceWithFile',
        {'filePath': filePath},
      );

      final launchResult = SpiceLaunchResult.fromMap(result);
      AppLogger.info(LogTags.spiceLauncher, 'launchSpiceWithFile result: ${launchResult.success}');
      return launchResult;
    } on PlatformException catch (e) {
      AppLogger.error(LogTags.spiceLauncher, 'launchSpiceWithFile failed', e);
      return SpiceLaunchResult(
        success: false,
        error: 'PLATFORM_ERROR',
        message: e.message ?? '未知错误',
      );
    }
  }

  /// 检查内嵌 aSPICE 是否可用
  static Future<bool> isEmbeddedAspiceAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isEmbeddedAspiceAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 使用内嵌模式启动 SPICE
  static Future<SpiceLaunchResult> launchEmbeddedSpice({
    required VVConnection connection,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'launchEmbeddedSpice',
        {
          'host': connection.host,
          'port': connection.port,
          'tlsPort': connection.tlsPort,
          'password': connection.password,
          'title': connection.title,
        },
      );

      return SpiceLaunchResult.fromMap(result);
    } on PlatformException catch (e) {
      return SpiceLaunchResult(
        success: false,
        error: 'PLATFORM_ERROR',
        message: e.message ?? '未知错误',
      );
    }
  }

  /// 解析 content URI 为真实文件路径
  static Future<String?> resolveContentUri(String uriString) async {
    try {
      final result = await _channel.invokeMethod<String>('resolveContentUri', {'uri': uriString});
      return result;
    } on PlatformException {
      return null;
    }
  }

  /// 使用内嵌模式和 .vv 文件启动 SPICE
  static Future<SpiceLaunchResult> launchEmbeddedSpiceWithFile(String filePath) async {
    try {
      AppLogger.debug(LogTags.spiceLauncher, 'launchEmbeddedSpiceWithFile: $filePath');
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'launchEmbeddedSpiceWithFile',
        {'filePath': filePath},
      );

      final launchResult = SpiceLaunchResult.fromMap(result);
      AppLogger.info(LogTags.spiceLauncher, 'launchEmbeddedSpiceWithFile result: ${launchResult.success}');
      return launchResult;
    } on PlatformException catch (e) {
      AppLogger.error(LogTags.spiceLauncher, 'launchEmbeddedSpiceWithFile failed', e);
      return SpiceLaunchResult(
        success: false,
        error: 'PLATFORM_ERROR',
        message: e.message ?? '未知错误',
      );
    }
  }
}
