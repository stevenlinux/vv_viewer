import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../models/vv_connection.dart';

/// PVE Web Console 连接页面
/// 通过 PVE REST API 获取控制台 URL，然后在 WebView 中显示
class PveConsoleScreen extends StatefulWidget {
  final VVConnection? connection;

  const PveConsoleScreen({super.key, this.connection});

  @override
  State<PveConsoleScreen> createState() => _PveConsoleScreenState();
}

class _PveConsoleScreenState extends State<PveConsoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '8006');
  final _userController = TextEditingController(text: 'root');
  final _passwordController = TextEditingController();
  final _vmIdController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  WebViewController? _webViewController;
  bool _useTls = true;

  // PVE API 基础 URL
  String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    // 如果有 .vv 文件中的主机信息，填充表单
    if (widget.connection != null) {
      _hostController.text = widget.connection!.host ?? '';
      _portController.text = (widget.connection!.tlsPort ?? widget.connection!.port ?? 8006).toString();
      _useTls = widget.connection!.tlsPort != null;
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _vmIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PVE Web Console'),
      ),
      body: _webViewController != null
          ? _buildWebView()
          : _buildLoginForm(),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.connection != null) ...[
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            '检测到 .vv 文件',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('主机: ${widget.connection!.host}'),
                      Text('端口: ${widget.connection!.effectivePort}'),
                      Text('类型: ${widget.connection!.type.displayName}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              '连接到 Proxmox VE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 主机地址
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'PVE 主机地址',
                hintText: 'pve.example.com 或 192.168.1.100',
                prefixIcon: Icon(Icons.computer),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入 PVE 主机地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 端口
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: '端口',
                      hintText: '8006',
                      prefixIcon: Icon(Icons.settings_ethernet),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Text('TLS'),
                    Switch(
                      value: _useTls,
                      onChanged: (value) {
                        setState(() {
                          _useTls = value;
                          if (value && _portController.text == '8006') {
                            _portController.text = '8006';
                          } else if (!value && _portController.text == '8006') {
                            _portController.text = '80';
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 用户名
            TextFormField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: '用户名',
                hintText: 'root',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入用户名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 密码
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // VM ID (可选)
            TextFormField(
              controller: _vmIdController,
              decoration: const InputDecoration(
                labelText: 'VM ID (可选)',
                hintText: '如果不填，稍后可以选择',
                prefixIcon: Icon(Icons.dns),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            if (_errorMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _connect,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_isLoading ? '连接中...' : '连接'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // 说明
            Card(
              color: Colors.grey[100],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '使用说明',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. 输入您的 Proxmox VE 服务器地址'),
                    Text('2. 输入 PVE 的用户名和密码'),
                    Text('3. (可选) 直接输入 VM ID'),
                    Text('4. 点击连接登录 PVE'),
                    Text('5. 之后可以选择要连接的虚拟机'),
                    SizedBox(height: 8),
                    Text(
                      '注意：此应用使用 PVE 的 Web Console (noVNC) 来显示远程桌面',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return Column(
      children: [
        Container(
          color: Colors.orange[100],
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('已在 PVE 控制台中登录，点击选择虚拟机'),
              ),
              TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('退出'),
              ),
            ],
          ),
        ),
        Expanded(
          child: WebViewWidget(controller: _webViewController!),
        ),
      ],
    );
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final host = _hostController.text.trim();
      final port = int.tryParse(_portController.text) ?? 8006;
      final user = _userController.text.trim();
      final password = _passwordController.text;
      final vmId = _vmIdController.text.trim();

      // 构建 API URL
      _baseUrl = '${_useTls ? "https" : "http"}://$host:$port';

      // 登录 PVE 获取 ticket
      final ticket = await _login(user, password);

      if (ticket == null) {
        setState(() {
          _errorMessage = '登录失败，请检查用户名和密码';
          _isLoading = false;
        });
        return;
      }

      // 创建 WebView 控制器
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black);

      if (vmId.isNotEmpty) {
        // 直接加载指定 VM 的控制台
        final consoleUrl = '$_baseUrl/?console=vm&id=$vmId&novnc=1';
        await _webViewController!.loadRequest(Uri.parse(consoleUrl));
      } else {
        // 加载 PVE 主界面，用户可以选择 VM
        await _webViewController!.loadRequest(Uri.parse(_baseUrl));
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = '连接错误: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _login(String user, String password) async {
    try {
      // PVE API 登录
      final response = await http.post(
        Uri.parse('$_baseUrl/api2/json/access/ticket'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'username=${Uri.encodeComponent(user)}@pam&password=${Uri.encodeComponent(password)}',
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['ticket'];
      }
      return null;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  void _logout() {
    setState(() {
      _webViewController = null;
      _passwordController.clear();
    });
  }
}
