import 'package:flutter_test/flutter_test.dart';
import 'package:vv_viewer/parsers/vv_parser.dart';
import 'package:vv_viewer/models/vv_connection.dart';
import 'package:vv_viewer/models/connection_type.dart';

void main() {
  group('VVParser', () {
    test('should parse basic SPICE connection', () {
      const content = '''
[virt-viewer]
type=spice
host=192.168.1.100
port=5900
''';

      final result = VVParser.parse(content);

      expect(result.type, ConnectionType.spice);
      expect(result.host, '192.168.1.100');
      expect(result.port, 5900);
      expect(result.isValid, true);
    });

    test('should parse complete connection with all fields', () {
      const content = '''
[virt-viewer]
type=spice
host=10.0.0.50
port=3001
tls-port=3002
password=MySecret123
proxy=http://proxy:8080
title=Test VM
fullscreen=1
enable-usbredir=1
enable-smartcard=0
enable-audio=1
delete-this-file=0
''';

      final result = VVParser.parse(content);

      expect(result.type, ConnectionType.spice);
      expect(result.host, '10.0.0.50');
      expect(result.port, 3001);
      expect(result.tlsPort, 3002);
      expect(result.password, 'MySecret123');
      expect(result.proxy, 'http://proxy:8080');
      expect(result.title, 'Test VM');
      expect(result.fullscreen, true);
      expect(result.enableUsbredir, true);
      expect(result.enableSmartcard, false);
      expect(result.enableAudio, true);
      expect(result.deleteThisFile, false);
    });

    test('should default to spice when type is missing', () {
      const content = '''
[virt-viewer]
host=192.168.1.100
port=5900
''';

      final result = VVParser.parse(content);

      expect(result.type, ConnectionType.spice);
    });

    test('should parse VNC connection type', () {
      const content = '''
[virt-viewer]
type=vnc
host=192.168.1.100
port=5900
''';

      final result = VVParser.parse(content);

      expect(result.type, ConnectionType.vnc);
    });

    test('should handle alternative key formats (underscore)', () {
      const content = '''
[virt-viewer]
type=spice
host=192.168.1.100
tls_port=3002
enable_usbredir=1
enable_smartcard=1
enable_audio=1
delete_this_file=1
''';

      final result = VVParser.parse(content);

      expect(result.tlsPort, 3002);
      expect(result.enableUsbredir, true);
      expect(result.enableSmartcard, true);
      expect(result.enableAudio, true);
      expect(result.deleteThisFile, true);
    });

    test('should handle boolean values as 0/1 and true/false', () {
      const content1 = '''
[virt-viewer]
type=spice
host=192.168.1.100
fullscreen=1
''';

      const content2 = '''
[virt-viewer]
type=spice
host=192.168.1.100
fullscreen=true
''';

      const content3 = '''
[virt-viewer]
type=spice
host=192.168.1.100
fullscreen=0
''';

      const content4 = '''
[virt-viewer]
type=spice
host=192.168.1.100
fullscreen=false
''';

      final result1 = VVParser.parse(content1);
      final result2 = VVParser.parse(content2);
      final result3 = VVParser.parse(content3);
      final result4 = VVParser.parse(content4);

      expect(result1.fullscreen, true);
      expect(result2.fullscreen, true);
      expect(result3.fullscreen, false);
      expect(result4.fullscreen, false);
    });

    test('should mark connection as invalid when host is missing', () {
      const content = '''
[virt-viewer]
type=spice
port=5900
''';

      final result = VVParser.parse(content);

      expect(result.isValid, false);
    });

    test('should set default port when both port and tls-port are missing', () {
      const content = '''
[virt-viewer]
type=spice
host=192.168.1.100
''';

      final result = VVParser.parse(content);

      expect(result.port, 5900);
      expect(result.isValid, true);
    });

    test('should be valid with only tls-port', () {
      const content = '''
[virt-viewer]
type=spice
host=192.168.1.100
tls-port=3002
''';

      final result = VVParser.parse(content);

      expect(result.isValid, true);
      expect(result.effectivePort, 3002);
    });

    test('should preserve raw content', () {
      const content = '''
[virt-viewer]
type=spice
host=192.168.1.100
port=5900
''';

      final result = VVParser.parse(content);

      expect(result.rawContent, content);
    });

    test('should ignore comments and empty lines', () {
      const content = '''
# This is a comment

[virt-viewer]
type=spice

host=192.168.1.100

# Another comment
port=5900

''';

      final result = VVParser.parse(content);

      expect(result.type, ConnectionType.spice);
      expect(result.host, '192.168.1.100');
      expect(result.port, 5900);
    });

    test('should parse even without [virt-viewer] section header', () {
      const content = '''
type=spice
host=192.168.1.100
port=5900
''';

      final result = VVParser.parse(content);

      expect(result.type, ConnectionType.spice);
      expect(result.host, '192.168.1.100');
      expect(result.port, 5900);
    });

    test('should use default port for unknown type when no port specified', () {
      const content = '''
[virt-viewer]
type=unknown_type
host=192.168.1.100
''';

      final result = VVParser.parse(content);

      expect(result.type, ConnectionType.unknown);
      expect(result.host, '192.168.1.100');
      expect(result.port, 5900); // default port
      expect(result.isValid, true);
    });
  });

  group('VVParser - generate', () {
    test('should generate valid .vv file content', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
        tlsPort: 5901,
        password: 'secret',
        title: 'My VM',
        fullscreen: true,
        enableUsbredir: true,
        enableSmartcard: false,
        enableAudio: true,
      );

      final result = VVParser.generate(connection);

      expect(result, contains('[virt-viewer]'));
      expect(result, contains('type=spice'));
      expect(result, contains('host=192.168.1.100'));
      expect(result, contains('port=5900'));
      expect(result, contains('tls-port=5901'));
      expect(result, contains('password=secret'));
      expect(result, contains('title=My VM'));
      expect(result, contains('fullscreen=1'));
      expect(result, contains('enable-usbredir=1'));
      expect(result, contains('enable-smartcard=0'));
      expect(result, contains('enable-audio=1'));
    });

    test('should generate minimal .vv file with only required fields', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
      );

      final result = VVParser.generate(connection);

      expect(result, contains('[virt-viewer]'));
      expect(result, contains('type=spice'));
      expect(result, contains('host=192.168.1.100'));
      expect(result, contains('port=5900'));
      expect(result, contains('fullscreen=0'));
    });

    test('should generate .vv file with proxy', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
        proxy: 'http://proxy:8080',
      );

      final result = VVParser.generate(connection);

      expect(result, contains('proxy=http://proxy:8080'));
    });

    test('should generate .vv file with delete-this-file', () {
      final connection = const VVConnection(
        type: ConnectionType.spice,
        host: '192.168.1.100',
        port: 5900,
        deleteThisFile: true,
      );

      final result = VVParser.generate(connection);

      expect(result, contains('delete-this-file=1'));
    });
  });

  group('VVParser error handling', () {
    test('should throw ArgumentError when content is empty', () {
      const content = '';

      expect(() => VVParser.parse(content), throwsArgumentError);
    });
  });
}
