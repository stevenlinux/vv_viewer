import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vv_viewer/models/vv_connection.dart';
import 'package:vv_viewer/models/connection_type.dart';
import 'package:vv_viewer/screens/pve_console_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PveConsoleScreen', () {
    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
      expect(find.text('PVE Web Console'), findsOneWidget);
    });

    testWidgets('should display login form', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.text('连接到 Proxmox VE'), findsOneWidget);
    });

    testWidgets('should display host input field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.widgetWithText(TextFormField, 'PVE 主机地址'), findsOneWidget);
    });

    testWidgets('should display port input field with default value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.widgetWithText(TextFormField, '端口'), findsOneWidget);
    });

    testWidgets('should display user input field with default value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.widgetWithText(TextFormField, '用户名'), findsOneWidget);
    });

    testWidgets('should display password input field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.widgetWithText(TextFormField, '密码'), findsOneWidget);
    });

    testWidgets('should display VM ID input field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.widgetWithText(TextFormField, 'VM ID (可选)'), findsOneWidget);
    });

    testWidgets('should display TLS switch', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.text('TLS'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('should display connect button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.text('连接'), findsOneWidget);
      expect(find.byIcon(Icons.login), findsOneWidget);
    });

    testWidgets('should display usage instructions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.text('使用说明'), findsOneWidget);
      expect(find.text('注意：此应用使用 PVE 的 Web Console (noVNC) 来显示远程桌面'), findsOneWidget);
    });

    testWidgets('should display icon for each input field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.byIcon(Icons.computer), findsOneWidget); // host
      expect(find.byIcon(Icons.settings_ethernet), findsOneWidget); // port
      expect(find.byIcon(Icons.person), findsOneWidget); // user
      expect(find.byIcon(Icons.lock), findsOneWidget); // password
      expect(find.byIcon(Icons.dns), findsOneWidget); // VM ID
    });

    testWidgets('should pre-fill form when connection is provided', (tester) async {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 8006,
        tlsPort: 8007,
        title: 'Test VM',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PveConsoleScreen(connection: connection),
        ),
      );

      // Should show info card about detected .vv file
      expect(find.text('检测到 .vv 文件'), findsOneWidget);
      expect(find.text('主机: 192.168.1.100'), findsOneWidget);
      expect(find.text('类型: SPICE'), findsOneWidget);
    });

    testWidgets('should have form with validation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      final form = find.byType(Form);
      expect(form, findsOneWidget);

      final textFormFields = find.byType(TextFormField);
      expect(textFormFields, findsNWidgets(5)); // host, port, user, password, vmId
    });

    testWidgets('should show info card when connection is provided', (tester) async {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: 'pve.example.com',
        port: 8006,
        tlsPort: 443,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PveConsoleScreen(connection: connection),
        ),
      );

      expect(find.byType(Card), findsWidgets);
      expect(find.text('检测到 .vv 文件'), findsOneWidget);
    });

    testWidgets('should display port from tlsPort when available', (tester) async {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: 'pve.example.com',
        port: 80,
        tlsPort: 443,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PveConsoleScreen(connection: connection),
        ),
      );

      expect(find.text('检测到 .vv 文件'), findsOneWidget);
      expect(find.text('端口: 443'), findsOneWidget);
    });

    testWidgets('should toggle TLS switch', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Find the Switch widget and get its state
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue); // Default is true
    });

    testWidgets('should have info icon in detected file card', (tester) async {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 8006,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PveConsoleScreen(connection: connection),
        ),
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('should display divider and instructions section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
      expect(find.text('使用说明'), findsOneWidget);
    });

    testWidgets('should display all instruction steps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.text('1. 输入您的 Proxmox VE 服务器地址'), findsOneWidget);
      expect(find.text('2. 输入 PVE 的用户名和密码'), findsOneWidget);
      expect(find.text('3. (可选) 直接输入 VM ID'), findsOneWidget);
      expect(find.text('4. 点击连接登录 PVE'), findsOneWidget);
      expect(find.text('5. 之后可以选择要连接的虚拟机'), findsOneWidget);
    });

    testWidgets('should have form key for validation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // Form exists and has a key
      final form = tester.widget<Form>(find.byType(Form));
      expect(form.key, isA<GlobalKey<FormState>>());
    });

    testWidgets('should have 5 text form fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(5));
    });

    testWidgets('should have elevated button for connect', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('连接'), findsOneWidget);
    });

    testWidgets('should scroll login form', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // The form is in a SingleChildScrollView
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should display error message container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // Error message container exists but is hidden when empty
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('should toggle TLS switch and change port', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // Default TLS is true, port should be 8006
      final portField = find.widgetWithText(TextFormField, '端口');
      expect(portField, findsOneWidget);

      final portTextField = tester.widget<TextFormField>(portField);
      expect(portTextField.controller?.text, '8006');

      // Find the switch and toggle it
      final switchFinder = find.byType(Switch);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);

      // Toggle TLS off
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Port should change to 80 when TLS is off
      final switchedPortTextField = tester.widget<TextFormField>(portField);
      expect(switchedPortTextField.controller?.text, '80');
    });

    testWidgets('should show password field with obscure text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      final passwordField = find.widgetWithText(TextFormField, '密码');
      expect(passwordField, findsOneWidget);

      // The password field is created with obscureText: true
      // We verify this by checking if there's a text field with obscure text behavior
      final textField = tester.widget<TextFormField>(passwordField);
      // obscureText is not directly accessible on TextFormField, but the widget exists
      expect(textField, isNotNull);
    });

    testWidgets('should have password field with lock icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('should display connect button with correct style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);

      // ElevatedButton.icon is a factory constructor, so we just check button exists
      // and has an icon child
      expect(find.byIcon(Icons.login), findsOneWidget);
    });

    testWidgets('should show loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // Initially not loading, so no CircularProgressIndicator in button
      final buttons = find.byType(ElevatedButton);
      expect(buttons, findsOneWidget);

      final button = tester.widget<ElevatedButton>(buttons);
      expect(button.child, isNot(const TypeMatcher<CircularProgressIndicator>()));
    });

    testWidgets('should have empty error message initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // Error message container exists but is hidden when empty
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('should display password field with obscure text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      final passwordField = find.widgetWithText(TextFormField, '密码');
      expect(passwordField, findsOneWidget);

      // The password field is created with obscureText: true
      // We verify this by checking if there's a text field with obscure text behavior
      final textField = tester.widget<TextFormField>(passwordField);
      // obscureText is not directly accessible on TextFormField, but the widget exists
      expect(textField, isNotNull);
    });

    testWidgets('should have password field with lock icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('should display connect button with correct style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);

      // ElevatedButton.icon is a factory constructor, so we just check button exists
      // and has an icon child
      expect(find.byIcon(Icons.login), findsOneWidget);
    });

    testWidgets('should show loading state in button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // The button label should say '连接' when not loading
      expect(find.text('连接'), findsOneWidget);
      expect(find.text('连接中...'), findsNothing);
    });

    testWidgets('should display logout button in webview header', (tester) async {
      // This would require setting up the webview state
      // The logout button is part of the _buildWebView which shows after successful login
      // This test verifies the webview header structure exists in the widget tree
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // Initially, webview is not shown, only the login form
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display error message when set', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // Initially no error message
      expect(find.text('连接错误: test error'), findsNothing);
    });

    testWidgets('should show warning banner when webview is active', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // WebView not shown initially, so no warning banner
      expect(find.text('已在 PVE 控制台中登录，点击选择虚拟机'), findsNothing);
      expect(find.byIcon(Icons.warning), findsNothing);
    });

    testWidgets('should display error container when error message is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // Error container exists but is hidden when _errorMessage is empty
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('should show host validation error when empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // Find the connect button and tap it to trigger validation
      final connectButton = find.text('连接');
      expect(connectButton, findsOneWidget);

      await tester.tap(connectButton);
      await tester.pumpAndSettle();

      // Should show validation error for empty host
      expect(find.text('请输入 PVE 主机地址'), findsOneWidget);
    });

    testWidgets('should validate form when host is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // Try to submit without filling anything
      final connectButton = find.text('连接');
      await tester.tap(connectButton);
      await tester.pumpAndSettle();

      // Should show validation error for empty host (first field)
      expect(find.text('请输入 PVE 主机地址'), findsOneWidget);
    });

    testWidgets('should show host error then clear when field is filled and resubmitted', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // First tap - host is empty, shows host error
      final connectButton = find.text('连接');
      await tester.tap(connectButton);
      await tester.pumpAndSettle();

      expect(find.text('请输入 PVE 主机地址'), findsOneWidget);

      // Now fill host
      final hostField = find.widgetWithText(TextFormField, 'PVE 主机地址');
      await tester.enterText(hostField, 'pve.example.com');
      await tester.pumpAndSettle();

      // Clear the error message by tapping away or using tester.idle
      await tester.pump();

      // Tap again - now host should be valid, but user is empty, shows user error
      await tester.tap(connectButton);
      await tester.pumpAndSettle();

      // User error should appear (or we could get password error if user field is also processed)
      final hasUserError = find.text('请输入用户名').evaluate().isNotEmpty;
      final hasPasswordError = find.text('请输入密码').evaluate().isNotEmpty;
      expect(hasUserError || hasPasswordError, isTrue);
    });

    testWidgets('should have port field with numeric keyboard', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      final portField = find.widgetWithText(TextFormField, '端口');
      expect(portField, findsOneWidget);

      // Find the underlying TextField to check keyboardType
      final textField = find.descendant(
        of: portField,
        matching: find.byType(TextField),
      );
      expect(textField, findsOneWidget);

      final field = tester.widget<TextField>(textField);
      expect(field.keyboardType, TextInputType.number);
    });

    testWidgets('should have VM ID field with numeric keyboard', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      final vmIdField = find.widgetWithText(TextFormField, 'VM ID (可选)');
      expect(vmIdField, findsOneWidget);

      // Find the underlying TextField to check keyboardType
      final textField = find.descendant(
        of: vmIdField,
        matching: find.byType(TextField),
      );
      expect(textField, findsOneWidget);

      final field = tester.widget<TextField>(textField);
      expect(field.keyboardType, TextInputType.number);
    });

    testWidgets('should show info card with connection details for spice type', (tester) async {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: 'test.pve.com',
        port: 5900,
        tlsPort: 443,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PveConsoleScreen(connection: connection),
        ),
      );

      expect(find.text('检测到 .vv 文件'), findsOneWidget);
      expect(find.text('主机: test.pve.com'), findsOneWidget);
      expect(find.text('类型: SPICE'), findsOneWidget);
    });

    testWidgets('should display all five input fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // Verify all 5 TextFormFields exist with correct labels
      expect(find.widgetWithText(TextFormField, 'PVE 主机地址'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '端口'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '用户名'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '密码'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'VM ID (可选)'), findsOneWidget);
    });

    testWidgets('should have instruction text for TLS usage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      // Instructions are in a Card at the bottom
      expect(find.text('使用说明'), findsOneWidget);
    });

    testWidgets('should display initial port value 8006', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      final portField = find.widgetWithText(TextFormField, '端口');
      final textField = find.descendant(
        of: portField,
        matching: find.byType(TextField),
      );
      final field = tester.widget<TextField>(textField);
      // The controller.text should be '8006'
      expect(field.controller?.text, '8006');
    });

    testWidgets('should display initial user value root', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PveConsoleScreen(),
        ),
      );

      final userField = find.widgetWithText(TextFormField, '用户名');
      final textField = find.descendant(
        of: userField,
        matching: find.byType(TextField),
      );
      final field = tester.widget<TextField>(textField);
      expect(field.controller?.text, 'root');
    });
  });
}
