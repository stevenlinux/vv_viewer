import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'dart:io';
import 'services/spice_launcher_service.dart';
import 'services/file_opened_observer.dart';
import 'services/app_logger.dart';
import 'screens/home_screen.dart';
import 'screens/viewer_screen.dart';
import 'parsers/vv_parser.dart';
import 'models/vv_connection.dart';
import 'models/connection_type.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局错误捕获
  // TODO: 集成 Sentry (需升级 Kotlin 到 2.1+)
  runZonedGuarded<Future<void>>(
    () async {
      AppLogger.info(LogTags.main, 'App starting...');
      FileOpenedObserver.initialize();
      runApp(const ProviderScope(child: MyApp()));
    },
    (e, st) {
      AppLogger.error(LogTags.main, 'Uncaught error', e, st);
    },
  );
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialConnection = useState<VVConnection?>(null);
    final initialFilePath = useState<String?>(null);
    final isHandlingLink = useState(false);

    useEffect(() {
      _handleIncomingLinks(initialConnection, initialFilePath, isHandlingLink);
      return null;
    }, []);

    return MaterialApp(
      title: 'VV Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: _buildHome(initialConnection.value, initialFilePath.value),
      routes: {
        '/viewer': (context) => ViewerScreen(
          connection: initialConnection.value ?? _createDefaultConnection(),
          filePath: initialFilePath.value,
        ),
      },
    );
  }

  Widget _buildHome(VVConnection? connection, String? filePath) {
    if (connection != null) {
      // 如果有连接，跳转到查看器
      return ViewerScreen(connection: connection, filePath: filePath);
    }
    return const HomeScreen();
  }

  VVConnection _createDefaultConnection() {
    return const VVConnection(
      type: ConnectionType.spice,
      host: 'localhost',
      port: 5900,
    );
  }

  Future<void> _handleIncomingLinks(
    ValueNotifier<VVConnection?> connection,
    ValueNotifier<String?> filePath,
    ValueNotifier<bool> isHandling,
  ) async {
    if (isHandling.value) return;
    isHandling.value = true;

    try {
      AppLogger.debug(LogTags.main, 'Setting up incoming link handlers');

      // Listen for file open events from Android native layer
      FileOpenedObserver.onFileOpened = (uriString) async {
        AppLogger.debug(LogTags.main, 'File opened via native: $uriString');
        final uri = Uri.parse(uriString);
        await _handleUri(uri, connection, filePath);
      };

      final appLinks = AppLinks();

      // Handle initial link
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        AppLogger.debug(LogTags.main, 'Initial URI: $initialUri');
        await _handleUri(initialUri, connection, filePath);
      }

      // Listen for subsequent links
      appLinks.uriLinkStream.listen((uri) async {
        AppLogger.debug(LogTags.main, 'Incoming URI stream: $uri');
        await _handleUri(uri, connection, filePath);
      });
    } catch (e) {
      AppLogger.warn(LogTags.main, 'Error setting up link handlers: $e');
    } finally {
      isHandling.value = false;
    }
  }

  Future<void> _handleUri(Uri uri, ValueNotifier<VVConnection?> connection, ValueNotifier<String?> filePath) async {
    try {
      AppLogger.debug(LogTags.main, '_handleUri: scheme=${uri.scheme}, path=${uri.path}');

      // content:// URIs cannot use toFilePath(), use resolveContentUri directly
      if (uri.scheme == 'content') {
        final realPath = await SpiceLauncherService.resolveContentUri(uri.toString());
        if (realPath != null) {
          AppLogger.debug(LogTags.main, 'Resolved content URI to: $realPath');
          final content = await File(realPath).readAsString();
          final parsed = VVParser.parse(content);
          if (parsed.isValid) {
            AppLogger.info(LogTags.main, 'Valid connection parsed: ${parsed.displayTitle}');
            connection.value = parsed;
            filePath.value = realPath;
          } else {
            AppLogger.warn(LogTags.main, 'Parsed connection is invalid');
          }
        }
        return;
      }

      // file:// URI
      final filePathStr = uri.toFilePath();
      final file = File(filePathStr);
      if (await file.exists()) {
        final content = await file.readAsString();
        final parsed = VVParser.parse(content);
        if (parsed.isValid) {
          AppLogger.info(LogTags.main, 'Valid file connection: ${parsed.displayTitle}');
          connection.value = parsed;
          filePath.value = filePathStr;
        } else {
          AppLogger.warn(LogTags.main, 'Parsed file connection is invalid');
        }
      } else {
        AppLogger.warn(LogTags.main, 'File does not exist: $filePathStr');
      }
    } catch (e, st) {
      AppLogger.error(LogTags.main, 'Error handling URI', e, st);
    }
  }
}
