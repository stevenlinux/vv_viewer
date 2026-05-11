import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vv_viewer/models/vv_connection.dart';
import 'package:vv_viewer/models/connection_type.dart';
import 'package:vv_viewer/services/spice_launcher_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpiceLauncherService', () {
    late MethodChannel channel;

    setUp(() {
      channel = const MethodChannel('com.vvviewer/spice');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'isAspiceInstalled':
            return true;
          case 'isEmbeddedAspiceAvailable':
            return true;
          case 'openAspiceStore':
            return true;
          case 'launchSpice':
            return {
              'success': true,
              'message': 'Launched successfully',
              'package': 'com.iiordanov.bVNC',
            };
          case 'launchSpiceWithFile':
            return {
              'success': true,
              'message': 'Launched with file',
            };
          case 'launchEmbeddedSpice':
            return {
              'success': true,
              'message': 'Embedded launch successful',
            };
          case 'launchEmbeddedSpiceWithFile':
            return {
              'success': true,
              'message': 'Embedded launch with file successful',
            };
          case 'resolveContentUri':
            return '/data/user/0/test.vv';
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    group('isAspiceInstalled', () {
      test('should return true when aSPICE is installed', () async {
        final result = await SpiceLauncherService.isAspiceInstalled();
        expect(result, true);
      });
    });

    group('isEmbeddedAspiceAvailable', () {
      test('should return true when embedded aSPICE is available', () async {
        final result = await SpiceLauncherService.isEmbeddedAspiceAvailable();
        expect(result, true);
      });
    });

    group('openAspiceStore', () {
      test('should return true on success', () async {
        final result = await SpiceLauncherService.openAspiceStore();
        expect(result, true);
      });
    });

    group('launchSpice', () {
      test('should return success with valid connection', () async {
        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          password: 'secret',
          title: 'Test VM',
        );

        final result = await SpiceLauncherService.launchSpice(
          connection: connection,
        );

        expect(result.success, true);
        expect(result.message, 'Launched successfully');
        expect(result.package, 'com.iiordanov.bVNC');
      });
    });

    group('launchSpiceWithFile', () {
      test('should return success with file path', () async {
        final result = await SpiceLauncherService.launchSpiceWithFile(
          '/data/test.vv',
        );

        expect(result.success, true);
        expect(result.message, 'Launched with file');
      });
    });

    group('launchEmbeddedSpice', () {
      test('should return success with valid connection', () async {
        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        final result = await SpiceLauncherService.launchEmbeddedSpice(
          connection: connection,
        );

        expect(result.success, true);
        expect(result.message, 'Embedded launch successful');
      });
    });

    group('launchEmbeddedSpiceWithFile', () {
      test('should return success with file path', () async {
        final result = await SpiceLauncherService.launchEmbeddedSpiceWithFile(
          '/data/test.vv',
        );

        expect(result.success, true);
        expect(result.message, 'Embedded launch with file successful');
      });
    });

    group('resolveContentUri', () {
      test('should return resolved path', () async {
        final result = await SpiceLauncherService.resolveContentUri(
          'content://com.example/test.vv',
        );

        expect(result, '/data/user/0/test.vv');
      });
    });

    group('platform error handling', () {
      test('should return false when isAspiceInstalled throws', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'isAspiceInstalled') {
            throw PlatformException(code: 'ERROR', message: 'Channel error');
          }
          return null;
        });

        final result = await SpiceLauncherService.isAspiceInstalled();
        expect(result, false);
      });

      test('should return error result when launchSpice throws', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'launchSpice') {
            throw PlatformException(code: 'ERROR', message: 'Launch failed');
          }
          return null;
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        final result = await SpiceLauncherService.launchSpice(
          connection: connection,
        );

        expect(result.success, false);
        expect(result.error, 'PLATFORM_ERROR');
      });

      test('should return false when openAspiceStore throws PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'openAspiceStore') {
            throw PlatformException(code: 'ERROR', message: 'Store error');
          }
          return null;
        });

        final result = await SpiceLauncherService.openAspiceStore();
        expect(result, false);
      });

      test('should return error result when launchSpiceWithFile throws PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'launchSpiceWithFile') {
            throw PlatformException(code: 'ERROR', message: 'File launch error');
          }
          return null;
        });

        final result = await SpiceLauncherService.launchSpiceWithFile(
          '/data/test.vv',
        );

        expect(result.success, false);
        expect(result.error, 'PLATFORM_ERROR');
        expect(result.message, 'File launch error');
      });

      test('should return false when isEmbeddedAspiceAvailable throws PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'isEmbeddedAspiceAvailable') {
            throw PlatformException(code: 'ERROR', message: 'Channel error');
          }
          return null;
        });

        final result = await SpiceLauncherService.isEmbeddedAspiceAvailable();
        expect(result, false);
      });

      test('should return error result when launchEmbeddedSpice throws PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'launchEmbeddedSpice') {
            throw PlatformException(code: 'ERROR', message: 'Embedded launch error');
          }
          return null;
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        final result = await SpiceLauncherService.launchEmbeddedSpice(
          connection: connection,
        );

        expect(result.success, false);
        expect(result.error, 'PLATFORM_ERROR');
      });

      test('should return null when resolveContentUri throws PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'resolveContentUri') {
            throw PlatformException(code: 'ERROR', message: 'URI resolve error');
          }
          return null;
        });

        final result = await SpiceLauncherService.resolveContentUri(
          'content://com.example/test.vv',
        );

        expect(result, isNull);
      });

      test('should return error result when launchEmbeddedSpiceWithFile throws PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'launchEmbeddedSpiceWithFile') {
            throw PlatformException(code: 'ERROR', message: 'Embedded file launch error');
          }
          return null;
        });

        final result = await SpiceLauncherService.launchEmbeddedSpiceWithFile(
          '/data/test.vv',
        );

        expect(result.success, false);
        expect(result.error, 'PLATFORM_ERROR');
        expect(result.message, 'Embedded file launch error');
      });
    });
  });
}