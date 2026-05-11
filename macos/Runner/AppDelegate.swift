import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var pendingFilePath: String?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Handle any pending file that was passed at launch
    if let filePath = pendingFilePath {
      sendFileToFlutter(filePath)
      pendingFilePath = nil
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // Handle file open requests (from file association or "Open With")
  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    sendFileToFlutter(filename)
    return true
  }

  // Also handle URLs (some macOS contexts use openURL)
  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      if url.isFileURL {
        sendFileToFlutter(url.path)
      }
    }
  }

  private func sendFileToFlutter(_ filePath: String) {
    // Get the Flutter engine from the main window's content view controller
    guard let flutterViewController = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      // Store for later when engine is ready
      pendingFilePath = filePath
      return
    }

    sendFileViaMethodChannel(flutterViewController: flutterViewController, filePath: filePath)
  }

  private func sendFileViaMethodChannel(flutterViewController: FlutterViewController, filePath: String) {
    let channel = FlutterMethodChannel(
      name: "com.vvviewer/spice",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    // Send to Flutter - pass as Map with 'uri' key to match Dart side
    channel.invokeMethod("onFileOpened", arguments: ["uri": filePath])
  }
}