import 'package:shared_preferences/shared_preferences.dart';
import '../models/vv_connection.dart';

class StorageService {
  static const String _connectionsKey = 'connections';
  static const String _lastConnectionKey = 'last_connection';

  Future<void> saveConnection(VVConnection connection) async {
    final prefs = await SharedPreferences.getInstance();
    final connections = await loadConnections();

    final updatedConnection = connection.copyWith(lastUsed: DateTime.now());

    final index = connections.indexWhere((c) =>
      c.host == updatedConnection.host &&
      c.port == updatedConnection.port &&
      c.tlsPort == updatedConnection.tlsPort
    );

    if (index >= 0) {
      connections[index] = updatedConnection;
    } else {
      connections.add(updatedConnection);
    }

    final encoded = connections.map((c) => _connectionToJson(c)).toList();
    await prefs.setStringList(_connectionsKey, encoded);
    await prefs.setString(_lastConnectionKey, _connectionToJson(updatedConnection));
  }

  Future<List<VVConnection>> loadConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedList = prefs.getStringList(_connectionsKey) ?? [];
    return encodedList.map((e) => _connectionFromJson(e)).toList();
  }

  Future<VVConnection?> loadLastConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_lastConnectionKey);
    if (encoded == null) return null;
    return _connectionFromJson(encoded);
  }

  Future<void> deleteConnection(VVConnection connection) async {
    final prefs = await SharedPreferences.getInstance();
    final connections = await loadConnections();

    // 更宽松的匹配逻辑：如果host和port都匹配，或者rawContent相同就删除
    connections.removeWhere((c) {
      final hostPortMatch = c.host == connection.host &&
          c.port == connection.port &&
          c.tlsPort == connection.tlsPort;
      final rawContentMatch = c.rawContent != null &&
          connection.rawContent != null &&
          c.rawContent == connection.rawContent;
      return hostPortMatch || rawContentMatch;
    });

    final encoded = connections.map((c) => _connectionToJson(c)).toList();
    await prefs.setStringList(_connectionsKey, encoded);
  }

  String _connectionToJson(VVConnection connection) {
    return connection.toJsonString();
  }

  VVConnection _connectionFromJson(String json) {
    return VVConnection.fromJsonString(json);
  }
}
