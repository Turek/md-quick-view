//
//  PreviewViewController.swift
//  PreviewExtension
//
//  Created by Turek on 26/05/2026.
//

import Cocoa
import Quartz
import WebKit

// Quick Look preview controller for Markdown files.
// Builds its view in code rather than from the template nib: the entire surface is a
// WKWebView that renders the document model's self-contained HTML.
@MainActor
final class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate {

    // Tracks whether the single programmatic content load has happened, so the navigation
    // policy can allow it once and refuse every navigation that follows.
    private var hasLoadedContent = false

    // The web view that renders the document model's HTML.
    // Initialised at declaration so the configuration and JavaScript-disabled state are
    // set once; loadView only needs to install it as the controller's view.
    private let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()

        // No script execution: this is a read-only preview and a hard requirement for
        // App Review. allowsContentJavaScript is the supported control on macOS 15.
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.autoresizingMask = [.width, .height]
        return webView
    }()

    // Building the view programmatically; the template nib is unused.
    override var nibName: NSNib.Name? {
        nil
    }

    // Installs the web view as the controller's view and takes over its navigation policy.
    override func loadView() {
        webView.navigationDelegate = self
        view = webView
    }

    func preparePreviewOfFile(at url: URL) async throws {
        do {
            let model = try await MarkdownDocumentModel.load(from: url)

            // The parent directory is the base for best-effort relative image resolution.
            // The sandbox may deny this access; that is expected and not treated as an error.
            let baseURL = url.deletingLastPathComponent()
            webView.loadHTMLString(model.renderedHTML, baseURL: baseURL)
        } catch {
            // A parse or read failure shows an inline message rather than surfacing
            // Quick Look's generic failure UI.
            let html = HTMLBuilder.errorDocument(
                message: "This Markdown file could not be previewed."
            )
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    // Allows only the initial programmatic content load and cancels everything else.
    // CSP restricts subresource loading but not top-level navigation, so without this a
    // link click would carry the read-only preview to arbitrary, network-backed content.
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
