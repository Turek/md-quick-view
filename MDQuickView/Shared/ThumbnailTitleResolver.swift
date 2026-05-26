//
//  ThumbnailTitleResolver.swift
//  MDQuickView
//
//  Created by Turek on 26/05/2026.
//

import Foundation

// Resolves the best available display title for a Markdown file thumbnail.
// Walks the priority chain: front matter title → first Markdown heading → filename.
enum ThumbnailTitleResolver {

    // Maximum byte count read from a file before truncating.
    // Thumbnails need only enough text to extract a title from the header region.
    nonisolated private static let maximumReadSize = 16 * 1024

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
    nonisolated private static func readSource(from url: URL) -> String? {
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
    nonisolated private static func firstHeading(in body: String) -> String? {
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
