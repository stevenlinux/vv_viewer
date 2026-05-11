import 'package:flutter_test/flutter_test.dart';
import 'package:vv_viewer/models/connection_type.dart';

void main() {
  group('ConnectionType', () {
    group('fromString', () {
      test('should return spice for "spice"', () {
        final result = ConnectionType.fromString('spice');
        expect(result, ConnectionType.spice);
      });

      test('should return spice for "SPICE" (uppercase)', () {
        final result = ConnectionType.fromString('SPICE');
        expect(result, ConnectionType.spice);
      });

      test('should return spice for "Spice" (mixed case)', () {
        final result = ConnectionType.fromString('Spice');
        expect(result, ConnectionType.spice);
      });

      test('should return vnc for "vnc"', () {
        final result = ConnectionType.fromString('vnc');
        expect(result, ConnectionType.vnc);
      });

      test('should return vnc for "VNC" (uppercase)', () {
        final result = ConnectionType.fromString('VNC');
        expect(result, ConnectionType.vnc);
      });

      test('should return unknown for null', () {
        final result = ConnectionType.fromString(null);
        expect(result, ConnectionType.unknown);
      });

      test('should return unknown for empty string', () {
        final result = ConnectionType.fromString('');
        expect(result, ConnectionType.unknown);
      });

      test('should return unknown for invalid type', () {
        final result = ConnectionType.fromString('rdp');
        expect(result, ConnectionType.unknown);
      });

      test('should return unknown for whitespace string', () {
        final result = ConnectionType.fromString('   ');
        expect(result, ConnectionType.unknown);
      });
    });

    group('displayName', () {
      test('should return "SPICE" for spice type', () {
        expect(ConnectionType.spice.displayName, 'SPICE');
      });

      test('should return "VNC" for vnc type', () {
        expect(ConnectionType.vnc.displayName, 'VNC');
      });

      test('should return "Unknown" for unknown type', () {
        expect(ConnectionType.unknown.displayName, 'Unknown');
      });
    });

    group('enum values', () {
      test('should have three enum values', () {
        final values = ConnectionType.values;
        expect(values.length, 3);
        expect(values, contains(ConnectionType.spice));
        expect(values, contains(ConnectionType.vnc));
        expect(values, contains(ConnectionType.unknown));
      });

      test('should have correct index order', () {
        expect(ConnectionType.spice.index, 0);
        expect(ConnectionType.vnc.index, 1);
        expect(ConnectionType.unknown.index, 2);
      });
    });
  });
}
