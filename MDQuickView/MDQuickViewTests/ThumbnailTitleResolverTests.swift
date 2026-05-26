//
//  ThumbnailTitleResolverTests.swift
//  MDQuickViewTests
//
//  Created by Turek on 26/05/2026.
//

import Foundation
import Testing
@testable import MDQuickView

struct ThumbnailTitleResolverTests {

    // A resolution scenario: file contents plus the filename that backs it,
    // and the title expected from the priority chain.
    struct ResolutionCase: Sendable {
        let name: String
        let fileName: String
        let contents: String
        let expected: String
    }

    // Writes the contents to a uniquely scoped temporary file with the given name
    // and returns its URL. The directory is removed when the returned token deinits.
    private static func makeFile(name: String, contents: String) throws -> (url: URL, cleanup: () -> Void) {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ThumbnailTitleResolverTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(name)
        try Data(contents.utf8).write(to: url)
        return (url, { try? FileManager.default.removeItem(at: dir) })
    }

    @Test(arguments: [
        ResolutionCase(
            name: "front matter title wins over heading",
            fileName: "notes.md",
            contents: "---\ntitle: From Front Matter\n---\n# A Heading\n",
            expected: "From Front Matter"
        ),
        ResolutionCase(
            name: "first ATX heading used when no front matter title",
            fileName: "notes.md",
            contents: "# The Heading\n\nbody text\n",
            expected: "The Heading"
        ),
        ResolutionCase(
            name: "deeper ATX heading is stripped of all hashes",
            fileName: "notes.md",
            contents: "###   Spaced Heading\n",
            expected: "Spaced Heading"
        ),
        ResolutionCase(
            name: "heading that collapses to empty falls through to filename",
            fileName: "my-doc.md",
            contents: "###\n\nbody\n",
            expected: "my-doc"
        ),
        ResolutionCase(
            name: "empty front matter title falls through to heading",
            fileName: "notes.md",
            contents: "---\ntitle:   \n---\n# Real Heading\n",
            expected: "Real Heading"
        ),
        ResolutionCase(
            name: "leading BOM does not block front matter detection",
            fileName: "notes.md",
            contents: "\u{FEFF}---\ntitle: BOM Title\n---\n# Heading\n",
            expected: "BOM Title"
        ),
        ResolutionCase(
            name: "no title or heading falls back to filename without extension",
            fileName: "Plain File.md",
            contents: "just some prose with no heading\n",
            expected: "Plain File"
        )
    ])
    func resolvesTitle(_ testCase: ResolutionCase) throws {
        let file = try Self.makeFile(name: testCase.fileName, contents: testCase.contents)
        defer { file.cleanup() }

        let title = ThumbnailTitleResolver.resolveTitle(for: file.url)
        #expect(title == testCase.expected, "\(testCase.name): got \"\(title)\"")
    }

    @Test
    func unreadableFileFallsBackToFilename() {
        let missing = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("does-not-exist-\(UUID().uuidString)")
            .appendingPathComponent("Ghost.md")

        #expect(ThumbnailTitleResolver.resolveTitle(for: missing) == "Ghost")
    }
}
