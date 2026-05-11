import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vv_viewer/services/storage_service.dart';
import 'package:vv_viewer/models/vv_connection.dart';
import 'package:vv_viewer/models/connection_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService', () {
    late StorageService storageService;
    late SharedPreferences prefs;

    setUp(() async {
      storageService = StorageService();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    group('saveConnection', () {
      test('should save new connection to preferences', () async {
        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          title: 'Test VM',
        );

        await storageService.saveConnection(connection);

        final saved = prefs.getStringList('connections');
        expect(saved, isNotNull);
        expect(saved!.length, 1);
        expect(saved[0], contains('192.168.1.100'));
      });

      test('should update existing connection if host and port match', () async {
        SharedPreferences.setMockInitialValues({
          'connections': [
            '{"type":"spice","host":"192.168.1.100","port":5900,"title":"Old Title"}',
          ],
        });
        prefs = await SharedPreferences.getInstance();

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          title: 'New Title',
        );

        await storageService.saveConnection(connection);

        final saved = prefs.getStringList('connections');
        expect(saved!.length, 1);
        expect(saved[0], contains('New Title'));
      });

      test('should add new connection if host or port differs', () async {
        SharedPreferences.setMockInitialValues({
          'connections': [
            '{"type":"spice","host":"192.168.1.100","port":5900}',
          ],
        });
        prefs = await SharedPreferences.getInstance();

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.101',
          port: 5900,
        );

        await storageService.saveConnection(connection);

        final saved = prefs.getStringList('connections');
        expect(saved!.length, 2);
      });

      test('should update last_connection when saving', () async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();

        final connection = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await storageService.saveConnection(connection);

        final lastConnection = prefs.getString('last_connection');
        expect(lastConnection, isNotNull);
        expect(lastConnection, contains('192.168.1.100'));
      });
    });

    group('loadConnections', () {
      test('should return empty list when no connections saved', () async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();

        final result = await storageService.loadConnections();

        expect(result, isEmpty);
      });

      test('should load saved connections', () async {
        SharedPreferences.setMockInitialValues({
          'connections': [
            '{"type":"spice","host":"192.168.1.100","port":5900}',
            '{"type":"vnc","host":"192.168.1.101","port":5901}',
          ],
        });
        prefs = await SharedPreferences.getInstance();

        final result = await storageService.loadConnections();

        expect(result.length, 2);
        expect(result[0].host, '192.168.1.100');
        expect(result[1].type, ConnectionType.vnc);
      });
    });

    group('loadLastConnection', () {
      test('should return null when no last connection saved', () async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();

        final result = await storageService.loadLastConnection();

        expect(result, isNull);
      });

      test('should return last saved connection', () async {
        SharedPreferences.setMockInitialValues({
          'last_connection': '{"type":"spice","host":"192.168.1.100","port":5900}',
        });
        prefs = await SharedPreferences.getInstance();

        final result = await storageService.loadLastConnection();

        expect(result, isNotNull);
        expect(result!.host, '192.168.1.100');
      });
    });

    group('deleteConnection', () {
      test('should remove connection by host and port', () async {
        SharedPreferences.setMockInitialValues({
          'connections': [
            '{"type":"spice","host":"192.168.1.100","port":5900}',
            '{"type":"spice","host":"192.168.1.101","port":5901}',
          ],
        });
        prefs = await SharedPreferences.getInstance();

        final connectionToDelete = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
        );

        await storageService.deleteConnection(connectionToDelete);

        final saved = prefs.getStringList('connections');
        expect(saved!.length, 1);
        expect(saved[0], contains('192.168.1.101'));
      });

      test('should remove connection by rawContent match', () async {
        SharedPreferences.setMockInitialValues({
          'connections': [
            '{"type":"spice","host":"192.168.1.100","port":5900,"rawContent":"abc123"}',
            '{"type":"spice","host":"192.168.1.101","port":5901,"rawContent":"def456"}',
          ],
        });
        prefs = await SharedPreferences.getInstance();

        final connectionToDelete = const VVConnection(
          type: ConnectionType.spice,
          host: '192.168.1.100',
          port: 5900,
          rawContent: 'abc123',
        );

        await storageService.deleteConnection(connectionToDelete);

        final saved = prefs.getStringList('connections');
        expect(saved!.length, 1);
        expect(saved[0], contains('192.168.1.101'));
      });
    });
  });
}