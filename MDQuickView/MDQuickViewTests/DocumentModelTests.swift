//
//  DocumentModelTests.swift
//  MDQuickViewTests
//
//  Created by Turek on 26/05/2026.
//

import Testing
import Foundation
@testable import MDQuickView

// Verifies that a Markdown file is read, parsed, and rendered into one shared model.
struct DocumentModelTests {

    // Writes contents to a temporary .md file and returns its URL.
    private func makeTemporaryFile(_ contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("md")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test func loadsValidUTF8Markdown() async throws {
        let url = try makeTemporaryFile("# Title\n\nSome **bold** body text.\n")
        defer { try? FileManager.default.removeItem(at: url) }

        let model = try await MarkdownDocumentModel.load(from: url)

        #expect(model.sourceText.contains("# Title"))
        #expect(model.fileURL == url)
        #expect(model.markdownBody.contains("Some **bold** body text."))
    }

    @Test func populatesFrontMatterFields() async throws {
        let url = try makeTemporaryFile("""
        ---
        title: Hello
        tags: [a, b]
        ---
        Body line.
        """)
        defer { try? FileManager.default.removeItem(at: url) }

        let model = try await MarkdownDocumentModel.load(from: url)

        #expect(model.frontMatterFields.contains { $0.key == "title" && $0.value == "Hello" })
        #expect(model.frontMatterFields.contains { $0.key == "tags" && $0.value == "a, b" })
    }

    @Test func markdownBodyExcludesFrontMatterDelimiters() async throws {
        let url = try makeTemporaryFile("""
        ---
        title: Hello
        ---
        Body line.
        """)
        defer { try? FileManager.default.removeItem(at: url) }

        let model = try await MarkdownDocumentModel.load(from: url)

        #expect(!model.markdownBody.contains("---"))
        #expect(!model.markdownBody.contains("title: Hello"))
        #expect(model.markdownBody.contains("Body line."))
    }

    @Test func renderedHTMLIsNonEmptyForNonEmptyBody() async throws {
        let url = try makeTemporaryFile("# Heading\n\nParagraph.\n")
        defer { try? FileManager.default.removeItem(at: url) }

        let model = try await MarkdownDocumentModel.load(from: url)

        #expect(!model.renderedHTML.isEmpty)
        #expect(model.renderedHTML.contains("<h1"))
    }

    @Test func stripsLeadingByteOrderMark() async throws {
        let url = try makeTemporaryFile("\u{FEFF}# Title\n")
        defer { try? FileManager.default.removeItem(at: url) }

        let model = try await MarkdownDocumentModel.load(from: url)

        #expect(!model.sourceText.hasPrefix("\u{FEFF}"))
        #expect(model.sourceText.hasPrefix("# Title"))
    }

    @Test func rejectsFileAboveSizeLimit() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("md")
        try Data(count: 10 * 1024 * 1024 + 1).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        await #expect(throws: (any Error).self) {
            _ = try await MarkdownDocumentModel.load(from: url)
        }
    }

    @Test func loadingMissingFileThrows() async {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("md")

        await #expect(throws: (any Error).self) {
            _ = try await MarkdownDocumentModel.load(from: url)
        }
    }
}
