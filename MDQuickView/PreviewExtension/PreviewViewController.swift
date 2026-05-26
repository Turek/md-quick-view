//
//  PreviewViewController.swift
//  PreviewExtension
//

import Cocoa
import Quartz
import SwiftUI
import WebKit

// Quick Look preview controller for Markdown files.
// Hosts a single SwiftUI view whose rendered and raw surfaces are both mounted at all times, so
// the WebKit render pipeline is built once and stays resident. The document is parsed and loaded
// exactly once per file open; switching modes only toggles visibility.
@MainActor
final class PreviewViewController: NSViewController, QLPreviewingController {

    // Owns the single WebPage and the verbatim source; created once and never recreated.
    private let viewModel = PreviewViewModel()

    // Building the view programmatically; the template nib is unused.
    override var nibName: NSNib.Name? {
        nil
    }

    override func loadView() {
        let hosting = NSHostingView(rootView: PreviewRootView(viewModel: viewModel))
        hosting.autoresizingMask = [.width, .height]
        view = hosting
    }

    func preparePreviewOfFile(at url: URL) async throws {
        do {
            let model = try await MarkdownDocumentModel.load(from: url)

            // The parent directory is the base for best-effort relative image resolution.
            let baseURL = url.deletingLastPathComponent()

            viewModel.present(html: model.renderedHTML, baseURL: baseURL, rawText: model.sourceText)
        } catch {
            // A parse or read failure shows an inline message rather than surfacing Quick Look's
            // generic failure UI.
            let html = HTMLBuilder.errorDocument(
                message: "This Markdown file could not be previewed."
            )
            viewModel.present(html: html, baseURL: nil, rawText: "")
        }
    }
}

// The preview's root view: a segmented control above the two stacked surfaces.
// Both surfaces stay in the hierarchy at full size; the rendered WebView is kept topmost and
// merely turned transparent and non-interactive when Raw is selected, so WebKit never treats it
// as hidden or zero-sized and its process stays warm — making the switch immediate.
struct PreviewRootView: View {

    let viewModel: PreviewViewModel

    // Defaults to Preview, matching the required initial selection.
    @State private var mode: PreviewMode = .preview

    var body: some View {
        VStack(spacing: 8) {
            PreviewModeSelector(mode: $mode)
                .padding(.top, 8)

            ZStack {
                RawSourceView(text: viewModel.rawText)
                    .opacity(mode == .raw ? 1 : 0)
                    .accessibilityHidden(mode != .raw)

                WebView(viewModel.page)
                    .opacity(mode == .preview ? 1 : 0)
                    .allowsHitTesting(mode == .preview)
                    .accessibilityHidden(mode != .preview)
            }
        }
    }
}
