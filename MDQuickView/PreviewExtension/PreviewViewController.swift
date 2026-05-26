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
class PreviewViewController: NSViewController, QLPreviewingController {

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

    // Installs the web view as the controller's view.
    override func loadView() {
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
}
