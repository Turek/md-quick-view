//
//  PreviewViewController.swift
//  PreviewExtension
//

import Cocoa
import Quartz
import SwiftUI

// Quick Look preview controller for Markdown files.
// Builds its view in code: a compact header carrying the native mode selector sits above a
// single split view whose left pane is the raw source and whose right pane is the rendered
// document. The three modes are expressed purely as divider positions — raw collapsed for
// Preview, centred for Side-by-side, rendered collapsed for Raw — so there is exactly one
// rendered web view and exactly one raw view. Switching between Preview and Side-by-side never
// collapses the rendered pane, so its web content stays foreground and the switch is immediate.
@MainActor
final class PreviewViewController: NSViewController, QLPreviewingController {

    // The raw source surface; occupies the left split pane.
    private let rawView = RawTextView()

    // The rendered surface; occupies the right split pane.
    private let webView = PreviewWebView()

    // Hosts the two panes; the divider position alone selects the active mode.
    private let splitView = NSSplitView()

    // The mode currently shown, so layout can restore its divider position.
    private var currentMode: PreviewMode = .preview

    // Set once the split view has a real width, after which divider moves are meaningful.
    private var hasLaidOut = false

    // The smallest width either pane may occupy while dragging in Side-by-side mode.
    private static let minimumPaneWidth: CGFloat = 80

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

        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = self
        splitView.addArrangedSubview(rawView)
        splitView.addArrangedSubview(webView)
        splitView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(splitView)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            header.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            splitView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            splitView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            splitView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        view = container
    }

    // Positions the divider for the initial mode once the split view has a real width.
    override func viewDidLayout() {
        super.viewDidLayout()
        if !hasLaidOut && splitView.bounds.width > 0 {
            hasLaidOut = true
            applyDividerPosition(for: currentMode)
        }
    }

    // Records the selected mode and moves the divider to express it.
    private func apply(_ mode: PreviewMode) {
        currentMode = mode
        rawView.setAccessibilityHidden(mode == .preview)
        webView.setAccessibilityHidden(mode == .raw)
        if hasLaidOut {
            applyDividerPosition(for: mode)
        }
    }

    // Collapses the pane the mode does not need; centres the divider for Side-by-side.
    private func applyDividerPosition(for mode: PreviewMode) {
        let width = splitView.bounds.width
        guard width > 0 else { return }
        switch mode {
        case .preview:
            splitView.setPosition(0, ofDividerAt: 0)
        case .raw:
            splitView.setPosition(width, ofDividerAt: 0)
        case .sideBySide:
            splitView.setPosition(width / 2, ofDividerAt: 0)
        }
    }

    func preparePreviewOfFile(at url: URL) async throws {
        do {
            let model = try await MarkdownDocumentModel.load(from: url)

            // The parent directory is the base for best-effort relative image resolution.
            let baseURL = url.deletingLastPathComponent()

            // Both panes are populated once from the single parsed model, so switching modes
            // later only moves the divider and never reparses or reloads the document.
            webView.loadDocument(model.renderedHTML, baseURL: baseURL)
            rawView.display(model.sourceText)
        } catch {
            // A parse or read failure shows an inline message rather than surfacing Quick
            // Look's generic failure UI.
            let html = HTMLBuilder.errorDocument(
                message: "This Markdown file could not be previewed."
            )
            webView.loadDocument(html, baseURL: nil)

            // Clear the raw surface so a reused controller cannot show stale source from a
            // previous file alongside the error document.
            rawView.display("")
        }
    }
}

extension PreviewViewController: NSSplitViewDelegate {

    // Lets Preview and Raw fully collapse the pane they do not use.
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        true
    }

    // Keeps the left pane usable while dragging in Side-by-side; allows full collapse otherwise.
    func splitView(
        _ splitView: NSSplitView,
        constrainMinCoordinate proposedMinimumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        currentMode == .sideBySide
            ? max(proposedMinimumPosition, Self.minimumPaneWidth)
            : proposedMinimumPosition
    }

    // Keeps the right pane usable while dragging in Side-by-side; allows full collapse otherwise.
    func splitView(
        _ splitView: NSSplitView,
        constrainMaxCoordinate proposedMaximumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        currentMode == .sideBySide
            ? min(proposedMaximumPosition, splitView.bounds.width - Self.minimumPaneWidth)
            : proposedMaximumPosition
    }
}
