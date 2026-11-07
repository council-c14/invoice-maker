import SwiftUI
import WebKit

@main
struct InvoiceMakerApp: App {
  @StateObject private var web = WebController()

  var body: some Scene {
    WindowGroup {
      WebView(controller: web)
        .ignoresSafeArea() // the page pads itself for the notch and home indicator
        .onOpenURL { web.open($0) }
    }
  }
}

struct WebView: UIViewRepresentable {
  let controller: WebController
  func makeUIView(context: Context) -> WKWebView { controller.view }
  func updateUIView(_ view: WKWebView, context: Context) {}
}
