//
//  PreviewViewController.swift
//  PreviewExtension
//
//  Created by Turek on 26/05/2026.
//

import Cocoa
import Quartz
import SwiftUI

// Quick Look preview controller for Markdown files.
// Builds its view in code: a compact header carrying the native mode selector sits
// above a content area that holds all three mode surfaces at once. Switching modes
// only toggles visibility, so it never reparses or reloads the document.
@MainActor
final class PreviewViewController: NSViewController, QLPreviewingController {

    // Preview mode surface.
    private let previewWebView = PreviewWebView()

    // Raw mode surface.
    private let rawView = RawTextView()

    // Side-by-side surfaces, distinct instances sharing the same model data.
    private let sideRawView = RawTextView()
    private let sideWebView = PreviewWebView()
    private let splitView = NSSplitView()

    // Holds the three mode surfaces stacked on top of one another.
    private let contentContainer = NSView()

    // Ensures the split divider is centred once, after the view has a real width.
    private var hasCentredDivider = false

    // Building the view programmatically; the template nib is unused.
    override var nibName: NSNib.Name? {
        nil
    }

    override func loadView() {
        let container = NSView()

        let header = NSHostingView(
            rootView: PreviewModeSelector { [weak self] mode in
                self?.apply(mode)
            }
        )
        header.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(header)

        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(contentContainer)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            header.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            contentContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            contentContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        configureSplitView()
        installModeSurfaces()
        apply(.preview)

        view = container
    }

    // The smallest width either split pane may occupy, so neither can collapse to zero.
    private static let minimumPaneWidth: CGFloat = 80

    // Arranges the raw source (left) and rendered preview (right) in a native split view.
    private func configureSplitView() {
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = self
        splitView.addArrangedSubview(sideRawView)
        splitView.addArrangedSubview(sideWebView)
    }

    // Pins each mode surface to fill the content area; visibility selects the active one.
    private func installModeSurfaces() {
        for surface in [previewWebView, rawView, splitView] as [NSView] {
            surface.translatesAutoresizingMaskIntoConstraints = false
            contentContainer.addSubview(surface)
            NSLayoutConstraint.activate([
                surface.topAnchor.constraint(equalTo: contentContainer.topAnchor),
                surface.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
                surface.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
                surface.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
            ])
        }
    }

    // Shows the surface for the selected mode and hides the others.
    private func apply(_ mode: PreviewMode) {
        previewWebView.isHidden = mode != .preview
        rawView.isHidden = mode != .raw
        splitView.isHidden = mode != .sideBySide
    }

    // Centres the split divider once the content area has a non-zero width.
    override func viewDidLayout() {
        super.viewDidLayout()
        if !hasCentredDivider && splitView.bounds.width > 0 {
            splitView.setPosition(splitView.bounds.width / 2, ofDividerAt: 0)
            hasCentredDivider = true
        }
    }

    func preparePreviewOfFile(at url: URL) async throws {
        do {
            let model = try await MarkdownDocumentModel.load(from: url)

            // The parent directory is the base for best-effort relative image resolution.
            let baseURL = url.deletingLastPathComponent()

            // Every surface is populated once from the single parsed model, so switching
            // modes later toggles visibility without reparsing or reloading.
            previewWebView.loadDocument(model.renderedHTML, baseURL: baseURL)
            sideWebView.loadDocument(model.renderedHTML, baseURL: baseURL)
            rawView.display(model.sourceText)
            sideRawView.display(model.sourceText)
        } catch {
            // A parse or read failure shows an inline message rather than surfacing
            // Quick Look's generic failure UI.
            let html = HTMLBuilder.errorDocument(
                message: "This Markdown file could not be previewed."
            )
            previewWebView.loadDocument(html, baseURL: nil)
            sideWebView.loadDocument(html, baseURL: nil)

            // Clear the raw surfaces so a reused controller cannot show stale source
            // from a previous file alongside the error document.
            rawView.display("")
            sideRawView.display("")
        }
    }
}

extension PreviewViewController: NSSplitViewDelegate {

    // Keeps the left pane from collapsing below the minimum width.
    func splitView(
        _ splitView: NSSplitView,
        constrainMinCoordinate proposedMinimumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        max(proposedMinimumPosition, Self.minimumPaneWidth)
    }

    // Keeps the right pane from collapsing below the minimum width.
    func splitView(
        _ splitView: NSSplitView,
        constrainMaxCoordinate proposedMaximumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        min(proposedMaximumPosition, splitView.bounds.width - Self.minimumPaneWidth)
    }
}
