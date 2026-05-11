import 'package:flutter_test/flutter_test.dart';
import 'package:vv_viewer/models/vv_connection.dart';
import 'package:vv_viewer/models/connection_type.dart';

void main() {
  group('VVConnection', () {
    test('should create valid connection with required fields', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      expect(connection.type, ConnectionType.spice);
      expect(connection.host, '192.168.1.100');
      expect(connection.port, 5900);
      expect(connection.isValid, true);
    });

    test('should be invalid without host', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        port: 5900,
      );

      expect(connection.isValid, false);
    });

    test('should be invalid without port and tlsPort', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
      );

      expect(connection.isValid, false);
    });

    test('should be valid with only tlsPort', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        tlsPort: 3002,
      );

      expect(connection.isValid, true);
      expect(connection.effectivePort, 3002);
    });

    test('should prefer tlsPort for effectivePort', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 3001,
        tlsPort: 3002,
      );

      expect(connection.effectivePort, 3002);
    });

    test('should use port when tlsPort is null for effectivePort', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 3001,
      );

      expect(connection.effectivePort, 3001);
    });

    test('should return title as displayTitle when available', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
        title: 'My Virtual Machine',
      );

      expect(connection.displayTitle, 'My Virtual Machine');
    });

    test('should return host:port as displayTitle when title is null', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      expect(connection.displayTitle, '192.168.1.100:5900');
    });

    test('should return only host as displayTitle when port is null but tlsPort exists', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        tlsPort: 3002,
      );

      expect(connection.displayTitle, '192.168.1.100:3002');
    });

    test('should return unknown as displayTitle when host is null', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        port: 5900,
      );

      expect(connection.displayTitle, 'Unknown Connection');
    });

    test('should create copy with updated fields', () {
      final original = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
        title: 'Old Title',
      );

      final updated = original.copyWith(
        title: 'New Title',
        port: 5901,
      );

      expect(updated.type, ConnectionType.spice);
      expect(updated.host, '192.168.1.100');
      expect(updated.port, 5901);
      expect(updated.title, 'New Title');
    });

    test('should equate connections with same properties', () {
      final connection1 = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      final connection2 = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      expect(connection1, connection2);
    });

    test('should not equate connections with different properties', () {
      final connection1 = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      final connection2 = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.101',
        port: 5900,
      );

      expect(connection1, isNot(connection2));
    });

    test('should have correct props for equality', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
        tlsPort: 3002,
        password: 'secret',
        proxy: 'http://proxy',
        title: 'Test',
        fullscreen: true,
        enableUsbredir: true,
        enableSmartcard: false,
        enableAudio: true,
        deleteThisFile: false,
      );

      final props = connection.props;

      expect(props, contains(ConnectionType.spice));
      expect(props, contains('192.168.1.100'));
      expect(props, contains(5900));
      expect(props, contains(3002));
      expect(props, contains('secret'));
      expect(props, contains('http://proxy'));
      expect(props, contains('Test'));
      expect(props, contains(true));
    });

    test('should serialize to JSON map', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
        tlsPort: 5901,
        password: 'secret',
        title: 'Test VM',
        fullscreen: true,
        enableUsbredir: true,
        enableSmartcard: false,
        enableAudio: true,
      );

      final json = connection.toJson();

      expect(json['type'], 'spice');
      expect(json['host'], '192.168.1.100');
      expect(json['port'], 5900);
      expect(json['tlsPort'], 5901);
      expect(json['password'], 'secret');
      expect(json['title'], 'Test VM');
      expect(json['fullscreen'], true);
      expect(json['enableUsbredir'], true);
      expect(json['enableSmartcard'], false);
      expect(json['enableAudio'], true);
    });

    test('should deserialize from JSON map', () {
      final json = {
        'type': 'spice',
        'host': '192.168.1.100',
        'port': 5900,
        'tlsPort': 5901,
        'password': 'secret',
        'title': 'Test VM',
        'fullscreen': true,
        'enableUsbredir': true,
        'enableSmartcard': false,
        'enableAudio': true,
      };

      final connection = VVConnection.fromJson(json);

      expect(connection.type, ConnectionType.spice);
      expect(connection.host, '192.168.1.100');
      expect(connection.port, 5900);
      expect(connection.tlsPort, 5901);
      expect(connection.password, 'secret');
      expect(connection.title, 'Test VM');
      expect(connection.fullscreen, true);
      expect(connection.enableUsbredir, true);
      expect(connection.enableSmartcard, false);
      expect(connection.enableAudio, true);
    });

    test('should handle unknown type in fromJson', () {
      final json = {
        'type': 'unknown_type',
        'host': '192.168.1.100',
        'port': 5900,
      };

      final connection = VVConnection.fromJson(json);
      expect(connection.type, ConnectionType.unknown);
    });

    test('should serialize and deserialize correctly', () {
      final original = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
        tlsPort: 5901,
        password: 'secret',
        title: 'Test VM',
        fullscreen: true,
        enableUsbredir: true,
        enableSmartcard: false,
        enableAudio: true,
      );

      final json = original.toJson();
      final restored = VVConnection.fromJson(json);

      expect(restored.type, original.type);
      expect(restored.host, original.host);
      expect(restored.port, original.port);
      expect(restored.tlsPort, original.tlsPort);
      expect(restored.password, original.password);
      expect(restored.title, original.title);
      expect(restored.fullscreen, original.fullscreen);
      expect(restored.enableUsbredir, original.enableUsbredir);
      expect(restored.enableSmartcard, original.enableSmartcard);
      expect(restored.enableAudio, original.enableAudio);
    });

    test('should serialize to JSON string and back', () {
      final original = const VVConnection(
        type: ConnectionType.vnc,
        host: '192.168.1.100',
        port: 5900,
        title: 'VNC VM',
      );

      final jsonString = original.toJsonString();
      final restored = VVConnection.fromJsonString(jsonString);

      expect(restored.type, original.type);
      expect(restored.host, original.host);
      expect(restored.port, original.port);
    });

    test('should return host with port as displayTitle when title is null', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      expect(connection.displayTitle, '192.168.1.100:5900');
    });

    test('should return title as displayTitle when title is set', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
        title: 'My VM',
      );

      expect(connection.displayTitle, 'My VM');
    });

    test('should deserialize from JSON with lastUsed date', () {
      final json = {
        'type': 'spice',
        'host': '192.168.1.100',
        'port': 5900,
        'lastUsed': '2024-06-15T10:30:00.000',
      };

      final connection = VVConnection.fromJson(json);

      expect(connection.type, ConnectionType.spice);
      expect(connection.host, '192.168.1.100');
      expect(connection.port, 5900);
      expect(connection.lastUsed, isNotNull);
      expect(connection.lastUsed!.year, 2024);
      expect(connection.lastUsed!.month, 6);
      expect(connection.lastUsed!.day, 15);
    });
  });
}
