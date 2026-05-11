import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/vv_connection.dart';

/// PVE 控制台页面
/// 使用 WebView 加载 PVE 的 HTML5 控制台 (noVNC)
class ConsoleScreen extends StatefulWidget {
  final VVConnection connection;

  const ConsoleScreen({super.key, required this.connection});

  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _isLoading = progress < 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = error.description;
            });
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.connection.title ?? 'PVE 控制台'),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: _zoomOut,
            tooltip: '缩小',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: _zoomIn,
            tooltip: '放大',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
            tooltip: '刷新',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clipboard':
                  _showClipboardDialog();
                  break;
                case 'fullscreen':
                  _toggleFullscreen();
                  break;
                case 'keyboard':
                  _showKeyboard();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clipboard',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('剪贴板'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'fullscreen',
                child: ListTile(
                  leading: Icon(Icons.fullscreen),
                  title: Text('全屏'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'keyboard',
                child: ListTile(
                  leading: Icon(Icons.keyboard),
                  title: Text('虚拟键盘'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Container(
              color: Colors.red[100],
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildConsoleView(),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleView() {
    // 构建 PVE 控制台 URL
    // PVE 的 HTML5 控制台通过 WebSocket 连接
    final consoleUrl = _buildConsoleUrl();

    if (consoleUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.computer, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '请提供 PVE 控制台 URL',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              '格式: https://your-pve-host:8006/?console=...',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showUrlInputDialog,
              icon: const Icon(Icons.link),
              label: const Text('输入 URL'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  /// 构建 PVE 控制台 URL
  /// PVE 使用 websockify 来代理 VNC/SPICE 连接
  String _buildConsoleUrl() {
    final host = widget.connection.host;
    final isTls = widget.connection.tlsPort != null;

    if (host == null) {
      return '';
    }

    // 构建 PVE HTML5 控制台 URL
    // PVE 6.x/7.x/8.x 都支持通过 /?console=... 访问 HTML5 控制台
    final scheme = isTls ? 'https' : 'https';
    final proxyPort = isTls ? (widget.connection.tlsPort ?? 8006) : 8006;

    // PVE HTML5 控制台基于 noVNC
    // 需要通过 PVE 的 API 获取 ticket 和 console URL
    return '$scheme://$host:$proxyPort/';

    // 实际使用时，PVE 会自动重定向到 websockify URL
    // 格式类似: /?console=firefox&novnc=1&vmname=vm-100
  }

  void _zoomIn() {
    // WebView 不支持直接缩放，提示用户使用系统缩放
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请使用系统缩放功能')),
    );
  }

  void _zoomOut() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请使用系统缩放功能')),
    );
  }

  void _reload() {
    _controller.reload();
  }

  void _toggleFullscreen() {
    // 切换全屏模式
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  void _showKeyboard() {
    // 显示虚拟键盘提示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('键盘快捷键'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ctrl+Alt+Del - 发送 Ctrl+Alt+Delete'),
            Text('Ctrl+Alt+Backspace - 发送 Ctrl+Alt+Backspace'),
            Text('Ctrl+Alt+F - 全屏切换'),
            Text('F11 - 全屏切换'),
            Text('Ctrl+Plus - 放大'),
            Text('Ctrl+Minus - 缩小'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showClipboardDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('剪贴板'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '输入要发送到远程桌面的文本',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 通过 JavaScript 发送到 noVNC 剪贴板
              _controller.runJavaScript(
                'if (RFB && RFB.clipboard) { RFB.clipboard.text = "${controller.text}"; }'
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已发送到剪贴板')),
              );
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  void _showUrlInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入 PVE URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://your-pve-host:8006',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _controller.loadRequest(Uri.parse(controller.text));
              }
            },
            child: const Text('加载'),
          ),
        ],
      ),
    );
  }
}
