import Testing
@testable import MDQuickView

// Verifies the self-contained error page used when a file cannot be previewed.
struct HTMLBuilderErrorTests {

    @Test func errorDocumentIsSelfContainedHTML() {
        let html = HTMLBuilder.errorDocument(message: "Unable to read file")

        #expect(html.hasPrefix("<!DOCTYPE html>"))
        #expect(html.contains("Unable to read file"))
        // No external or scripted resources in a read-only preview.
        #expect(!html.contains("<script"))
        #expect(!html.contains("http://"))
    }

    @Test func errorDocumentEscapesTheMessage() {
        let html = HTMLBuilder.errorDocument(message: "a < b & \"c\"")

        #expect(html.contains("a &lt; b &amp; &quot;c&quot;"))
        #expect(!html.contains("a < b & \"c\""))
    }
}
