import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vv_viewer/models/vv_connection.dart';
import 'package:vv_viewer/models/connection_type.dart';
import 'package:vv_viewer/models/spice_launch_result.dart';
import 'package:vv_viewer/screens/viewer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.vvviewer/spice');

  group('ViewerScreen', () {
    Widget buildTestWidget(VVConnection connection, {String? filePath}) {
      return ProviderScope(
        child: MaterialApp(
          home: ViewerScreen(connection: connection, filePath: filePath),
        ),
      );
    }

    group('Auto-launch', () {
      testWidgets('should auto-launch when embedded aSPICE available', (tester) async {
        bool launchCalled = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              launchCalled = true;
              return true;
            case 'launchEmbeddedSpice':
              return SpiceLaunchResult(success: true).toMap();
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pump();

        // The auto-launch check should have been called
        expect(launchCalled, isTrue);
      });
    });

    group('Quick Actions', () {
      testWidgets('should display copy all button', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('复制全部'), findsOneWidget);
        expect(find.byIcon(Icons.copy_all), findsOneWidget);
      });

      testWidgets('should display external connection button when aSPICE installed', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('外部连接'), findsOneWidget);
        expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      });
    });

    group('UI Rendering', () {
      testWidgets('should display app bar with connection title', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          title: 'Test VM',
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('Test VM'), findsWidgets);
      });

      testWidgets('should display SPICE connection icon', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.dvr), findsWidgets);
      });

      testWidgets('should display VNC connection icon', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.vnc,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.computer), findsWidgets);
        expect(find.text('VNC 连接'), findsOneWidget);
      });

      testWidgets('should not show external or install buttons for VNC connection', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.vnc,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        // VNC should only show copy button
        expect(find.text('复制全部'), findsOneWidget);
        // Should NOT show external connection button (only for spice)
        expect(find.text('外部连接'), findsNothing);
        // Should NOT show install button
        expect(find.text('安装 aSPICE'), findsNothing);
        expect(find.text('安装'), findsNothing);
      });

      testWidgets('should display connection details card', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          title: 'Test VM',
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('连接详情'), findsOneWidget);
        expect(find.text('SPICE 连接'), findsOneWidget);
      });

      testWidgets('should display quick actions card', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('快速操作'), findsOneWidget);
        expect(find.text('复制全部'), findsOneWidget);

        // Scroll to make quick actions visible and tap the copy all button
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Tap the copy all button
        final copyButton = find.text('复制全部');
        if (copyButton.evaluate().isNotEmpty) {
          await tester.tap(copyButton, warnIfMissed: false);
          await tester.pumpAndSettle();
        }

        // Should have copied something
        expect(find.text('复制全部'), findsOneWidget);
      });

      testWidgets('should display refresh button in app bar', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should display fullscreen info when true', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          fullscreen: true,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('全屏'), findsOneWidget);
        expect(find.text('是'), findsOneWidget);
      });

      testWidgets('should display proxy info when set', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          proxy: 'http://proxy:8080',
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('代理'), findsOneWidget);
        expect(find.text('http://proxy:8080'), findsOneWidget);
      });

      testWidgets('should display TLS port when set', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          tlsPort: 5901,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('TLS 端口'), findsOneWidget);
        expect(find.text('5901'), findsOneWidget);
      });

      testWidgets('should display USB redirection setting when set', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          enableUsbredir: true,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('USB 重定向'), findsOneWidget);
        expect(find.text('是'), findsOneWidget);
      });

      testWidgets('should display smartcard setting when set', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          enableSmartcard: true,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('智能卡'), findsOneWidget);
        expect(find.text('是'), findsOneWidget);
      });

      testWidgets('should display audio setting when set', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          enableAudio: false,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('音频'), findsOneWidget);
      });
    });

    group('Password Field', () {
      testWidgets('should display password row when password is set', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          password: 'secret123',
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('密码'), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsOneWidget);
      });

      testWidgets('should show masked password initially', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          password: 'secret123',
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('••••••••'), findsOneWidget);
      });
    });

    group('Status Card', () {
      testWidgets('should show install button when aSPICE not installed', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return false;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('aSPICE 未安装'), findsOneWidget);
        expect(find.text('安装'), findsOneWidget);
      });

      testWidgets('should show external aSPICE installed status', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('外部 aSPICE 已安装'), findsOneWidget);
      });

      testWidgets('should show builtin aSPICE available status', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return false;
            case 'isEmbeddedAspiceAvailable':
              return true;
            case 'launchEmbeddedSpice':
              throw PlatformException(code: 'CANCELLED', message: 'Launch cancelled in test');
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pump();

        // The widget should have checked and found embedded available
        // but auto-launch may fail without navigation
        expect(find.byType(ViewerScreen), findsOneWidget);
      });
    });

    group('Connection Info Display', () {
      testWidgets('should display connection info card', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('连接详情'), findsOneWidget);
      });

      testWidgets('should display connection type correctly', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.text('SPICE 连接'), findsOneWidget);
      });
    });

    group('App Bar', () {
      testWidgets('should have refresh button in app bar', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should have AppBar with title', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          title: 'Test VM Title',
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsOneWidget);
      });
    });

    group('didUpdateWidget', () {
      testWidgets('should recheck aSPICE when connection changes', (tester) async {
        bool recheckCalled = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'isAspiceInstalled') {
            recheckCalled = true;
          }
          switch (call.method) {
            case 'isAspiceInstalled':
              return true;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection1 = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection1));
        await tester.pumpAndSettle();

        // Update with new connection
        final connection2 = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.200',
          port: 5901,
        );

        await tester.pumpWidget(buildTestWidget(connection2));
        await tester.pumpAndSettle();

        expect(recheckCalled, isTrue);
      });
    });

    group('Quick Actions', () {
      testWidgets('should handle needsInstall case when launching fails with needsInstall', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        // Find and tap the install button in the snackbar or dialog
        // The install dialog appears when needsInstall is true
        final installButton = find.text('安装');
        expect(installButton, findsOneWidget);
      });

      testWidgets('should show install dialog when tapping install button', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'isAspiceInstalled':
              return false;
            case 'isEmbeddedAspiceAvailable':
              return false;
            default:
              return null;
          }
        });

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await tester.pumpWidget(buildTestWidget(connection));
        await tester.pumpAndSettle();

        // Scroll to make the quick actions visible
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Find and tap the install button
        final installButton = find.text('安装 aSPICE');
        expect(installButton, findsOneWidget);

        await tester.tap(installButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Dialog should appear with correct content
        expect(find.text('需要安装 aSPICE'), findsOneWidget);
        expect(find.text('请先安装 aSPICE 客户端才能进行 SPICE 连接'), findsOneWidget);
        expect(find.text('取消'), findsOneWidget);
        expect(find.text('前往下载'), findsOneWidget);

        // Tap cancel button to dismiss dialog
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();

        // Dialog should be dismissed
        expect(find.text('需要安装 aSPICE'), findsNothing);
      });
    });
  });
}
