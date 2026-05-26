//
//  HTMLBuilder.swift
//  MDQuickView
//
//  Created by Turek on 26/05/2026.
//

import Foundation

// Assembles a self-contained HTML document from a rendered Markdown fragment and front matter.
// The wrapper itself adds no scripts and references no network resources, but the embedded
// fragment is untrusted: swift-markdown passes raw HTML in the source through verbatim, so the
// body may contain arbitrary markup. The Content-Security-Policy below is the defence-in-depth
// boundary; the consuming WebKit view must also be configured with JavaScript disabled.
enum HTMLBuilder {

    // An ordered front matter entry shown in the metadata table.
    typealias Field = (key: String, value: String)

    // Wraps the body fragment in a full document with inlined CSS and a UTF-8 charset.
    // When front matter is present it is rendered as a table above the body; otherwise the
    // table is omitted entirely.
    nonisolated static func buildDocument(fragment: String, frontMatter: [Field]) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="color-scheme" content="light dark">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data: file: https:; style-src 'unsafe-inline'; font-src *;">
        <style>
        \(Theme.css)
        </style>
        </head>
        <body>
        \(frontMatterTable(frontMatter))<main class="markdown-body">
        \(fragment)</main>
        </body>
        </html>
        """
    }

    // Builds the front matter table, returning an empty string when there are no fields.
    nonisolated private static func frontMatterTable(_ fields: [Field]) -> String {
        guard !fields.isEmpty else { return "" }

        let rows = fields.map { field in
            "<tr><th scope=\"row\">\(escape(field.key))</th><td>\(escape(field.value))</td></tr>"
        }.joined(separator: "\n")

        return """
        <table class="front-matter">
        <caption class="visually-hidden">Document front matter</caption>
        <tbody>
        \(rows)
        </tbody>
        </table>
        """ + "\n"
    }

    // Builds a minimal self-contained page shown when a file cannot be previewed.
    // The message is escaped because it may include a system error description.
    nonisolated static func errorDocument(message: String) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="color-scheme" content="light dark">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline';">
        <style>
        :root { color-scheme: light dark; }
        body {
            font: -apple-system-body;
            margin: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            color: GrayText;
        }
        p { margin: 2rem; text-align: center; }
        </style>
        </head>
        <body>
        <p>\(escape(message))</p>
        </body>
        </html>
        """
    }

    // Escapes characters that would otherwise be interpreted as HTML markup.
    // Front matter values are plain text and must never inject markup into the document.
    nonisolated private static func escape(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.count)
        for character in text {
            switch character {
            case "&": result += "&amp;"
            case "<": result += "&lt;"
            case ">": result += "&gt;"
            case "\"": result += "&quot;"
            case "'": result += "&#39;"
            default: result.append(character)
            }
        }
        return result
    }
}
