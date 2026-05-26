//
//  MarkdownRendererTests.swift
//  MDQuickViewTests
//
//  Created by Turek on 26/05/2026.
//

import Testing
@testable import MDQuickView

// Verifies GFM rendering and self-contained HTML document assembly.
struct MarkdownRendererTests {

    @Test func gfmTableRendersStructure() {
        let body = """
        | Name | Role |
        | --- | --- |
        | Jane | Editor |
        """
        let html = MarkdownRenderer.renderHTMLFragment(from: body)
        #expect(html.contains("<table>"))
        #expect(html.contains("<thead>"))
        #expect(html.contains("<tbody>"))
        #expect(html.contains("<th>Name</th>"))
        #expect(html.contains("<td>Editor</td>"))
    }

    @Test func strikethroughRenders() {
        let html = MarkdownRenderer.renderHTMLFragment(from: "This is ~~gone~~ text.")
        #expect(html.contains("<del>gone</del>"))
    }

    @Test func taskListCheckboxesRender() {
        let body = """
        - [x] Done
        - [ ] Pending
        """
        let html = MarkdownRenderer.renderHTMLFragment(from: body)
        #expect(html.contains("type=\"checkbox\""))
        #expect(html.contains("checked=\"\""))
        #expect(html.contains("disabled=\"\""))
    }

    @Test func htmlBuilderProducesFullDocumentWithFrontMatter() {
        let fragment = MarkdownRenderer.renderHTMLFragment(from: "# Title")
        let html = HTMLBuilder.buildDocument(
            fragment: fragment,
            frontMatter: [("title", "Hello"), ("author", "Jane")]
        )

        #expect(html.hasPrefix("<!DOCTYPE html>"))
        #expect(html.contains("<meta charset=\"utf-8\">"))
        #expect(html.contains("<meta name=\"color-scheme\" content=\"light dark\">"))
        #expect(html.contains("<style>"))
        #expect(html.contains("<table class=\"front-matter\">"))
        #expect(html.contains("<th scope=\"row\">title</th>"))
        #expect(html.contains("<td>Hello</td>"))
        #expect(html.contains("<th scope=\"row\">author</th>"))
        #expect(html.contains("<main class=\"markdown-body\">"))
        #expect(html.contains("<h1>Title</h1>"))
        #expect(html.contains("Content-Security-Policy"))
    }

    @Test func rawHTMLInBodyPassesThroughSoWebViewMustDisableJS() {
        let html = MarkdownRenderer.renderHTMLFragment(from: "<script>alert(1)</script>")
        #expect(html.contains("<script>alert(1)</script>"))
    }

    @Test func documentCarriesContentSecurityPolicy() {
        let html = HTMLBuilder.buildDocument(fragment: "", frontMatter: [])
        #expect(html.contains("<meta http-equiv=\"Content-Security-Policy\""))
        #expect(html.contains("default-src 'none'"))
    }

    @Test func htmlBuilderOmitsFrontMatterTableWhenEmpty() {
        let fragment = MarkdownRenderer.renderHTMLFragment(from: "Body only.")
        let html = HTMLBuilder.buildDocument(fragment: fragment, frontMatter: [])

        #expect(!html.contains("<table class=\"front-matter\">"))
        #expect(!html.contains("<th scope=\"row\">"))
        #expect(html.contains("<main class=\"markdown-body\">"))
    }

    @Test func htmlBuilderEscapesFrontMatterValues() {
        let html = HTMLBuilder.buildDocument(
            fragment: "",
            frontMatter: [("desc", "a < b & \"c\"")]
        )
        #expect(html.contains("a &lt; b &amp; &quot;c&quot;"))
    }
}
