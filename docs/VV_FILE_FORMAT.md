# .vv (virt-viewer) 文件格式详解

## 概述

.vv 文件是 virt-viewer 工具使用的配置文件格式，用于存储 SPICE 或 VNC 远程桌面连接的配置信息。该文件采用 INI 格式。

## 基本格式

```ini
[virt-viewer]
type=spice
host=192.168.1.100
port=3001
tls-port=3002
password=secret
title=My Virtual Machine
fullscreen=1
```

## 完整配置项列表

### 基础连接配置

| 配置项 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `type` | string | 连接类型：`spice` 或 `vnc` | `type=spice` |
| `host` | string | 服务器主机名或 IP 地址 | `host=192.168.1.100` |
| `port` | int | 非 TLS 端口号 | `port=3001` |
| `tls-port` | int | TLS 加密端口号 | `tls-port=3002` |
| `password` | string | 连接密码 | `password=MySecret123` |
| `username` | string | 用户名（可选） | `username=admin` |
| `proxy` | string | 代理 URL | `proxy=http://proxy:8080` |

### 显示配置

| 配置项 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `title` | string | 窗口标题 | `title=Ubuntu VM` |
| `fullscreen` | int | 是否全屏：`0` 或 `1` | `fullscreen=1` |
| `toggle-fullscreen` | string | 全屏切换快捷键 | `toggle-fullscreen=ctrl+alt+f` |
| `release-cursor` | string | 释放光标快捷键 | `release-cursor=ctrl+alt` |
| `color-depth` | int | 颜色深度（16/24/32） | `color-depth=24` |
| `disable-effects` | string list | 禁用的效果列表 | `disable-effects=animation,shadow` |

### 安全配置

| 配置项 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `ca` | string | CA 证书 PEM 数据（用 `\n` 换行） | `ca=-----BEGIN CERTIFICATE-----\n...` |
| `host-subject` | string | 主机证书主题 | `host-subject=CN=myvm` |
| `tls-ciphers` | string | TLS 加密套件 | `tls-ciphers=HIGH:+MEDIUM` |
| `secure-channels` | string list | 需要加密的通道 | `secure-channels=main,display` |
| `disable-channels` | string list | 禁用的通道 | `disable-channels=playback` |

### 设备配置

| 配置项 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `enable-smartcard` | int | 启用智能卡：`0` 或 `1` | `enable-smartcard=1` |
| `smartcard-insert` | string | 插入智能卡快捷键 | `smartcard-insert=ctrl+alt+i` |
| `smartcard-remove` | string | 移除智能卡快捷键 | `smartcard-remove=ctrl+alt+r` |
| `enable-usbredir` | int | 启用 USB 重定向：`0` 或 `1` | `enable-usbredir=1` |
| `enable-usb-autoshare` | int | 启用 USB 自动共享 | `enable-usb-autoshare=1` |
| `usb-filter` | string | USB 设备过滤规则 | `usb-filter=-1,-1,-1,-1,0` |

### 音频配置

| 配置项 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `enable-audio` | int | 启用音频：`0` 或 `1` | `enable-audio=1` |

### 其他配置

| 配置项 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `version` | string | 文件格式版本 | `version=1.0` |
| `delete-this-file` | int | 连接后删除文件：`0` 或 `1` | `delete-this-file=1` |
| `secure-attention` | string | 安全注意键序列 | `secure-attention=ctrl+alt+del` |

## PVE (Proxmox VE) 生成的 .vv 文件示例

### 标准 SPICE 连接

```ini
[virt-viewer]
type=spice
host=192.168.1.50
port=3128
tls-port=3129
password=supersecret
title=VM 101 - Ubuntu 22.04
toggle-fullscreen=shift+f11
release-cursor=ctrl+alt
delete-this-file=1
fullscreen=0
enable-usbredir=1
enable-smartcard=0
enable-audio=1
```

### 带代理的连接

```ini
[virt-viewer]
type=spice
host=10.0.0.100
port=5900
tls-port=5901
password=password123
proxy=http://proxy.example.com:3128
title=Production Server
fullscreen=0
```

## 代码实现

### Flutter 解析实现

参见 `lib/parsers/vv_parser.dart`

```dart
class VVParser {
  static VVConnection parse(String content) {
    // 按行解析
    // 查找 [virt-viewer] 段
    // 解析 key=value 对
  }
}
```

### C 语言解析实现 (virt-viewer-file.c)

关键函数：
- `virt_viewer_file_new()` - 从文件创建
- `virt_viewer_file_get_*()` - 获取各项配置
- `virt_viewer_file_is_set()` - 检查配置项是否存在

### Android 解析流程

1. `RemoteCanvasActivity.onNewIntent(Intent)` 接收文件 intent
2. `UriIntentParser` 解析 URI
3. 读取文件内容
4. 通过 JNI 调用 native 层解析
5. 填充 `AbstractConnectionBean`

## 注意事项

1. **文件编码**：建议使用 UTF-8 编码
2. **换行符**：支持 `\n` (Unix) 和 `\r\n` (Windows)
3. **密码安全**：密码以明文存储，注意文件权限
4. **`delete-this-file`**：设置为 1 时，virt-viewer 会在连接成功后删除文件
5. **扩展字段**：自定义字段建议使用 `x-` 前缀

## 验证工具

### 检查 .vv 文件是否有效

```bash
# 使用 remote-viewer 验证
remote-viewer --preview connection.vv

# 或在 Android 上用 aSPICE 打开
```

## 相关资源

- [virt-viewer 官方文档](https://virt-manager.org/)
- [SPICE 协议规范](https://www.spice-space.org/)
- [Proxmox VE 文档](https://pve.proxmox.com/wiki/SPICE)
