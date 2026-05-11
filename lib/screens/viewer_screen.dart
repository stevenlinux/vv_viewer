import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/vv_connection.dart';
import '../models/connection_type.dart';
import '../providers.dart';
import '../services/spice_launcher_service.dart';
import 'embedded_spice_screen.dart';

class ViewerScreen extends ConsumerStatefulWidget {
  final VVConnection connection;
  final String? filePath;

  const ViewerScreen({super.key, required this.connection, this.filePath});

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  bool _showPassword = false;
  bool _isAspiceInstalled = false;
  bool _isEmbeddedAspiceAvailable = false;
  bool _isChecking = true;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _checkAspiceInstallation();
    _saveToHistory();
  }

  @override
  void didUpdateWidget(ViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 connection 变了，重新检查并自动连接
    if (widget.connection != oldWidget.connection) {
      _checkAspiceInstallation();
    }
  }

  Future<void> _checkAspiceInstallation() async {
    final installed = await SpiceLauncherService.isAspiceInstalled();
    final embeddedAvailable = await SpiceLauncherService.isEmbeddedAspiceAvailable();
    if (!mounted) return;

    setState(() {
      _isAspiceInstalled = installed;
      _isEmbeddedAspiceAvailable = embeddedAvailable;
      _isChecking = false;
    });

    // 如果内嵌可用，自动启动连接
    if (embeddedAvailable && widget.connection.type == ConnectionType.spice) {
      _autoLaunchEmbeddedSpice();
    }
  }

  Future<void> _autoLaunchEmbeddedSpice() async {
    if (_isLaunching) return;
    _isLaunching = true;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmbeddedSpiceScreen(
            connection: widget.connection,
            filePath: widget.filePath,
          ),
        ),
      );
    } finally {
      if (mounted) {
        _isLaunching = false;
      }
    }
  }

  Future<void> _saveToHistory() async {
    try {
      final storage = ref.read(storageServiceProvider);
      await storage.saveConnection(widget.connection);
    } catch (e) {
      // 忽略保存错误
    }
  }

  Future<void> _launchSpice() async {
    if (_isLaunching) return;

    setState(() {
      _isLaunching = true;
    });

    try {
      final result = await SpiceLauncherService.launchSpice(
        connection: widget.connection,
      );

      if (!mounted) return;

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('正在启动 SPICE 连接...')),
          );
        }
      } else if (result.needsInstall) {
        _showInstallDialog();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('启动失败: ${result.message}')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
      }
    }
  }

  void _showInstallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要安装 aSPICE'),
        content: const Text('请先安装 aSPICE 客户端才能进行 SPICE 连接'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await SpiceLauncherService.openAspiceStore();
            },
            child: const Text('前往下载'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.connection.displayTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAspiceInstallation,
            tooltip: '刷新状态',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      widget.connection.type == ConnectionType.vnc
                          ? Icons.computer
                          : Icons.dvr,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${widget.connection.type.displayName} 连接',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.connection.displayTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildConnectionInfo(),
            const SizedBox(height: 20),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _isEmbeddedAspiceAvailable ? Colors.green[50] : (_isAspiceInstalled ? Colors.blue[50] : Colors.orange[50]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isChecking
                  ? Icons.hourglass_empty
                  : (_isEmbeddedAspiceAvailable
                      ? Icons.check_circle
                      : (_isAspiceInstalled ? Icons.check_circle_outline : Icons.warning)),
              color: _isChecking
                  ? Colors.grey
                  : (_isEmbeddedAspiceAvailable
                      ? Colors.green
                      : (_isAspiceInstalled ? Colors.blue : Colors.orange)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isChecking
                        ? '正在检查...'
                        : (_isEmbeddedAspiceAvailable
                            ? '内置 aSPICE 可用 ⭐'
                            : (_isAspiceInstalled
                                ? '外部 aSPICE 已安装'
                                : 'aSPICE 未安装')),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isChecking
                          ? Colors.grey
                          : (_isEmbeddedAspiceAvailable
                              ? Colors.green[800]
                              : (_isAspiceInstalled ? Colors.blue[800] : Colors.orange[800])),
                    ),
                  ),
                  if (_isEmbeddedAspiceAvailable)
                    Text(
                      '可使用内置 aSPICE 直接连接',
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                  if (!_isChecking && !_isEmbeddedAspiceAvailable && !_isAspiceInstalled)
                    Text(
                      '点击下方按钮下载安装',
                      style: TextStyle(color: Colors.orange[700], fontSize: 12),
                    ),
                ],
              ),
            ),
            if (!_isChecking && !_isEmbeddedAspiceAvailable && !_isAspiceInstalled)
              ElevatedButton.icon(
                onPressed: SpiceLauncherService.openAspiceStore,
                icon: const Icon(Icons.download),
                label: const Text('安装'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '快速操作',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _copyAllInfo,
                    icon: const Icon(Icons.copy_all),
                    label: const Text('复制全部'),
                  ),
                ),
                if (widget.connection.type == ConnectionType.spice && _isAspiceInstalled) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isChecking || _isLaunching
                          ? null
                          : _launchSpice,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('外部连接'),
                    ),
                  ),
                ],
                if (widget.connection.type == ConnectionType.spice && !_isAspiceInstalled && !_isEmbeddedAspiceAvailable) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isChecking || _isLaunching
                          ? null
                          : _showInstallDialog,
                      icon: const Icon(Icons.download),
                      label: const Text('安装 aSPICE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '连接详情',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('类型', widget.connection.type.displayName),
            _buildInfoRow('主机', widget.connection.host ?? '-'),
            if (widget.connection.port != null)
              _buildInfoRow('端口', widget.connection.port.toString()),
            if (widget.connection.tlsPort != null)
              _buildInfoRow('TLS 端口', widget.connection.tlsPort.toString()),
            if (widget.connection.proxy != null)
              _buildInfoRow('代理', widget.connection.proxy!),
            if (widget.connection.password != null) _buildPasswordRow(),
            _buildInfoRow('标题', widget.connection.title ?? '-'),
            _buildInfoRow('全屏', widget.connection.fullscreen ? '是' : '否'),
            if (widget.connection.enableUsbredir != null)
              _buildInfoRow(
                'USB 重定向',
                widget.connection.enableUsbredir! ? '是' : '否',
              ),
            if (widget.connection.enableSmartcard != null)
              _buildInfoRow(
                '智能卡',
                widget.connection.enableSmartcard! ? '是' : '否',
              ),
            if (widget.connection.enableAudio != null)
              _buildInfoRow(
                '音频',
                widget.connection.enableAudio! ? '是' : '否',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '密码',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Row(
            children: [
              Text(
                _showPassword ? widget.connection.password! : '••••••••',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  _copyToClipboard(widget.connection.password!, '密码');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (value != '-' && value != '是' && value != '否')
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      _copyToClipboard(value, label);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label 已复制到剪贴板')),
      );
    }
  }

  void _copyAllInfo() async {
    final buffer = StringBuffer();
    buffer.writeln('类型: ${widget.connection.type.displayName}');
    buffer.writeln('主机: ${widget.connection.host ?? ''}');
    if (widget.connection.port != null) {
      buffer.writeln('端口: ${widget.connection.port}');
    }
    if (widget.connection.tlsPort != null) {
      buffer.writeln('TLS端口: ${widget.connection.tlsPort}');
    }
    if (widget.connection.proxy != null) {
      buffer.writeln('代理: ${widget.connection.proxy}');
    }
    if (widget.connection.password != null) {
      buffer.writeln('密码: ${widget.connection.password}');
    }
    if (widget.connection.title != null) {
      buffer.writeln('标题: ${widget.connection.title}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有连接信息已复制到剪贴板')),
      );
    }
  }
}
