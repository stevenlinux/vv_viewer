# vv_viewer 测试计划

## 测试环境
- 设备：Android 手机 (duchamp)
- APK：`android/app/build/outputs/apk/debug/app-debug.apk`
- 构建：`flutter build apk --debug`

---

## 手动测试用例

### 测试 1：同一连接唤醒（外部调用 - PVE App）

**目的**：验证点击同一 .vv 链接时，使用 CLEAR_TOP 唤醒现有连接

**步骤**：
1. 安装 APK：`adb install -r android/app/build/outputs/apk/debug/app-debug.apk`
2. 从 PVE App 打开一个 .vv 文件
3. 观察 SPICE 连接建立
4. 再次点击同一个 .vv 文件
5. 观察日志：`adb logcat | grep -i "MainActivity\|RemoteCanvas"`

**预期结果**：
```
isSameConnection: true
Started RemoteCanvasActivity with CLEAR_TOP for same connection
```

**实际结果**：________________

---

### 测试 2：不同连接（外部调用）

**目的**：验证点击不同 .vv 链接时，创建新连接

**步骤**：
1. 从 PVE App 打开 .vv 文件 A
2. 连接建立后，再打开 .vv 文件 B

**预期结果**：
```
isSameConnection: false
Started RemoteCanvasActivity with NEW_TASK
```

**实际结果**：________________

---

### 测试 3：Flutter 调用同一连接

**目的**：验证 Flutter 端同一文件路径的多次调用

**步骤**：
1. 在 Flutter App 中打开一个连接
2. 再次点击同一个 VM

**预期结果**：
```
launchEmbeddedSpiceWithFile: CLEAR_TOP for same connection
```

**实际结果**：________________

---

### 测试 4：连接断开后重新连接

**目的**：验证断开后再次连接正常

**步骤**：
1. 建立 SPICE 连接
2. 点击断开按钮或返回键
3. 再次打开同一连接

**预期结果**：正常建立连接，无错误

**实际结果**：________________

---

### 测试 5：第三次点击白屏问题

**目的**：验证多次点击同一链接不再出现白屏

**步骤**：
1. 打开连接 A
2. 断开
3. 再次打开连接 A
4. 第三次打开连接 A

**预期结果**：每次都能正常连接

**实际结果**：________________

---

## 代码审计问题清单

### 已修复的问题 ✅

| # | 问题 | 文件 | 状态 |
|---|------|------|------|
| 1 | `onNewIntent()` 不处理新连接 | RemoteCanvasActivity.java | ✅ 已修复 |
| 2 | `resolveContentUriSync` 临时文件未追踪 | MainActivity.kt | ✅ 已修复 |
| 3 | spiceComm 重新连接时未关闭旧实例 | RemoteOpaqueConnection.kt | ✅ 已修复 |
| 4 | BroadcastReceiver 未注销 | SpiceCommunicator.java | ✅ 已修复 |

### 待验证的问题 ⚠️

| # | 问题 | 严重程度 | 验证方法 |
|---|------|----------|----------|
| A | `savedContext` 可能导致内存泄漏 | 中 | Android Studio Memory Profiler |
| B | `onDestroy()` 无异常处理 | 低 | 代码审查 |
| C | `recreate()` 时 connection 未关闭 | 高 | 手动测试 #5 |

---

## 日志命令

```bash
# 过滤 MainActivity 日志
adb logcat | grep -i "MainActivity\|handleVirtViewerFile\|launchEmbeddedSpiceWithFile"

# 过滤 RemoteCanvasActivity 日志
adb logcat | grep -i "RemoteCanvas\|onCreate\|onNewIntent\|onDestroy"

# 过滤 SPICE 日志
adb logcat | grep -i "SpiceCommunicator\|close()\|myself"

# 完整日志
adb logcat -d > app_log.txt
```
