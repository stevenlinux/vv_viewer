import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vv_viewer/models/vv_connection.dart';
import 'package:vv_viewer/models/connection_type.dart';
import 'package:vv_viewer/models/spice_launch_result.dart';
import 'package:vv_viewer/screens/embedded_spice_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.vvviewer/spice');

  group('EmbeddedSpiceScreen', () {
    testWidgets('should display app bar with connection title', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpice') {
          return SpiceLaunchResult(success: true).toMap();
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
        title: 'Test VM',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection),
        ),
      );

      expect(find.text('Test VM'), findsWidgets);
    });

    testWidgets('should display loading indicator initially', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpice') {
          return SpiceLaunchResult(success: true).toMap();
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('正在启动内嵌 SPICE...'), findsOneWidget);
    });

    testWidgets('should have proper structure with Scaffold and AppBar', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpice') {
          return SpiceLaunchResult(success: true).toMap();
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should use displayTitle from connection', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpice') {
          return SpiceLaunchResult(success: true).toMap();
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
        title: 'My Virtual Machine',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection),
        ),
      );

      expect(find.text('My Virtual Machine'), findsWidgets);
    });

    testWidgets('should use host:port as fallback title when title is null', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpice') {
          return SpiceLaunchResult(success: true).toMap();
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection),
        ),
      );

      expect(find.text('192.168.1.100:5900'), findsWidgets);
    });

    testWidgets('should have loading message with connection title below', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpice') {
          return SpiceLaunchResult(success: true).toMap();
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
        title: 'Test Server',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection),
        ),
      );

      expect(find.text('正在启动内嵌 SPICE...'), findsOneWidget);
      expect(find.text('Test Server'), findsWidgets);
    });

    testWidgets('should display error view when launch fails', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpiceWithFile') {
          return SpiceLaunchResult(success: false, message: 'Launch failed').toMap();
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection, filePath: '/test/file.vv'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('启动内嵌 SPICE 失败'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should display error message when launch fails', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpiceWithFile') {
          return SpiceLaunchResult(success: false, message: 'Connection refused').toMap();
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection, filePath: '/test/file.vv'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Connection refused'), findsOneWidget);
    });

    testWidgets('should display retry button when launch fails', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpiceWithFile') {
          return SpiceLaunchResult(success: false, message: 'Error').toMap();
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection, filePath: '/test/file.vv'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('重试'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should display return button when launch fails', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpiceWithFile') {
          return SpiceLaunchResult(success: false, message: 'Error').toMap();
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection, filePath: '/test/file.vv'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('返回'), findsOneWidget);
    });

    testWidgets('should launch with file when filePath is provided', (tester) async {
      bool launchCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpiceWithFile') {
          launchCalled = true;
          return SpiceLaunchResult(success: true).toMap();
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection, filePath: '/test/file.vv'),
        ),
      );

      await tester.pump();
      expect(launchCalled, isTrue);
    });

    testWidgets('should launch without file when filePath is null', (tester) async {
      bool launchCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpice') {
          launchCalled = true;
          return SpiceLaunchResult(success: true).toMap();
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection),
        ),
      );

      await tester.pump();
      expect(launchCalled, isTrue);
    });

    testWidgets('should handle exception during launch', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpice') {
          throw Exception('Launch error');
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('启动内嵌 SPICE 失败'), findsOneWidget);
    });

    testWidgets('should handle exception during launch with file', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launchEmbeddedSpiceWithFile') {
          throw PlatformException(code: 'ERROR', message: 'File launch exception');
        }
        return null;
      });

      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbeddedSpiceScreen(connection: connection, filePath: '/test/file.vv'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('启动内嵌 SPICE 失败'), findsOneWidget);
    });
  });
}
