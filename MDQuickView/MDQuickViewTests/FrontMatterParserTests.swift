//
//  FrontMatterParserTests.swift
//  MDQuickViewTests
//
//  Created by Turek on 26/05/2026.
//

import XCTest

final class FrontMatterParserTests: XCTestCase {

    // Compares parsed fields without relying on tuple Equatable conformance.
    private func assertFields(
        _ actual: [FrontMatterParser.Field],
        _ expected: [FrontMatterParser.Field],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual.count, expected.count, "field count", file: file, line: line)
        for (lhs, rhs) in zip(actual, expected) {
            XCTAssertEqual(lhs.key, rhs.key, "key", file: file, line: line)
            XCTAssertEqual(lhs.value, rhs.value, "value for \(rhs.key)", file: file, line: line)
        }
    }

    func testValidFrontMatter() {
        let source = """
        ---
        title: Hello World
        author: Jane
        ---
        # Body

        Text.
        """

        let result = FrontMatterParser.parse(source)

        assertFields(result.fields, [("title", "Hello World"), ("author", "Jane")])
        XCTAssertEqual(result.body, "# Body\n\nText.")
    }

    func testNoFrontMatter() {
        let source = "# Just Markdown\n\nNo front matter here."

        let result = FrontMatterParser.parse(source)

        XCTAssertTrue(result.fields.isEmpty)
        XCTAssertEqual(result.body, source)
    }

    func testInlineArrayValue() {
        let source = """
        ---
        tags: [swift, macos, quicklook]
        ---
        Body
        """

        let result = FrontMatterParser.parse(source)

        assertFields(result.fields, [("tags", "swift, macos, quicklook")])
        XCTAssertEqual(result.body, "Body")
    }

    func testNestedObjectAsRawString() {
        let source = """
        ---
        author:
          name: Jane
          role: editor
        title: Test
        ---
        Body
        """

        let result = FrontMatterParser.parse(source)

        assertFields(result.fields, [("author", "name: Jane\nrole: editor"), ("title", "Test")])
        XCTAssertEqual(result.body, "Body")
    }

    func testEmptyFile() {
        let result = FrontMatterParser.parse("")

        XCTAssertTrue(result.fields.isEmpty)
        XCTAssertEqual(result.body, "")
    }

    func testUnterminatedFrontMatterTreatedAsBody() {
        let source = "---\ntitle: orphan\nstill body without closing delimiter"

        let result = FrontMatterParser.parse(source)

        XCTAssertTrue(result.fields.isEmpty)
        XCTAssertEqual(result.body, source)
    }
}
