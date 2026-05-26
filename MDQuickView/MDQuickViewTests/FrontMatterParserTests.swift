//
//  FrontMatterParserTests.swift
//  MDQuickViewTests
//
//  Created by Turek on 26/05/2026.
//

import Testing
@testable import MDQuickView

struct FrontMatterParserTests {

    // A source that yields extracted fields and a stripped body.
    struct ExtractionCase: Sendable {
        let name: String
        let source: String
        let keys: [String]
        let values: [String]
        let body: String
    }

    @Test(arguments: [
        ExtractionCase(
            name: "scalars",
            source: """
            ---
            title: Hello World
            author: Jane
            ---
            # Body

            Text.
            """,
            keys: ["title", "author"],
            values: ["Hello World", "Jane"],
            body: "# Body\n\nText."
        ),
        ExtractionCase(
            name: "inline array",
            source: """
            ---
            tags: [swift, macos, quicklook]
            ---
            Body
            """,
            keys: ["tags"],
            values: ["swift, macos, quicklook"],
            body: "Body"
        ),
        ExtractionCase(
            name: "nested object as raw string",
            source: """
            ---
            author:
              name: Jane
              role: editor
            title: Test
            ---
            Body
            """,
            keys: ["author", "title"],
            values: ["name: Jane\nrole: editor", "Test"],
            body: "Body"
        ),
    ])
    func extractsFields(_ testCase: ExtractionCase) {
        let result = FrontMatterParser.parse(testCase.source)
        #expect(result.fields.map(\.key) == testCase.keys)
        #expect(result.fields.map(\.value) == testCase.values)
        #expect(result.body == testCase.body)
    }

    @Test func noFrontMatterReturnsFullSource() {
        let source = "# Just Markdown\n\nNo front matter here."
        let result = FrontMatterParser.parse(source)
        #expect(result.fields.isEmpty)
        #expect(result.body == source)
    }

    @Test func emptyFile() {
        let result = FrontMatterParser.parse("")
        #expect(result.fields.isEmpty)
        #expect(result.body == "")
    }

    @Test func unterminatedFrontMatterTreatedAsBody() {
        let source = "---\ntitle: orphan\nstill body without closing delimiter"
        let result = FrontMatterParser.parse(source)
        #expect(result.fields.isEmpty)
        #expect(result.body == source)
    }
}
