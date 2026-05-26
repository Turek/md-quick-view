//
//  ThumbnailProvider.swift
//  ThumbnailExtension
//
//  Created by Turek on 26/05/2026.
//

import QuickLookThumbnailing
import AppKit

// Generates Finder thumbnail images for Markdown files.
// The thumbnail shows the document title on a neutral background so the file is
// immediately identifiable at small icon sizes without being over-branded.
final class ThumbnailProvider: QLThumbnailProvider {

    // Carries the Quick Look completion handler across an actor boundary into the
    // detached task. The handler is not Sendable, but it is invoked exactly once and
    // never touched again here, so concurrent access cannot occur.
    private struct CompletionHandler: @unchecked Sendable {
        let call: (QLThumbnailReply?, Error?) -> Void
    }

    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        let fileURL = request.fileURL
        let size = request.maximumSize
        let completion = CompletionHandler(call: handler)

        // Quick Look is routinely invoked on files living on SMB shares, iCloud Drive,
        // and similar volumes, where a cold read can stall for hundreds of milliseconds.
        // Resolve the title and build the reply off the calling thread, then complete
        // through the escaping handler rather than blocking it synchronously.
        Task.detached(priority: .userInitiated) {
            let title = ThumbnailTitleResolver.resolveTitle(for: fileURL)

            let reply = QLThumbnailReply(contextSize: size, currentContextDrawing: {
                // QLThumbnailReply provides a CG context with a bottom-left origin.
                // NSAttributedString layout assumes a flipped (top-left) context, so
                // install one explicitly before drawing.
                guard let cg = NSGraphicsContext.current?.cgContext else { return false }
                let flipped = NSGraphicsContext(cgContext: cg, flipped: true)
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = flipped
                defer { NSGraphicsContext.restoreGraphicsState() }
                ThumbnailRenderer.draw(title: title, in: CGRect(origin: .zero, size: size))
                return true
            })

            completion.call(reply, nil)
        }
    }
}

// Resolves the best available display title for a Markdown file thumbnail.
// Walks the priority chain: front matter title → first Markdown heading → filename.
enum ThumbnailTitleResolver {

    // Maximum byte count read from a file before truncating.
    // Thumbnails need only enough text to extract a title from the header region.
    private static let maximumReadSize = 16 * 1024

    // Reads the file at the given URL and returns the best available title string.
    nonisolated static func resolveTitle(for url: URL) -> String {
        let source = readSource(from: url)

        if let source {
            // Front matter title takes highest priority.
            let parsed = FrontMatterParser.parse(source)

            if let titleField = parsed.fields.first(where: { $0.key == "title" }) {
                let value = titleField.value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    return value
                }
            }

            // First Markdown heading is the second priority.
            if let heading = firstHeading(in: parsed.body) {
                return heading
            }
        }

        // Filename without extension is the guaranteed fallback.
        return url.deletingPathExtension().lastPathComponent
    }

    // Reads up to maximumReadSize bytes from the file and decodes as UTF-8.
    // Invalid bytes at a truncation boundary are replaced with U+FFFD, preserving
    // the intact head where the title is located. Strips any leading BOM.
    private static func readSource(from url: URL) -> String? {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            return nil
        }

        let slice = data.count > maximumReadSize ? data.prefix(maximumReadSize) : data
        let raw = String(decoding: slice, as: UTF8.self)

        // Strip a leading byte order mark so it never appears in the extracted title.
        return raw.hasPrefix("\u{FEFF}") ? String(raw.dropFirst()) : raw
    }

    // Scans the Markdown body for the first ATX heading line (leading `#` characters).
    // Returns the trimmed heading text, or nil when none is found.
    // Note: setext-style headings (text underlined with === or ---) are not detected.
    private static func firstHeading(in body: String) -> String? {
        for line in body.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("#") else { continue }

            // Strip the leading # characters and any surrounding whitespace.
            let text = trimmed
                .drop(while: { $0 == "#" })
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !text.isEmpty {
                return text
            }
        }
        return nil
    }
}

