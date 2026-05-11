package com.vvviewer.vv_viewer

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.ComponentName
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.URLDecoder

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.vvviewer/spice"
    private val TAG = "MainActivity"

    // aSPICE 包名（外部调用用）
    private val ASPICE_PACKAGE = "com.iiordanov.aSPICE"
    private val ASPICE_PACKAGE_FREE = "com.iiordanov.freeaSPICE"
    private val ASPICE_ACTIVITY = "com.iiordanov.bVNC.RemoteCanvasActivity"

    // 内置 aSPICE Activity（内嵌模式用）
    private val EMBEDDED_ASPICE_ACTIVITY = "com.iiordanov.bVNC.RemoteCanvasActivity"

    // 保存 MethodChannel 引用以便在 onCreate 中使用
    private var methodChannel: MethodChannel? = null

    // 保存初始 intent 以便在 FlutterEngine 准备好后处理
    private var pendingIntent: Intent? = null

    // 跟踪临时文件路径，Activity 关闭时清理
    private val tempFiles = mutableSetOf<String>()

    // SharedPreferences for persisting connection state across process deaths
    private lateinit var prefs: SharedPreferences
    private val PREFS_NAME = "vv_viewer_connection"
    private val KEY_EXTERNAL_CALL_PATH = "external_call_path"
    private val KEY_FLUTTER_CALL_PATH = "flutter_call_path"

    // 外部调用追踪：存储解析后的文件路径
    private var externalCallPath: String? = null
    // Flutter 调用追踪：存储文件路径
    private var flutterCallPath: String? = null

    // 连接关闭回调接口
    interface ConnectionClosedListener {
        fun onConnectionClosed()
    }
    companion object {
        // 静态回调列表，用于通知连接关闭
        private val connectionClosedListeners = mutableListOf<ConnectionClosedListener>()

        // 注册连接关闭监听器
        fun addConnectionClosedListener(listener: ConnectionClosedListener) {
            synchronized(connectionClosedListeners) {
                connectionClosedListeners.add(listener)
            }
        }

        // 移除连接关闭监听器
        fun removeConnectionClosedListener(listener: ConnectionClosedListener) {
            synchronized(connectionClosedListeners) {
                connectionClosedListeners.remove(listener)
            }
        }

        // 重置连接状态（供外部调用）
        fun resetConnectionState() {
            Log.d("MainActivity", "resetConnectionState called")
            synchronized(connectionClosedListeners) {
                for (listener in connectionClosedListeners) {
                    listener.onConnectionClosed()
                }
                connectionClosedListeners.clear()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "configureFlutterEngine called")

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            Log.d(TAG, "MethodCall received: ${call.method}")
            when (call.method) {
                "launchSpice" -> {
                    val host = call.argument<String>("host")
                    val port = call.argument<Int>("port")
                    val tlsPort = call.argument<Int>("tlsPort")
                    val password = call.argument<String>("password")
                    val title = call.argument<String>("title")

                    launchSpice(host, port, tlsPort, password, title, result)
                }
                "launchSpiceWithFile" -> {
                    val filePath = call.argument<String>("filePath")
                    launchSpiceWithFile(filePath, result)
                }
                "launchEmbeddedSpice" -> {
                    val host = call.argument<String>("host")
                    val port = call.argument<Int>("port")
                    val tlsPort = call.argument<Int>("tlsPort")
                    val password = call.argument<String>("password")
                    val title = call.argument<String>("title")

                    launchEmbeddedSpice(host, port, tlsPort, password, title, result)
                }
                "launchEmbeddedSpiceWithFile" -> {
                    val filePath = call.argument<String>("filePath")
                    launchEmbeddedSpiceWithFile(filePath, result)
                }
                "isAspiceInstalled" -> {
                    result.success(isAspiceInstalled())
                }
                "isEmbeddedAspiceAvailable" -> {
                    result.success(true)
                }
                "openAspiceStore" -> {
                    openAspiceStore(result)
                }
                "resolveContentUri" -> {
                    val uriString = call.argument<String>("uri")
                    resolveContentUri(uriString, result)
                }
                "getInitialUri" -> {
                    // 返回初始 URI 给 Flutter
                    val uri = getIntent()?.data
                    result.success(uri?.toString())
                }
                "resetConnectionState" -> {
                    // 重置连接状态（连接关闭时调用）
                    resetConnectionState()
                    externalCallPath = null
                    flutterCallPath = null
                    // 清除持久化的连接状态
                    prefs.edit()
                        .remove(KEY_EXTERNAL_CALL_PATH)
                        .remove(KEY_FLUTTER_CALL_PATH)
                        .apply()
                    Log.d(TAG, "resetConnectionState: cleared in-memory and persisted state")
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 处理初始 intent（如果有待处理的）
        Log.d(TAG, "configureFlutterEngine: pendingIntent=$pendingIntent")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 初始化 SharedPreferences 并恢复连接状态
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        externalCallPath = prefs.getString(KEY_EXTERNAL_CALL_PATH, null)
        flutterCallPath = prefs.getString(KEY_FLUTTER_CALL_PATH, null)
        Log.d(TAG, "onCreate: restored externalCallPath=$externalCallPath, flutterCallPath=$flutterCallPath")

        // 保存 intent 以便在 FlutterEngine 准备好后处理
        Log.d(TAG, "onCreate called with intent=${intent}")
        pendingIntent = intent
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume called, pendingIntent=$pendingIntent")
        pendingIntent?.let { handleIntent(it) }
        pendingIntent = null
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent called with intent=${intent}")
        // 处理新的 intent（当 app 已经在运行时）
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        Log.d(TAG, "handleIntent called with intent=$intent")
        intent ?: return
        Log.d(TAG, "handleIntent: action=${intent.action}, type=${intent.type}, data=${intent.data}")
        if (intent.action != Intent.ACTION_VIEW) {
            Log.d(TAG, "handleIntent: not ACTION_VIEW, returning")
            return
        }
        val uri = intent.data ?: run {
            Log.d(TAG, "handleIntent: no data, returning")
            return
        }
        Log.d(TAG, "handleIntent: uri=$uri, scheme=${uri.scheme}")

        // 检查是否是 .vv 文件：content:// URI 或明确的 MIME 类型
        val isVirtViewerFile = intent.type == "application/x-virt-viewer" ||
            intent.type == "application/octet-stream" ||
            uri.toString().contains(".vv") ||
            uri.scheme == "content"

        // 检查是否是 spice+ URL（PVE/Proxmox 调用）
        val isSpiceUrl = uri.scheme?.startsWith("spice+") == true

        Log.d(TAG, "handleIntent: isVirtViewerFile=$isVirtViewerFile, isSpiceUrl=$isSpiceUrl, mimeType=${intent.type}")

        if (isSpiceUrl) {
            // spice+ URL 需要特殊处理：解析 URL 并启动 RemoteCanvasActivity
            Log.d(TAG, "Detected spice+ URL, handling as SPICE connection: $uri")
            handleSpiceUrl(uri.toString())
        } else if (isVirtViewerFile) {
            Log.d(TAG, "Detected .vv file intent, handling directly: $uri")
            // 直接在 Native 层处理，不需要通知 Flutter
            handleVirtViewerFile(uri.toString())
        }
    }

    private fun handleVirtViewerFile(uriString: String, isPveCall: Boolean = false) {
        Log.d(TAG, "handleVirtViewerFile: $uriString, isPveCall=$isPveCall")
        try {
            val uri = Uri.parse(uriString)

            // 解析文件路径用于比较和启动 RemoteCanvasActivity
            val realPath: String?
            if (uri.scheme == "content") {
                realPath = resolveContentUriSync(uriString)
            } else {
                // 对于文件路径或 PVE 生成的临时 .vv 文件
                realPath = uri.path ?: uriString
            }

            if (realPath == null) {
                Log.e(TAG, "Failed to resolve file path for: $uriString")
                return
            }

            Log.d(TAG, "Resolved to: $realPath")

            // 判断是否同一连接：用解析后的文件路径比较
            val isSameConnection = (realPath == externalCallPath)
            Log.d(TAG, "isSameConnection: $isSameConnection, externalCallPath: $externalCallPath, newPath: $realPath")

            // 更新当前连接信息（保存解析后的文件路径）并持久化
            externalCallPath = realPath
            prefs.edit().putString(KEY_EXTERNAL_CALL_PATH, realPath).apply()
            Log.d(TAG, "Persisted externalCallPath: $realPath")

            val file = File(realPath)
            if (!file.exists()) {
                Log.e(TAG, "File does not exist: $realPath")
                return
            }

            if (isSameConnection) {
                // 同一连接：使用 CLEAR_TOP 唤醒现有 Activity
                Log.d(TAG, "Same connection, using CLEAR_TOP to bring to front")
                try {
                    val newIntent = Intent(Intent.ACTION_VIEW).apply {
                        setClass(this@MainActivity, com.iiordanov.bVNC.RemoteCanvasActivity::class.java)
                        setDataAndType(uri, "application/x-virt-viewer")
                        putExtra("vv_file_path", realPath)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    }
                    startActivity(newIntent)
                    Log.d(TAG, "Started RemoteCanvasActivity with CLEAR_TOP for same connection")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start RemoteCanvasActivity: ${e.message}")
                }
            } else {
                // 不同连接：直接启动新连接
                Log.d(TAG, "Different connection, launching new activity")

                try {
                    val newIntent = Intent(Intent.ACTION_VIEW).apply {
                        setClass(this@MainActivity, com.iiordanov.bVNC.RemoteCanvasActivity::class.java)
                        setDataAndType(uri, "application/x-virt-viewer")
                        putExtra("vv_file_path", realPath)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(newIntent)
                    Log.d(TAG, "Started RemoteCanvasActivity with NEW_TASK")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start RemoteCanvasActivity: ${e.message}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "handleVirtViewerFile error: ${e.message}")
        }
    }

    /**
     * 处理 PVE/Proxmox 的 spice+ URL
     * 格式: spice+https://host:port/?vmid=xxx&node=xxx&ticket=xxx&...
     * 这些 URL 需要通过 PVE API 获取真正的 SPICE 连接数据
     */
    private fun handleSpiceUrl(uriString: String) {
        Log.d(TAG, "handleSpiceUrl: $uriString")
        try {
            val uri = Uri.parse(uriString)

            // 从 URI 提取主机和端口
            val host = uri.host ?: run {
                Log.e(TAG, "handleSpiceUrl: no host found in URI")
                return
            }
            val port = if (uri.port != -1) uri.port else 443

            // 解析查询参数
            val queryParams = parseQueryParams(uri.query)
            val vmid = queryParams["vmid"]
            val node = queryParams["node"]
            val ticket = queryParams["ticket"]
            val proxy = queryParams["proxy"]
            val csrfToken = queryParams["csrfToken"]

            Log.d(TAG, "handleSpiceUrl: host=$host, port=$port")
            Log.d(TAG, "handleSpiceUrl: vmid=$vmid, node=$node, ticket=$ticket, proxy=$proxy")

            // 检查是否是 PVE URL（有 vmid 参数）
            val isPveUrl = !vmid.isNullOrEmpty()

            if (isPveUrl) {
                // PVE URL：需要通过 PVE API 获取连接数据
                // 我们直接传递 URL 给 RemoteCanvasActivity，让它通过 RemoteProxmoxConnection 处理
                Log.d(TAG, "handleSpiceUrl: Detected PVE URL, passing directly to RemoteCanvasActivity")

                // 使用 URL 的 hash 作为稳定的标识符，用于判断是否同一连接
                val urlHash = uriString.hashCode().toString()

                // 判断是否同一连接：直接比较 urlHash（因为 externalCallPath 存储的已经是 hash）
                val isSameConnection = (urlHash == externalCallPath)

                // 更新当前连接信息并持久化
                externalCallPath = urlHash
                prefs.edit().putString(KEY_EXTERNAL_CALL_PATH, urlHash).apply()
                Log.d(TAG, "handleSpiceUrl: isSameConnection=$isSameConnection, urlHash=$urlHash")

                // 直接将 spice+ URL 传递给 RemoteCanvasActivity
                // 使用 urlHash 作为 vv_file_path 以便在 onNewIntent 中正确比较
                if (isSameConnection) {
                    // 同一连接：使用 CLEAR_TOP 唤醒现有 Activity
                    try {
                        val newIntent = Intent(Intent.ACTION_VIEW).apply {
                            setClass(this@MainActivity, com.iiordanov.bVNC.RemoteCanvasActivity::class.java)
                            setDataAndType(uri, null)
                            putExtra("vv_file_path", urlHash) // 使用 hash 作为标识
                            putExtra("pve_url", uriString) // 保留原始 PVE URL
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        }
                        startActivity(newIntent)
                        Log.d(TAG, "Started RemoteCanvasActivity with CLEAR_TOP for same PVE connection")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to start RemoteCanvasActivity: ${e.message}")
                    }
                } else {
                    // 不同连接：直接启动新连接
                    try {
                        val newIntent = Intent(Intent.ACTION_VIEW).apply {
                            setClass(this@MainActivity, com.iiordanov.bVNC.RemoteCanvasActivity::class.java)
                            setDataAndType(uri, null)
                            putExtra("vv_file_path", urlHash) // 使用 hash 作为标识
                            putExtra("pve_url", uriString) // 保留原始 PVE URL
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(newIntent)
                        Log.d(TAG, "Started RemoteCanvasActivity with NEW_TASK for PVE connection")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to start RemoteCanvasActivity: ${e.message}")
                    }
                }
            } else {
                // 非 PVE 的 SPICE URL：直接传递给 RemoteCanvasActivity
                Log.d(TAG, "handleSpiceUrl: Non-PVE SPICE URL, passing directly to RemoteCanvasActivity")

                // 判断是否同一连接
                val isSameConnection = (uriString == externalCallPath)

                // 更新当前连接信息并持久化
                externalCallPath = uriString
                prefs.edit().putString(KEY_EXTERNAL_CALL_PATH, uriString).apply()

                if (isSameConnection) {
                    // 同一连接：使用 CLEAR_TOP 唤醒现有 Activity
                    try {
                        val newIntent = Intent(Intent.ACTION_VIEW).apply {
                            setClass(this@MainActivity, com.iiordanov.bVNC.RemoteCanvasActivity::class.java)
                            setDataAndType(uri, null)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        }
                        startActivity(newIntent)
                        Log.d(TAG, "Started RemoteCanvasActivity with CLEAR_TOP for same spice connection")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to start RemoteCanvasActivity: ${e.message}")
                    }
                } else {
                    // 不同连接：直接启动新连接
                    try {
                        val newIntent = Intent(Intent.ACTION_VIEW).apply {
                            setClass(this@MainActivity, com.iiordanov.bVNC.RemoteCanvasActivity::class.java)
                            setDataAndType(uri, null)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(newIntent)
                        Log.d(TAG, "Started RemoteCanvasActivity with NEW_TASK for spice connection")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to start RemoteCanvasActivity: ${e.message}")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "handleSpiceUrl error: ${e.message}")
        }
    }

    private fun parseQueryParams(query: String?): Map<String, String> {
        val params = mutableMapOf<String, String>()
        query?.split("&")?.forEach { param ->
            val parts = param.split("=", limit = 2)
            if (parts.size == 2) {
                try {
                    params[parts[0]] = URLDecoder.decode(parts[1], "UTF-8")
                } catch (e: Exception) {
                    params[parts[0]] = parts[1]
                }
            }
        }
        return params
    }

    private fun resolveContentUriSync(uriString: String): String? {
        return try {
            val uri = Uri.parse(uriString)
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val tempFile = File(cacheDir, "vv_temp_${System.currentTimeMillis()}.vv")
            inputStream.use { input ->
                tempFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            // 跟踪临时文件以便后续清理
            tempFiles.add(tempFile.absolutePath)
            Log.d(TAG, "resolveContentUriSync: saved to ${tempFile.absolutePath}")
            tempFile.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "resolveContentUriSync error: ${e.message}")
            null
        }
    }

    private fun launchEmbeddedSpiceWithFileInternal(filePath: String) {
        Log.d(TAG, "launchEmbeddedSpiceWithFileInternal: $filePath")
        try {
            val file = File(filePath)
            if (!file.exists()) {
                Log.e(TAG, "File does not exist: $filePath")
                return
            }

            val uri: Uri = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    file
                )
            } else {
                Uri.fromFile(file)
            }

            // 启动内嵌的 RemoteCanvasActivity
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setClass(this@MainActivity, com.iiordanov.bVNC.RemoteCanvasActivity::class.java)
                setDataAndType(uri, "application/x-virt-viewer")
                putExtra("vv_file_path", filePath)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                // 不加 NEW_TASK，让 RemoteCanvasActivity 可以在同一个 task 中被复用
            }

            try {
                startActivity(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start RemoteCanvasActivity: ${e.message}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "launchEmbeddedSpiceWithFileInternal error: ${e.message}")
        }
    }

    private fun isAspiceInstalled(): Boolean {
        return try {
            packageManager.getPackageInfo(ASPICE_PACKAGE, 0)
            true
        } catch (e: Exception) {
            try {
                packageManager.getPackageInfo(ASPICE_PACKAGE_FREE, 0)
                true
            } catch (e: Exception) {
                false
            }
        }
    }

    private fun getAspicePackage(): String {
        return try {
            packageManager.getPackageInfo(ASPICE_PACKAGE, 0)
            ASPICE_PACKAGE
        } catch (e: Exception) {
            try {
                packageManager.getPackageInfo(ASPICE_PACKAGE_FREE, 0)
                ASPICE_PACKAGE_FREE
            } catch (e: Exception) {
                ASPICE_PACKAGE_FREE
            }
        }
    }

    private fun launchSpice(
        host: String?,
        port: Int?,
        tlsPort: Int?,
        password: String?,
        title: String?,
        result: MethodChannel.Result
    ) {
        try {
            val pkg = getAspicePackage()
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setClassName(pkg, ASPICE_ACTIVITY)

                // 构建 spice:// URI
                val uriBuilder = StringBuilder()
                uriBuilder.append("spice://")
                uriBuilder.append(host ?: "localhost")

                val usePort = tlsPort ?: port ?: 5900
                uriBuilder.append(":").append(usePort)

                val params = mutableListOf<String>()
                if (tlsPort != null) {
                    params.add("tls-port=$tlsPort")
                }
                if (port != null && tlsPort == null) {
                    params.add("port=$port")
                }
                if (!password.isNullOrEmpty()) {
                    params.add("password=${Uri.encode(password)}")
                }
                if (!title.isNullOrEmpty()) {
                    params.add("title=${Uri.encode(title)}")
                }

                if (params.isNotEmpty()) {
                    uriBuilder.append("?").append(params.joinToString("&"))
                }

                data = Uri.parse(uriBuilder.toString())
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            startActivity(intent)
            result.success(mapOf("success" to true, "package" to pkg))
        } catch (e: ActivityNotFoundException) {
            Log.e(TAG, "aSPICE not found", e)
            result.success(mapOf(
                "success" to false,
                "error" to "ASPICE_NOT_INSTALLED",
                "message" to "请先安装 aSPICE 客户端"
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error launching SPICE", e)
            result.success(mapOf(
                "success" to false,
                "error" to "LAUNCH_ERROR",
                "message" to e.message
            ))
        }
    }

    private fun launchSpiceWithFile(filePath: String?, result: MethodChannel.Result) {
        if (filePath.isNullOrEmpty()) {
            result.success(mapOf(
                "success" to false,
                "error" to "INVALID_FILE",
                "message" to "文件路径无效"
            ))
            return
        }

        try {
            val file = File(filePath)
            if (!file.exists()) {
                result.success(mapOf(
                    "success" to false,
                    "error" to "FILE_NOT_FOUND",
                    "message" to "文件不存在"
                ))
                return
            }

            val pkg = getAspicePackage()
            val uri: Uri = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    file
                )
            } else {
                Uri.fromFile(file)
            }

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setClassName(pkg, ASPICE_ACTIVITY)
                setDataAndType(uri, "application/x-virt-viewer")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            startActivity(intent)
            result.success(mapOf("success" to true, "package" to pkg))
        } catch (e: ActivityNotFoundException) {
            Log.e(TAG, "aSPICE not found", e)
            result.success(mapOf(
                "success" to false,
                "error" to "ASPICE_NOT_INSTALLED",
                "message" to "请先安装 aSPICE 客户端"
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error launching SPICE with file", e)
            result.success(mapOf(
                "success" to false,
                "error" to "LAUNCH_ERROR",
                "message" to e.message
            ))
        }
    }

    private fun openAspiceStore(result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("market://details?id=$ASPICE_PACKAGE_FREE")
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            try {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    data = Uri.parse("https://play.google.com/store/apps/details?id=$ASPICE_PACKAGE_FREE")
                }
                startActivity(intent)
                result.success(true)
            } catch (e: Exception) {
                result.success(false)
            }
        }
    }

    private fun resolveContentUri(uriString: String?, result: MethodChannel.Result) {
        if (uriString.isNullOrEmpty()) {
            result.success(null)
            return
        }
        try {
            val uri = Uri.parse(uriString)
            val inputStream = contentResolver.openInputStream(uri)
            if (inputStream == null) {
                result.success(null)
                return
            }
            val tempFile = File(cacheDir, "vv_temp_${System.currentTimeMillis()}.vv")
            inputStream.use { input ->
                tempFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            // 跟踪临时文件以便后续清理
            tempFiles.add(tempFile.absolutePath)
            Log.d(TAG, "resolveContentUri: saved to ${tempFile.absolutePath}")
            result.success(tempFile.absolutePath)
        } catch (e: Exception) {
            Log.e(TAG, "resolveContentUri failed", e)
            result.success(null)
        }
    }

    // ==================== 内嵌 aSPICE 模式 ====================

    private fun launchEmbeddedSpice(
        host: String?,
        port: Int?,
        tlsPort: Int?,
        password: String?,
        title: String?,
        result: MethodChannel.Result
    ) {
        try {
            // 构建 spice:// URI
            val uriBuilder = StringBuilder()
            uriBuilder.append("spice://")
            uriBuilder.append(host ?: "localhost")

            val usePort = tlsPort ?: port ?: 5900
            uriBuilder.append(":").append(usePort)

            val params = mutableListOf<String>()
            if (tlsPort != null) {
                params.add("tls-port=$tlsPort")
            }
            if (port != null && tlsPort == null) {
                params.add("port=$port")
            }
            if (!password.isNullOrEmpty()) {
                params.add("password=${Uri.encode(password)}")
            }
            if (!title.isNullOrEmpty()) {
                params.add("title=${Uri.encode(title)}")
            }

            if (params.isNotEmpty()) {
                uriBuilder.append("?").append(params.joinToString("&"))
            }

            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse(uriBuilder.toString())
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            // 先尝试显式启动（通过 setClass）
            try {
                intent.setClass(this, com.iiordanov.bVNC.RemoteCanvasActivity::class.java)
                startActivity(intent)
            } catch (e: Exception) {
                // 如果失败，尝试通过 URI scheme 自动匹配
                Log.d(TAG, "Explicit launch failed, trying URI match: ${e.message}")
                intent.removeCategory(Intent.CATEGORY_BROWSABLE)
                intent.addCategory(Intent.CATEGORY_DEFAULT)
                startActivity(intent)
            }

            result.success(mapOf(
                "success" to true,
                "mode" to "embedded"
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error launching embedded SPICE", e)
            result.success(mapOf(
                "success" to false,
                "error" to "LAUNCH_ERROR",
                "message" to e.message
            ))
        }
    }

    private fun launchEmbeddedSpiceWithFile(filePath: String?, result: MethodChannel.Result) {
        if (filePath.isNullOrEmpty()) {
            result.success(mapOf(
                "success" to false,
                "error" to "INVALID_FILE",
                "message" to "文件路径无效"
            ))
            return
        }

        try {
            val file = File(filePath)
            if (!file.exists()) {
                result.success(mapOf(
                    "success" to false,
                    "error" to "FILE_NOT_FOUND",
                    "message" to "文件不存在"
                ))
                return
            }

            // 判断是否同一连接：用文件路径比较（Flutter 调用）
            val isSameConnection = (filePath == flutterCallPath)
            Log.d(TAG, "launchEmbeddedSpiceWithFile: isSameConnection: $isSameConnection, flutterCallPath: $flutterCallPath, newPath: $filePath")

            // 更新当前连接信息（保存文件路径）并持久化
            flutterCallPath = filePath
            prefs.edit().putString(KEY_FLUTTER_CALL_PATH, filePath).apply()
            Log.d(TAG, "Persisted flutterCallPath: $filePath")

            val uri: Uri = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    file
                )
            } else {
                Uri.fromFile(file)
            }

            if (isSameConnection) {
                // 同一连接：使用 CLEAR_TOP 唤醒现有 Activity
                try {
                    val newIntent = Intent(Intent.ACTION_VIEW).apply {
                        setClass(this@MainActivity, com.iiordanov.bVNC.RemoteCanvasActivity::class.java)
                        setDataAndType(uri, "application/x-virt-viewer")
                        putExtra("vv_file_path", filePath)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    }
                    startActivity(newIntent)
                    Log.d(TAG, "launchEmbeddedSpiceWithFile: CLEAR_TOP for same connection")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start RemoteCanvasActivity: ${e.message}")
                }
            } else {
                // 不同连接：使用 NEW_TASK 启动新连接（每个连接独立任务）
                try {
                    val newIntent = Intent(Intent.ACTION_VIEW).apply {
                        setClass(this@MainActivity, com.iiordanov.bVNC.RemoteCanvasActivity::class.java)
                        setDataAndType(uri, "application/x-virt-viewer")
                        putExtra("vv_file_path", filePath)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(newIntent)
                    Log.d(TAG, "launchEmbeddedSpiceWithFile: NEW_TASK for different connection")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start RemoteCanvasActivity: ${e.message}")
                }
            }

            result.success(mapOf(
                "success" to true,
                "mode" to "embedded"
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Error launching embedded SPICE with file", e)
            result.success(mapOf(
                "success" to false,
                "error" to "LAUNCH_ERROR",
                "message" to e.message
            ))
        }
    }

    override fun onDestroy() {
        // 清理临时文件
        for (filePath in tempFiles) {
            try {
                val file = File(filePath)
                if (file.exists() && file.delete()) {
                    Log.d(TAG, "Deleted temp file: $filePath")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to delete temp file: $filePath", e)
            }
        }
        tempFiles.clear()
        super.onDestroy()
    }
}
