import WebKit

// A WKWebView preconfigured for the read-only preview.
// JavaScript is disabled and every navigation is blocked except the single
// programmatic content load, so a link click cannot carry the preview to
// arbitrary, network-backed content. Used for both Preview mode and the rendered
// pane of Side-by-side mode.
@MainActor
final class PreviewWebView: WKWebView, WKNavigationDelegate {

    // Tracks whether the single programmatic content load has happened, so the
    // navigation policy can allow it once and refuse every navigation that follows.
    private var hasLoadedContent = false

    init() {
        let configuration = WKWebViewConfiguration()

        // No script execution: this is a read-only preview and a hard requirement for
        // App Review. allowsContentJavaScript is the supported control on macOS 15.
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false

        super.init(frame: .zero, configuration: configuration)
        navigationDelegate = self
        autoresizingMask = [.width, .height]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }

    // Loads the self-contained document HTML once.
    // The parent directory is the base for best-effort relative image resolution;
    // the sandbox may deny that access, which is expected and not treated as an error.
    func loadDocument(_ html: String, baseURL: URL?) {
        // Reset so the navigation policy permits this load; a reused controller may
        // load a second document into the same web view.
        hasLoadedContent = false
        loadHTMLString(html, baseURL: baseURL)
    }

    // Allows only the initial programmatic content load and cancels everything else.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        if navigationAction.navigationType == .other && !hasLoadedContent {
            hasLoadedContent = true
            return .allow
        }
        return .cancel
    }
}
