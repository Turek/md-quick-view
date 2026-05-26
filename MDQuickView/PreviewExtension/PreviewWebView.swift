import SwiftUI
import WebKit

// A read-only preview surface backed by the native SwiftUI WebView and WebPage.
// JavaScript is disabled and every navigation except the programmatic content load is refused,
// so a link click cannot carry the preview to arbitrary, network-backed content. The SwiftUI
// WebView is hosted inside an NSView so the AppKit preview controller can place it among its
// other mode surfaces. Used for both Preview mode and the rendered pane of Side-by-side mode.
@MainActor
final class PreviewWebView: NSView {

    // The page model that backs the hosted WebView; document HTML is loaded into it directly.
    private let page: WebPage

    // Refuses every navigation except the programmatic content load.
    private let navigationGate = NavigationGate()

    init() {
        var configuration = WebPage.Configuration()

        // No script execution: this is a read-only preview and a hard requirement for App Review.
        configuration.defaultNavigationPreferences.allowsContentJavaScript = false

        page = WebPage(configuration: configuration, navigationDecider: navigationGate)

        super.init(frame: .zero)
        autoresizingMask = [.width, .height]

        let host = NSHostingView(rootView: WebView(page))
        host.translatesAutoresizingMaskIntoConstraints = false
        addSubview(host)
        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: topAnchor),
            host.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.trailingAnchor.constraint(equalTo: trailingAnchor),
            host.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }

    // Loads the self-contained document HTML.
    // The parent directory is the base for best-effort relative image resolution; the sandbox
    // may deny that access, which is expected and not treated as an error.
    func loadDocument(_ html: String, baseURL: URL?) {
        page.load(html: html, baseURL: baseURL ?? URL(string: "about:blank")!)
    }
}

// Allows only the navigations the preview itself initiates and refuses link activations and any
// remote navigation, keeping the preview read-only and free of network-backed content.
@MainActor
private final class NavigationGate: WebPage.NavigationDeciding {

    func decidePolicy(
        for action: WebPage.NavigationAction,
        preferences: inout WebPage.NavigationPreferences
    ) async -> WKNavigationActionPolicy {
        // Reaffirm the no-JavaScript policy for every navigation.
        preferences.allowsContentJavaScript = false

        if action.navigationType == .linkActivated {
            return .cancel
        }
        if let scheme = action.request.url?.scheme?.lowercased(), scheme == "http" || scheme == "https" {
            return .cancel
        }
        return .allow
    }
}
