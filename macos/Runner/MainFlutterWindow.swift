import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var securityScopedUrls: [String: URL] = [:]

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerSecurityScopedBookmarkChannel(flutterViewController)

    super.awakeFromNib()
  }

  private func registerSecurityScopedBookmarkChannel(_ flutterViewController: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "io.github.normalllll.yandegui/security_scoped_bookmark",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "window_unavailable", message: "Window is unavailable.", details: nil))
        return
      }

      switch call.method {
      case "pickDirectory":
        self.pickDirectory(result)
      case "startAccessing":
        guard
          let args = call.arguments as? [String: Any],
          let bookmark = args["bookmark"] as? String
        else {
          result(FlutterError(code: "bad_args", message: "Missing bookmark.", details: nil))
          return
        }
        self.startAccessing(bookmark, result)
      case "stopAccessing":
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(FlutterError(code: "bad_args", message: "Missing path.", details: nil))
          return
        }
        self.stopAccessing(path)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func pickDirectory(_ result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = true

    panel.beginSheetModal(for: self) { response in
      guard response == .OK, let url = panel.url else {
        result(nil)
        return
      }

      do {
        let data = try url.bookmarkData(
          options: [.withSecurityScope],
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
        result([
          "path": url.path,
          "bookmark": data.base64EncodedString(),
        ])
      } catch {
        result(FlutterError(code: "bookmark_failed", message: error.localizedDescription, details: nil))
      }
    }
  }

  private func startAccessing(_ bookmark: String, _ result: FlutterResult) {
    guard let data = Data(base64Encoded: bookmark) else {
      result(FlutterError(code: "bad_bookmark", message: "Bookmark data is invalid.", details: nil))
      return
    }

    do {
      var isStale = false
      let url = try URL(
        resolvingBookmarkData: data,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      guard url.startAccessingSecurityScopedResource() else {
        result(FlutterError(code: "access_denied", message: "Unable to access selected directory.", details: nil))
        return
      }

      securityScopedUrls[url.path] = url
      result([
        "path": url.path,
        "isStale": isStale,
      ])
    } catch {
      result(FlutterError(code: "bookmark_resolve_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func stopAccessing(_ path: String) {
    guard let url = securityScopedUrls.removeValue(forKey: path) else {
      return
    }
    url.stopAccessingSecurityScopedResource()
  }
}
