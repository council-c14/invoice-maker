import UIKit
import WebKit
import WidgetKit

/// Runs public/index.html from the app bundle. Records stay in this app's WebKit storage on the device;
/// nothing is sent anywhere. The page talks to the app through window.NativeBridge (see `shim`).
final class WebController: NSObject, ObservableObject, WKScriptMessageHandler, WKUIDelegate {
  static let appGroup = "group.app.invoicemaker"
  let view: WKWebView

  // Same methods as the Android app's bridge, so the page treats both apps alike.
  private static let shim = """
  (function () {
    const post = (m, a) => window.webkit.messageHandlers.native.postMessage({ m: m, a: a });
    window.NativeBridge = {
      print: t => post('print', [String(t)]),
      saveFile: (n, m, t) => post('saveFile', [String(n), String(m), String(t)]),
      haptic: k => post('haptic', [String(k)]),
      setDark: d => post('setDark', [d ? '1' : '0']),
      updateWidget: (...a) => post('updateWidget', a.map(String)),
    };
  })();
  """

  private static let background = UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? UIColor(red: 0.071, green: 0.071, blue: 0.067, alpha: 1)
      : UIColor(red: 0.961, green: 0.961, blue: 0.949, alpha: 1)
  }

  override init() {
    let config = WKWebViewConfiguration()
    config.userContentController.addUserScript(
      WKUserScript(source: Self.shim, injectionTime: .atDocumentStart, forMainFrameOnly: true))
    view = WKWebView(frame: .zero, configuration: config)
    super.init()
    // ponytail: the content controller keeps this handler alive; fine, the controller lives as long as the app.
    view.configuration.userContentController.add(self, name: "native")
    view.uiDelegate = self
    view.isOpaque = false
    view.backgroundColor = Self.background
    view.scrollView.backgroundColor = Self.background
    view.scrollView.contentInsetAdjustmentBehavior = .never
    load(route: "")
  }

  private func load(route: String) {
    guard let index = Bundle.main.url(forResource: "index", withExtension: "html"),
          var parts = URLComponents(url: index, resolvingAgainstBaseURL: false) else { return }
    parts.fragment = "/" + route
    view.loadFileURL(parts.url ?? index, allowingReadAccessTo: index.deletingLastPathComponent())
  }

  /// Widget links: invoicemaker://open/new/invoice -> #/new/invoice. Only plain paths are accepted.
  func open(_ url: URL) {
    guard url.scheme == "invoicemaker" else { return }
    let path = url.path.hasPrefix("/") ? String(url.path.dropFirst()) : url.path
    guard path.range(of: "^[a-z/]{0,40}$", options: .regularExpression) != nil else { return }
    if view.isLoading || view.url == nil {
      load(route: path)
    } else {
      view.evaluateJavaScript("location.hash = '#/\(path)'", completionHandler: nil)
    }
  }

  // MARK: - Messages from the page

  func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
    guard let body = message.body as? [String: Any], let method = body["m"] as? String else { return }
    let args = (body["a"] as? [Any])?.map { "\($0)" } ?? []
    func arg(_ i: Int) -> String { i < args.count ? args[i] : "" }
    switch method {
    case "print": printPage(title: arg(0))
    case "saveFile": share(name: arg(0), text: arg(2))
    case "haptic": haptic(arg(0))
    case "updateWidget": updateWidget(args)
    default: break // setDark: the status bar follows the system appearance
    }
  }

  /// AirPrint, or Save to Files as PDF from the same sheet. Uses the page's print styles.
  private func printPage(title: String) {
    let info = UIPrintInfo(dictionary: nil)
    info.jobName = title
    info.outputType = .general
    let printer = UIPrintInteractionController.shared
    printer.printInfo = info
    printer.printFormatter = view.viewPrintFormatter()
    _ = printer.present(animated: true, completionHandler: nil)
  }

  /// CSV and backup files go to the share sheet (Save to Files, Mail, AirDrop).
  private func share(name: String, text: String) {
    let safe = name.replacingOccurrences(of: "/", with: "-")
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(safe.isEmpty ? "export.txt" : safe)
    do { try text.write(to: url, atomically: true, encoding: .utf8) } catch { return }
    let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    sheet.popoverPresentationController?.sourceView = view // iPad shows it as a popover
    sheet.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
    topController()?.present(sheet, animated: true)
  }

  private func haptic(_ kind: String) {
    switch kind {
    case "confirm": UINotificationFeedbackGenerator().notificationOccurred(.success)
    case "reject": UINotificationFeedbackGenerator().notificationOccurred(.error)
    default: UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
  }

  /// The page's summary for the home-screen widget (shared through the app group), sent after every save.
  private func updateWidget(_ values: [String]) {
    guard values.count >= 5, let shared = UserDefaults(suiteName: Self.appGroup) else { return }
    for (key, value) in zip(["cur", "open", "collected", "month", "synced"], values) { shared.set(value, forKey: key) }
    WidgetCenter.shared.reloadAllTimelines()
  }

  private func topController() -> UIViewController? {
    var top = view.window?.rootViewController
    while let next = top?.presentedViewController { top = next }
    return top
  }

  // MARK: - confirm() for "leave without saving?"

  func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
               initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
    guard let top = topController() else { return completionHandler(false) }
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Stay", style: .cancel) { _ in completionHandler(false) })
    alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in completionHandler(true) })
    top.present(alert, animated: true)
  }
}
