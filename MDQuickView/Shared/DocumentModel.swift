//
//  DocumentModel.swift
//  MDQuickView
//
//  Created by Turek on 26/05/2026.
//

import Foundation

// A single ordered front matter entry.
// Identity is the key, which lets the metadata table be rendered directly in a SwiftUI list.
nonisolated struct FrontMatterField: Sendable, Identifiable, Equatable {
    let key: String
    let value: String

    var id: String { key }
}

// The single parsed representation of a Markdown file.
// One instance is produced per file open and shared by all three preview modes,
// so the source is read and parsed exactly once.
nonisolated struct MarkdownDocumentModel: Sendable, Equatable {

    // The original file contents, preserved verbatim for the Raw viewing mode.
    let sourceText: String

    // Ordered front matter entries, empty when the file has no valid block.
    let frontMatterFields: [FrontMatterField]

    // The Markdown body with any front matter block stripped.
    let markdownBody: String

    // The fully assembled, self-contained HTML document for the rendered mode.
    let renderedHTML: String

    // The location the model was loaded from.
    let fileURL: URL

    // Upper bound, in bytes, on the file this preview will load.
    // The extension runs with a constrained memory budget and the model holds the source,
    // the body, and the rendered HTML at once, so an unbounded read risks terminating the
    // process. Files above this limit are rejected rather than previewed partially.
    private static let maximumFileSize = 10 * 1024 * 1024

    // Reads, parses, and renders a Markdown file into a complete model.
    // Declared async and nonisolated so that callers on the main actor await it and the
    // blocking file read runs on the cooperative thread pool, never stalling the UI thread.
    static func load(from url: URL) async throws -> MarkdownDocumentModel {
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= maximumFileSize else {
            throw CocoaError(.fileReadTooLarge)
        }

        let data = try Data(contentsOf: url, options: .mappedIfSafe)

        // UTF-8 is attempted first; files that are not valid UTF-8 fall back to Latin-1,
        // which maps every byte and so always succeeds. The deliberate consequence is that
        // a file in another encoding such as UTF-16 renders as garbled text rather than
        // failing to load, which matches the read-only, best-effort scope of v1.
        let source: String
        if let utf8 = String(data: data, encoding: .utf8) {
            source = utf8
        } else if let latin1 = String(data: data, encoding: .isoLatin1) {
            source = latin1
        } else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }

        // A leading byte order mark would otherwise survive into the raw view and the body.
        let normalisedSource = source.hasPrefix("\u{FEFF}") ? String(source.dropFirst()) : source

        let parsed = FrontMatterParser.parse(normalisedSource)
        let fields = parsed.fields.map { FrontMatterField(key: $0.key, value: $0.value) }
        let fragment = MarkdownRenderer.renderHTMLFragment(from: parsed.body)
        let html = HTMLBuilder.buildDocument(fragment: fragment, frontMatter: parsed.fields)

        return MarkdownDocumentModel(
            sourceText: normalisedSource,
            frontMatterFields: fields,
            markdownBody: parsed.body,
            renderedHTML: html,
            fileURL: url
        )
    }
}