// Geometric constants derived from a thumbnail rectangle.
// Computed once and passed to all draw helpers so padding and font sizes
// remain consistent and cannot drift between the title and badge areas.
private struct ThumbnailMetrics {
    let hPad: CGFloat
    let vPad: CGFloat
    let fontSize: CGFloat
    let badgeFontSize: CGFloat
    let contentRect: CGRect
    // Title occupies the top portion of contentRect, leaving room for the badge.
    let titleRect: CGRect
    // Badge sits at the bottom of contentRect.
    let badgeRect: CGRect

    // Vertical padding as a fraction of the thumbnail height.
    private static let verticalPaddingRatio: CGFloat = 0.10
    // Horizontal padding as a fraction of the thumbnail width.
    private static let horizontalPaddingRatio: CGFloat = 0.10
    // Title font size as a fraction of the shorter thumbnail dimension.
    private static let fontSizeRatio: CGFloat = 0.14
    // Maximum title font size cap so large request sizes do not produce enormous text.
    private static let maximumFontSize: CGFloat = 32
    // Minimum title font size so the title remains legible at tiny icon sizes.
    private static let minimumFontSize: CGFloat = 8
    // Badge font size as a fraction of the title font size.
    private static let badgeFontRatio: CGFloat = 0.55

    init(rect: CGRect) {
        hPad = rect.width * Self.horizontalPaddingRatio
        vPad = rect.height * Self.verticalPaddingRatio
        contentRect = rect.insetBy(dx: hPad, dy: vPad)

        let baseDimension = min(rect.width, rect.height)
        let rawFontSize = baseDimension * Self.fontSizeRatio
        fontSize = max(Self.minimumFontSize, min(Self.maximumFontSize, rawFontSize))
        badgeFontSize = max(Self.minimumFontSize, fontSize * Self.badgeFontRatio)

        // Badge band height reserves space at the bottom of contentRect.
        let badgeBandHeight = badgeFontSize + 4

        // In a flipped (top-left) context, minY is the top edge.
        // Title band starts at the top of contentRect and ends above the badge band.
        titleRect = CGRect(
            x: contentRect.minX,
            y: contentRect.minY,
            width: contentRect.width,
            height: contentRect.height - badgeBandHeight - vPad
        )

        // Badge band occupies the bottom of contentRect.
        badgeRect = CGRect(
            x: contentRect.minX,
            y: contentRect.maxY - badgeBandHeight,
            width: contentRect.width,
            height: badgeBandHeight
        )
    }
}

// Draws a thumbnail into the current AppKit graphics context.
// The caller must ensure a flipped (top-left origin) NSGraphicsContext is current.
enum ThumbnailRenderer {

    // Fills the given rectangle with the background and draws the title and badge.
    // Expects a flipped NSGraphicsContext to be current so NSAttributedString
    // layout proceeds top-down without manual transform adjustments.
    nonisolated static func draw(title: String, in rect: CGRect) {
        let metrics = ThumbnailMetrics(rect: rect)
        drawBackground(in: rect)
        drawTitle(title, metrics: metrics)
        drawBadge(metrics: metrics)
    }

    // Fills the rectangle with the system window background colour.
    // Semantic colours resolve against NSAppearance.current, which the Quick Look
    // system sets to match the Finder appearance, so the thumbnail follows dark mode.
    private static func drawBackground(in rect: CGRect) {
        NSColor.windowBackgroundColor.setFill()
        NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.04, yRadius: rect.width * 0.04).fill()
    }

    // Draws the title string in the top portion of the thumbnail, wrapping across
    // up to several lines and truncating with an ellipsis.
    private static func drawTitle(_ title: String, metrics: ThumbnailMetrics) {
        let font = NSFont.systemFont(ofSize: metrics.fontSize, weight: .semibold)
        let textColor = NSColor.labelColor

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        let attributed = NSAttributedString(string: title, attributes: attributes)
        attributed.draw(with: metrics.titleRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
    }

    // Draws a subtle ".md" badge at the bottom of the thumbnail.
    private static func drawBadge(metrics: ThumbnailMetrics) {
        let font = NSFont.monospacedSystemFont(ofSize: metrics.badgeFontSize, weight: .regular)
        let badgeColor = NSColor.secondaryLabelColor

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byClipping
        paragraphStyle.alignment = .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: badgeColor,
            .paragraphStyle: paragraphStyle
        ]

        let attributed = NSAttributedString(string: ".md", attributes: attributes)
        attributed.draw(with: metrics.badgeRect, options: [.usesLineFragmentOrigin])
    }
}
