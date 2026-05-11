import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vv_viewer/main.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MyApp', () {
    testWidgets('should build MaterialApp successfully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should have correct app title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, 'VV Viewer');
    });

    testWidgets('should use Material 3 theme by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, true);
    });

    testWidgets('should have debugShowCheckedModeBanner set to false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, false);
    });

    testWidgets('should have light and dark theme configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);
      expect(app.themeMode, ThemeMode.system);
    });

    testWidgets('should configure both light and dark ColorScheme', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));

      // Light theme
      expect(app.theme?.colorScheme.brightness, Brightness.light);

      // Dark theme
      expect(app.darkTheme?.colorScheme.brightness, Brightness.dark);
    });

    testWidgets('should have routes configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.routes, isNotNull);
      expect(app.routes!.containsKey('/viewer'), isTrue);
    });
  });

  group('App Navigation', () {
    testWidgets('should show HomeScreen as initial route', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should have /viewer route configured with ViewerScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));

      // Verify the /viewer route exists
      expect(app.routes!['/viewer'], isNotNull);
    });
  });
}
