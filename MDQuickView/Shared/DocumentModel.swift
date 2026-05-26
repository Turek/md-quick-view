//
//  DocumentModel.swift
//  MDQuickView
//
//  Created by Turek on 26/05/2026.
//

import Foundation

// The single parsed representation of a Markdown file.
// One instance is produced per file open and shared by all three preview modes,
// so the source is read and parsed exactly once.
nonisolated struct MarkdownDocumentModel: Sendable {

    // The original file contents, preserved verbatim for the Raw viewing mode.
    let sourceText: String

    // Ordered front matter entries, empty when the file has no valid block.
    let frontMatterFields: [(key: String, value: String)]

    // The Markdown body with any front matter block stripped.
    let markdownBody: String

    // The fully assembled, self-contained HTML document for the rendered mode.
    let renderedHTML: String

    // The location the model was loaded from.
    let fileURL: URL

    // Reads, parses, and renders a Markdown file into a complete model.
    // UTF-8 is attempted first; files that are not valid UTF-8 fall back to Latin-1,
    // which maps every byte and so cannot itself fail to decode.
    static func load(from url: URL) throws -> MarkdownDocumentModel {
        let data = try Data(contentsOf: url)

        let source: String
        if let utf8 = String(data: data, encoding: .utf8) {
            source = utf8
        } else if let latin1 = String(data: data, encoding: .isoLatin1) {
            source = latin1
        } else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }

        let parsed = FrontMatterParser.parse(source)
        let fragment = MarkdownRenderer.renderHTMLFragment(from: parsed.body)
        let html = HTMLBuilder.buildDocument(fragment: fragment, frontMatter: parsed.fields)

        return MarkdownDocumentModel(
            sourceText: source,
            frontMatterFields: parsed.fields,
            markdownBody: parsed.body,
            renderedHTML: html,
            fileURL: url
        )
    }
}
