import Cocoa
import FlutterMacOS
import CoreGraphics

@main
class AppDelegate: FlutterAppDelegate {
  private var systemIdleChannel: FlutterMethodChannel?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      super.applicationDidFinishLaunching(notification)
      return
    }

    let channel = FlutterMethodChannel(
      name: "structural/system_idle",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isSupported":
        result(true)
      case "getIdleMilliseconds":
        let seconds = CGEventSource.secondsSinceLastEventType(
          .combinedSessionState,
          eventType: .null
        )
        result(Int64(seconds * 1000))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    systemIdleChannel = channel

    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
