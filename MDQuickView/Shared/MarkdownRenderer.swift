//
//  MarkdownRenderer.swift
//  MDQuickView
//
//  Created by Turek on 26/05/2026.
//

import Foundation
import Markdown

// Renders a Markdown body into an HTML fragment using swift-markdown.
// Front matter is stripped upstream by FrontMatterParser before the body reaches here.
enum MarkdownRenderer {

    // Converts a Markdown body string into body-level HTML with no document wrapper.
    // swift-markdown parses against GitHub Flavored Markdown, so tables, task lists,
    // strikethrough, and autolinks are recognised without extra configuration.
    nonisolated static func renderHTMLFragment(from body: String) -> String {
        let document = Document(parsing: body)
        return HTMLFormatter.format(document)
    }
}
