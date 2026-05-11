import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/connection_type.dart';
import '../models/vv_connection.dart';
import '../providers.dart';
import 'viewer_screen.dart';

class ConnectionListScreen extends HookConsumerWidget {
  const ConnectionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = useMemoized(() => ref.read(storageServiceProvider));
    final connections = useState<List<VVConnection>>([]);
    final isLoading = useState(true);

    Future<void> loadConnections() async {
      final list = await storage.loadConnections();
      list.sort((a, b) {
        final aTime = a.lastUsed;
        final bTime = b.lastUsed;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      connections.value = list;
      isLoading.value = false;
    }

    useEffect(() {
      Future.microtask(loadConnections);
      return null;
    }, []);

    void openConnection(VVConnection connection) async {
      await storage.saveConnection(connection);
      if (context.mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewerScreen(connection: connection),
          ),
        );
        if (result == true) {
          loadConnections();
        }
      }
    }

    void deleteConnection(VVConnection connection) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('删除连接'),
          content: Text('确定要删除 "${connection.displayTitle}" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await storage.deleteConnection(connection);
        loadConnections();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('连接历史'),
      ),
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : connections.value.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '没有历史记录',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: connections.value.length,
                  itemBuilder: (context, index) {
                    final connection = connections.value[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          connection.type == ConnectionType.vnc
                              ? Icons.computer
                              : Icons.dvr,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(connection.displayTitle),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${connection.type.displayName} • ${connection.host}:${connection.port}',
                            ),
                            if (connection.lastUsed != null)
                              Text(
                                '上次使用: ${_formatDateTime(connection.lastUsed!)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                          onPressed: () => deleteConnection(connection),
                        ),
                        onTap: () => openConnection(connection),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
