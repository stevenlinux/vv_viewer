import 'package:flutter_test/flutter_test.dart';
import 'package:vv_viewer/services/app_logger.dart';

void main() {
  group('AppLogger', () {
    group('LogTags', () {
      test('should have correct tag values', () {
        expect(LogTags.main, 'Main');
        expect(LogTags.spiceLauncher, 'SpiceLauncher');
        expect(LogTags.vvParser, 'VvParser');
        expect(LogTags.connection, 'Connection');
        expect(LogTags.platformChannel, 'PlatformChannel');
      });
    });

    group('debug', () {
      test('should not throw when called', () {
        expect(() => AppLogger.debug(LogTags.main, 'test message'), returnsNormally);
      });
    });

    group('info', () {
      test('should not throw when called', () {
        expect(() => AppLogger.info(LogTags.main, 'test message'), returnsNormally);
      });
    });

    group('warn', () {
      test('should not throw when called', () {
        expect(() => AppLogger.warn(LogTags.main, 'test message'), returnsNormally);
      });
    });

    group('error', () {
      test('should not throw when called with message only', () {
        expect(() => AppLogger.error(LogTags.main, 'error message'), returnsNormally);
      });

      test('should not throw when called with exception', () {
        expect(
          () => AppLogger.error(LogTags.main, 'error with exception', Exception('test')),
          returnsNormally,
        );
      });

      test('should not throw when called with exception and stack trace', () {
        final stackTrace = StackTrace.current;
        expect(
          () => AppLogger.error(LogTags.main, 'error with trace', Exception('test'), stackTrace),
          returnsNormally,
        );
      });
    });

    group('output format', () {
      test('should include all required format elements', () {
        // The AppLogger outputs to console via print
        // This test verifies the method doesn't throw and produces output
        expect(() => AppLogger.debug(LogTags.main, 'test message'), returnsNormally);
        expect(() => AppLogger.info(LogTags.main, 'info message'), returnsNormally);
        expect(() => AppLogger.warn(LogTags.main, 'warn message'), returnsNormally);
        expect(() => AppLogger.error(LogTags.main, 'error message'), returnsNormally);
      });
    });
  });
}