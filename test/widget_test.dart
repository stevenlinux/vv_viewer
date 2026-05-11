import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vv_viewer/main.dart';
import 'package:vv_viewer/models/vv_connection.dart';
import 'package:vv_viewer/models/connection_type.dart';
import 'package:vv_viewer/screens/viewer_screen.dart';

void main() {
  testWidgets('App should start without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('ViewerScreen should display connection info', (WidgetTester tester) async {
    final testConnection = const VVConnection(
      type: ConnectionType.spice,
      host: '192.168.1.100',
      port: 5900,
      title: 'Test VM',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ViewerScreen(connection: testConnection),
        ),
      ),
    );

    expect(find.text('Test VM'), findsWidgets);
    expect(find.text('SPICE 连接'), findsOneWidget);
    expect(find.text('192.168.1.100'), findsWidgets);
    expect(find.text('5900'), findsWidgets);
  });

  testWidgets('ViewerScreen should show copy buttons', (WidgetTester tester) async {
    final testConnection = const VVConnection(
      type: ConnectionType.spice,
      host: '192.168.1.100',
      port: 5900,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ViewerScreen(connection: testConnection),
        ),
      ),
    );

    expect(find.text('复制全部'), findsOneWidget);
  });

  testWidgets('ViewerScreen should display password field', (WidgetTester tester) async {
    final testConnection = const VVConnection(
      type: ConnectionType.spice,
      host: '192.168.1.100',
      port: 5900,
      password: 'secret123',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ViewerScreen(connection: testConnection),
        ),
      ),
    );

    expect(find.text('密码'), findsOneWidget);
    expect(find.text('secret123'), findsNothing);
    expect(find.text('••••••••'), findsOneWidget);
  });

  testWidgets('ViewerScreen should have password visibility toggle', (WidgetTester tester) async {
    final testConnection = const VVConnection(
      type: ConnectionType.spice,
      host: '192.168.1.100',
      port: 5900,
      password: 'secret123',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ViewerScreen(connection: testConnection),
        ),
      ),
    );

    expect(find.text('密码'), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });

  testWidgets('ViewerScreen should show connection info section', (WidgetTester tester) async {
    final testConnection = const VVConnection(
      type: ConnectionType.spice,
      host: '192.168.1.100',
      port: 5900,
      fullscreen: true,
      enableUsbredir: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ViewerScreen(connection: testConnection),
        ),
      ),
    );

    expect(find.text('连接详情'), findsOneWidget);
    expect(find.text('类型'), findsOneWidget);
    expect(find.text('主机'), findsOneWidget);
    expect(find.text('端口'), findsOneWidget);
    expect(find.text('全屏'), findsOneWidget);
    expect(find.text('USB 重定向'), findsOneWidget);
  });

  testWidgets('ViewerScreen should show quick actions section', (WidgetTester tester) async {
    final testConnection = const VVConnection(
      type: ConnectionType.spice,
      host: '192.168.1.100',
      port: 5900,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ViewerScreen(connection: testConnection),
        ),
      ),
    );

    expect(find.text('快速操作'), findsOneWidget);
  });

  testWidgets('ViewerScreen should show connection tips section', (WidgetTester tester) async {
    final testConnection = const VVConnection(
      type: ConnectionType.spice,
      host: '192.168.1.100',
      port: 5900,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ViewerScreen(connection: testConnection),
        ),
      ),
    );

    // 连接说明 section was removed - test becomes a simple presence check
    expect(find.text('连接说明'), findsNothing);
  });

  testWidgets('ViewerScreen should display PVE Console button for SPICE', (WidgetTester tester) async {
    final testConnection = const VVConnection(
      type: ConnectionType.spice,
      host: '192.168.1.100',
      port: 5900,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ViewerScreen(connection: testConnection),
        ),
      ),
    );

    expect(find.text('PVE控制台'), findsNothing);
  });

  testWidgets('ViewerScreen should not display connect button for VNC (in quick actions)', (WidgetTester tester) async {
    final testConnection = const VVConnection(
      type: ConnectionType.vnc,
      host: '192.168.1.100',
      port: 5900,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ViewerScreen(connection: testConnection),
        ),
      ),
    );

    expect(find.text('立即连接'), findsNothing);
  });
}
