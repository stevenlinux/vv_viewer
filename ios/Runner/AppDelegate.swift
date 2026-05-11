import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let CHANNEL = "com.vvviewer/spice"

  // aSPICE Pro 的 URL Scheme
  private let ASPICE_URL_SCHEME = "aspice://"
  private let ASPICE_APPSTORE_URL = "https://apps.apple.com/app/aspice-pro/id1560593107"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }

      switch call.method {
      case "isAspiceInstalled":
        self.isAspiceInstalled(result: result)
      case "openAspiceStore":
        self.openAspiceStore(result: result)
      case "launchSpice":
        self.launchSpice(call: call, result: result)
      case "launchSpiceWithFile":
        self.launchSpiceWithFile(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func isAspiceInstalled(result: FlutterResult) {
    guard let url = URL(string: ASPICE_URL_SCHEME) else {
      result(false)
      return
    }
    result(UIApplication.shared.canOpenURL(url))
  }

  private func openAspiceStore(result: @escaping FlutterResult) {
    guard let url = URL(string: ASPICE_APPSTORE_URL) else {
      result(false)
      return
    }
    UIApplication.shared.open(url, options: [:]) { success in
      result(success)
    }
  }

  private func launchSpice(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    let host = args?["host"] as? String ?? "localhost"
    let port = args?["port"] as? Int
    let tlsPort = args?["tlsPort"] as? Int
    let password = args?["password"] as? String
    let title = args?["title"] as? String

    // 构建 aSPICE URL
    var urlComponents = URLComponents()
    urlComponents.scheme = "aspice"
    urlComponents.host = host

    var queryItems = [URLQueryItem]()

    if let tlsPort = tlsPort {
      urlComponents.port = tlsPort
      queryItems.append(URLQueryItem(name: "tls-port", value: "\(tlsPort)"))
    } else if let port = port {
      urlComponents.port = port
      queryItems.append(URLQueryItem(name: "port", value: "\(port)"))
    }

    if let password = password {
      queryItems.append(URLQueryItem(name: "password", value: password))
    }

    if let title = title {
      queryItems.append(URLQueryItem(name: "title", value: title))
    }

    if !queryItems.isEmpty {
      urlComponents.queryItems = queryItems
    }

    guard let url = urlComponents.url else {
      result([
        "success": false,
        "error": "INVALID_URL",
        "message": "无法构建连接 URL"
      ])
      return
    }

    if !UIApplication.shared.canOpenURL(url) {
      // aSPICE 未安装，返回需要安装的错误
      result([
        "success": false,
        "error": "ASPICE_NOT_INSTALLED",
        "message": "请先安装 aSPICE Pro"
      ])
      return
    }

    UIApplication.shared.open(url, options: [:]) { success in
      if success {
        result([
          "success": true,
          "package": "com.iiordanov.aSPICE"
        ])
      } else {
        result([
          "success": false,
          "error": "LAUNCH_ERROR",
          "message": "无法打开 aSPICE Pro"
        ])
      }
    }
  }

  private func launchSpiceWithFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    guard let filePath = args?["filePath"] as? String else {
      result([
        "success": false,
        "error": "INVALID_FILE",
        "message": "文件路径无效"
      ])
      return
    }

    let fileURL = URL(fileURLWithPath: filePath)

    // 检查文件是否存在
    if !FileManager.default.fileExists(atPath: filePath) {
      result([
        "success": false,
        "error": "FILE_NOT_FOUND",
        "message": "文件不存在"
      ])
      return
    }

    // aSPICE iOS 版本可能不支持直接通过文件打开
    // 这里我们尝试读取文件内容并通过 URL 参数传递
    do {
      let content = try String(contentsOf: fileURL, encoding: .utf8)

      // 构建一个包含文件内容的自定义 URL（aSPICE iOS 可能不支持，这是一个备选方案）
      var urlComponents = URLComponents()
      urlComponents.scheme = "aspice"
      urlComponents.host = "file"

      let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
      urlComponents.queryItems = [
        URLQueryItem(name: "content", value: encodedContent)
      ]

      guard let url = urlComponents.url else {
        result([
          "success": false,
          "error": "INVALID_URL",
          "message": "无法构建文件 URL"
        ])
        return
      }

      if !UIApplication.shared.canOpenURL(url) {
        result([
          "success": false,
          "error": "ASPICE_NOT_INSTALLED",
          "message": "请先安装 aSPICE Pro"
        ])
        return
      }

      UIApplication.shared.open(url, options: [:]) { success in
        if success {
          result([
            "success": true,
            "package": "com.iiordanov.aSPICE"
          ])
        } else {
          // 如果直接文件方式失败，提示用户手动打开
          result([
            "success": false,
            "error": "FILE_LAUNCH_NOT_SUPPORTED",
            "message": "iOS 版本 aSPICE 可能不支持直接文件打开，请在 aSPICE 中手动选择文件"
          ])
        }
      }
    } catch {
      result([
        "success": false,
        "error": "READ_ERROR",
        "message": "读取文件失败: \(error.localizedDescription)"
      ])
    }
  }
}
