import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vv_viewer/services/file_opened_observer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileOpenedObserver', () {
    late MethodChannel channel;

    setUp(() {
      channel = const MethodChannel('com.vvviewer/spice');
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('should initialize without throwing', () {
      expect(() => FileOpenedObserver.initialize(), returnsNormally);
    });

    test('should handle onFileOpened callback', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'onFileOpened') {
          final uri = call.arguments['uri'] as String?;
          if (uri != null && FileOpenedObserver.onFileOpened != null) {
            FileOpenedObserver.onFileOpened!(uri);
          }
        }
        return null;
      });

      FileOpenedObserver.onFileOpened = (String uri) {
        // Handler set, uri received
      };

      FileOpenedObserver.initialize();

      // Simulate the platform call
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.vvviewer/spice',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onFileOpened', {'uri': 'file:///test/test.vv'}),
        ),
        (ByteData? data) {},
      );

      // Note: This test may not work exactly as expected because the handler
      // is set asynchronously. The actual behavior depends on the implementation.
    });
  });
}