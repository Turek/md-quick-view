import SwiftUI
import WebKit

// Base URL used when the document has no resolvable parent directory. Backed by a constant
// literal, so it is constructed once and cannot fail at the call site.
private let aboutBlankURL = URL(string: "about:blank")!

// Backing model for the preview, owning the single WebPage that renders the document.
// One instance is created per controller and never recreated, so the WebKit render pipeline is
// built once and stays warm; mode switching only changes view visibility, never this model.
@MainActor
@Observable
final class PreviewViewModel {

    // The page that renders the document HTML; bound to a permanently mounted WebView.
    let page: WebPage

    // The verbatim source shown by the raw view.
    private(set) var rawText: String = ""

    // Refuses every navigation except the programmatic content load.
    private let navigationGate = NavigationGate()

    init() {
        var configuration = WebPage.Configuration()

        // No script execution: this is a read-only preview and a hard requirement for App Review.
        configuration.defaultNavigationPreferences.allowsContentJavaScript = false

        page = WebPage(configuration: configuration, navigationDecider: navigationGate)
    }

    // Loads the document once. The parent directory is the base for best-effort relative image
    // resolution; the sandbox may deny that access, which is expected and not treated as an error.
    func present(html: String, baseURL: URL?, rawText: String) {
        self.rawText = rawText
        page.load(html: html, baseURL: baseURL ?? aboutBlankURL)
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
        // Permit only the local content load. Remote schemes and data:/blob: URIs are never needed
        // by the preview, so refusing them keeps the surface read-only as a matter of defence in depth.
        if let scheme = action.request.url?.scheme?.lowercased(),
           scheme == "http" || scheme == "https" || scheme == "data" || scheme == "blob" {
            return .cancel
        }
        return .allow
    }
}

// Bridges the AppKit raw source surface into SwiftUI so it can sit alongside the WebView.
struct RawSourceView: NSViewRepresentable {

    let text: String

    func makeNSView(context: Context) -> RawTextView {
        let view = RawTextView()
        view.display(text)
        return view
    }

    func updateNSView(_ nsView: RawTextView, context: Context) {
        if nsView.textView.string != text {
            nsView.display(text)
        }
    }
}
