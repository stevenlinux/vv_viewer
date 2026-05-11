import 'package:flutter_test/flutter_test.dart';
import 'package:vv_viewer/models/spice_launch_result.dart';

void main() {
  group('SpiceLaunchResult', () {
    test('should create with success=true', () {
      final result = SpiceLaunchResult(
        success: true,
        message: 'Launched successfully',
      );

      expect(result.success, true);
      expect(result.message, 'Launched successfully');
      expect(result.error, isNull);
      expect(result.package, isNull);
    });

    test('should create with success=false', () {
      final result = SpiceLaunchResult(
        success: false,
        error: 'ASPICE_NOT_INSTALLED',
        message: 'Please install aSPICE',
      );

      expect(result.success, false);
      expect(result.error, 'ASPICE_NOT_INSTALLED');
      expect(result.message, 'Please install aSPICE');
    });

    test('should create with all fields', () {
      final result = SpiceLaunchResult(
        success: true,
        error: null,
        message: 'Success',
        package: 'com.iiordanov.bVNC',
      );

      expect(result.success, true);
      expect(result.package, 'com.iiordanov.bVNC');
    });

    group('fromMap', () {
      test('should parse valid map with success=true', () {
        final map = {
          'success': true,
          'message': 'Launched',
          'package': 'com.example.app',
        };

        final result = SpiceLaunchResult.fromMap(map);

        expect(result.success, true);
        expect(result.message, 'Launched');
        expect(result.package, 'com.example.app');
      });

      test('should parse valid map with success=false', () {
        final map = {
          'success': false,
          'error': 'CONNECTION_REFUSED',
          'message': 'Connection failed',
        };

        final result = SpiceLaunchResult.fromMap(map);

        expect(result.success, false);
        expect(result.error, 'CONNECTION_REFUSED');
        expect(result.message, 'Connection failed');
      });

      test('should handle null map', () {
        final result = SpiceLaunchResult.fromMap(null);

        expect(result.success, false);
        expect(result.error, 'NULL_RESULT');
        expect(result.message, '没有返回结果');
      });

      test('should handle map with missing fields', () {
        final map = <dynamic, dynamic>{};

        final result = SpiceLaunchResult.fromMap(map);

        expect(result.success, false);
      });

      test('should default success to false when null', () {
        final map = {
          'success': null,
        };

        final result = SpiceLaunchResult.fromMap(map);

        expect(result.success, false);
      });
    });

    group('needsInstall', () {
      test('should return true when error is ASPICE_NOT_INSTALLED', () {
        final result = SpiceLaunchResult(
          success: false,
          error: 'ASPICE_NOT_INSTALLED',
        );

        expect(result.needsInstall, true);
      });

      test('should return false when error is something else', () {
        final result = SpiceLaunchResult(
          success: false,
          error: 'CONNECTION_FAILED',
        );

        expect(result.needsInstall, false);
      });

      test('should return false when success is true', () {
        final result = SpiceLaunchResult(
          success: true,
        );

        expect(result.needsInstall, false);
      });

      test('should return false when error is null', () {
        final result = SpiceLaunchResult(
          success: false,
        );

        expect(result.needsInstall, false);
      });
    });
  });
}