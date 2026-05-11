import 'package:flutter/material.dart';
import '../models/vv_connection.dart';
import '../models/spice_launch_result.dart';
import '../services/spice_launcher_service.dart';

/// 内嵌 SPICE 连接屏幕
/// 注意：当前版本通过启动内置的 aSPICE Activity 来实现
/// 未来版本可以实现真正的 PlatformView 嵌入
class EmbeddedSpiceScreen extends StatefulWidget {
  final VVConnection connection;
  final String? filePath;

  const EmbeddedSpiceScreen({
    super.key,
    required this.connection,
    this.filePath,
  });

  @override
  State<EmbeddedSpiceScreen> createState() => _EmbeddedSpiceScreenState();
}

class _EmbeddedSpiceScreenState extends State<EmbeddedSpiceScreen> {
  bool _isLaunching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _launchEmbeddedSpice();
  }

  Future<void> _launchEmbeddedSpice() async {
    if (_isLaunching) return;

    setState(() {
      _isLaunching = true;
      _errorMessage = null;
    });

    try {
      SpiceLaunchResult result;

      // DEBUG: 确认 filePath 是否传递
      debugPrint('EmbeddedSpiceScreen: filePath=${widget.filePath}, host=${widget.connection.host}');

      if (widget.filePath != null) {
        debugPrint('Calling launchEmbeddedSpiceWithFile: ${widget.filePath}');
        result = await SpiceLauncherService.launchEmbeddedSpiceWithFile(
          widget.filePath!,
        );
      } else {
        debugPrint('Calling launchEmbeddedSpice (no filePath)');
        result = await SpiceLauncherService.launchEmbeddedSpice(
          connection: widget.connection,
        );
      }

      if (!mounted) return;

      if (result.success) {
        // 成功启动后，关闭当前屏幕（因为 aSPICE Activity 已经在前台）
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = result.message ?? '启动失败';
          _isLaunching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLaunching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.connection.displayTitle),
      ),
      body: Center(
        child: _isLaunching
            ? _buildLoadingIndicator()
            : _buildErrorView(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          '正在启动内嵌 SPICE...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          widget.connection.displayTitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            '启动内嵌 SPICE 失败',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[800]),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _launchEmbeddedSpice,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}
