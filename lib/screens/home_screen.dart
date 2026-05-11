import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/vv_connection.dart';
import '../parsers/vv_parser.dart';
import '../providers.dart';
import 'viewer_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _pickFile() async {
    final context = this.context;
    final storage = ref.read(storageServiceProvider);

    try {
      FilePickerResult? result;
      try {
        // 先尝试使用 custom 类型
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['vv'],
          withData: true,
        );
      } catch (e) {
        // 如果 custom 类型失败，回退到 any 类型
        try {
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            withData: true,
          );
        } catch (e2) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('选择文件时出错: $e2')),
            );
          }
          return;
        }
      }

      if (result == null) {
        return;
      }

      if (result.files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未选择文件')),
          );
        }
        return;
      }

      final file = result.files.first;

      // 验证文件扩展名 - 支持 .vv 以及 .vv (1) 这种格式
      final fileName = file.name.toLowerCase();
      if (!fileName.contains('.vv')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请选择 .vv 格式的文件')),
          );
        }
        return;
      }

      // file.path 是文件系统路径，可以传递给 ViewerScreen 用于内嵌 SPICE
      final filePath = file.path;
      late VVConnection connection;

      if (file.bytes != null) {
        // 有文件内容（内存读取），直接解析
        final content = String.fromCharCodes(file.bytes!);
        try {
          connection = VVParser.parse(content);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('解析文件失败: $e')),
            );
          }
          return;
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法读取文件内容')),
          );
        }
        return;
      }

      if (context.mounted) {
        await storage.saveConnection(connection);

        if (connection.isValid) {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewerScreen(
                  connection: connection,
                  filePath: filePath,
                ),
              ),
            );
          }
        } else {
          if (context.mounted) {
            final missingParts = <String>[];
            if (connection.host == null || connection.host!.isEmpty) {
              missingParts.add('host');
            }
            if (connection.port == null && connection.tlsPort == null) {
              missingParts.add('port/tls-port');
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('连接信息不完整，缺少: ${missingParts.join(', ')}'),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VV Viewer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dvr,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'VV Viewer',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮打开 .vv 文件',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickFile,
        icon: const Icon(Icons.file_open),
        label: const Text('打开 .vv 文件'),
      ),
    );
  }
}
