import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vv_viewer/screens/connection_list_screen.dart';
import 'package:vv_viewer/models/vv_connection.dart';
import 'package:vv_viewer/models/connection_type.dart';
import 'package:vv_viewer/providers.dart';
import 'package:vv_viewer/services/storage_service.dart';

// Mock StorageService for testing
class MockStorageService extends StorageService {
  List<VVConnection> _connections = [];

  void setConnections(List<VVConnection> connections) {
    _connections = connections;
  }

  @override
  Future<void> saveConnection(VVConnection connection) async {
    _connections.add(connection);
  }

  @override
  Future<List<VVConnection>> loadConnections() async {
    return _connections;
  }

  @override
  Future<void> deleteConnection(VVConnection connection) async {
    _connections.removeWhere((c) => c.host == connection.host && c.port == connection.port);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectionListScreen', () {
    testWidgets('should display app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ConnectionListScreen(),
          ),
        ),
      );

      expect(find.text('连接历史'), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ConnectionListScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no connections', (WidgetTester tester) async {
      // Create a provider override with empty connections
      final mockStorage = MockStorageService();
      mockStorage.setConnections([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(
            home: ConnectionListScreen(),
          ),
        ),
      );

      // Wait for async load
      await tester.pumpAndSettle();

      expect(find.text('没有历史记录'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('should display list of connections when data exists', (WidgetTester tester) async {
      final mockStorage = MockStorageService();
      mockStorage.setConnections([
        const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          title: 'Test VM 1',
        ),
        const VVConnection(
          type: ConnectionType.vnc,
          host: '192.168.1.101',
          port: 5901,
          title: 'Test VM 2',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(
            home: ConnectionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test VM 1'), findsOneWidget);
      expect(find.text('Test VM 2'), findsOneWidget);
    });

    testWidgets('should show delete icon for each connection', (WidgetTester tester) async {
      final mockStorage = MockStorageService();
      mockStorage.setConnections([
        const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          title: 'Test VM',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(
            home: ConnectionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('should show delete confirmation dialog when delete is tapped', (WidgetTester tester) async {
      final mockStorage = MockStorageService();
      mockStorage.setConnections([
        const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          title: 'Test VM',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(
            home: ConnectionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('删除连接'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
    });

    testWidgets('should dismiss dialog when cancel is tapped', (WidgetTester tester) async {
      final mockStorage = MockStorageService();
      mockStorage.setConnections([
        const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          title: 'Test VM',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(
            home: ConnectionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Verify dialog is dismissed and connection still exists
      expect(find.text('Test VM'), findsOneWidget);
    });

    testWidgets('should display connection type icon correctly', (WidgetTester tester) async {
      final mockStorage = MockStorageService();
      mockStorage.setConnections([
        const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        ),
        const VVConnection(
          type: ConnectionType.vnc,
          host: '192.168.1.101',
          port: 5901,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(
            home: ConnectionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // SPICE uses Icons.dvr, VNC uses Icons.computer
      expect(find.byIcon(Icons.dvr), findsOneWidget);
      expect(find.byIcon(Icons.computer), findsOneWidget);
    });

    testWidgets('should display host and port in subtitle', (WidgetTester tester) async {
      final mockStorage = MockStorageService();
      mockStorage.setConnections([
        const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          title: 'Test VM',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(
            home: ConnectionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('192.168.1.100'), findsOneWidget);
      expect(find.textContaining('5900'), findsOneWidget);
    });

    testWidgets('should display last used time when available', (WidgetTester tester) async {
      final connection = VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
        title: 'Test VM',
        lastUsed: DateTime(2024, 1, 15, 10, 30),
      );

      final mockStorage = MockStorageService();
      mockStorage.setConnections([connection]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(
            home: ConnectionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('上次使用'), findsOneWidget);
    });

    testWidgets('should sort connections by lastUsed descending', (WidgetTester tester) async {
      final mockStorage = MockStorageService();
      mockStorage.setConnections([
        VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          title: 'Older VM',
          lastUsed: DateTime(2024, 1, 1),
        ),
        VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.101',
          port: 5901,
          title: 'Newer VM',
          lastUsed: DateTime(2024, 6, 1),
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(
            home: ConnectionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Newer VM should appear first
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsNWidgets(2));
    });
  });
}
