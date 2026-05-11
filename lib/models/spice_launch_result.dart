/// SPICE 启动结果
class SpiceLaunchResult {
  final bool success;
  final String? error;
  final String? message;
  final String? package;

  SpiceLaunchResult({
    required this.success,
    this.error,
    this.message,
    this.package,
  });

  factory SpiceLaunchResult.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return SpiceLaunchResult(
        success: false,
        error: 'NULL_RESULT',
        message: '没有返回结果',
      );
    }

    return SpiceLaunchResult(
      success: map['success'] as bool? ?? false,
      error: map['error'] as String?,
      message: map['message'] as String?,
      package: map['package'] as String?,
    );
  }

  bool get needsInstall => error == 'ASPICE_NOT_INSTALLED';

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      if (error != null) 'error': error,
      if (message != null) 'message': message,
      if (package != null) 'package': package,
    };
  }
}
