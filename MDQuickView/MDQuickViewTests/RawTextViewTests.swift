//
//  RawTextViewTests.swift
//  MDQuickViewTests
//
//  Created by Turek on 26/05/2026.
//

import Testing
import AppKit
@testable import MDQuickView

// Verifies that the Raw viewing mode presents the source verbatim in a native,
// selectable, non-editable, scrollable text view.
@MainActor
struct RawTextViewTests {

    // The full source, including front matter delimiters, is shown exactly as supplied.
    @Test func displaysSourceTextVerbatimIncludingFrontMatter() {
        let source = "---\ntitle: Demo\ntags: [a, b]\n---\n\n# Heading\n\nBody text.\n"
        let view = RawTextView()
        view.display(source)
        #expect(view.textView.string == source)
    }

    // Trailing newlines, blank lines, tabs, and trailing spaces survive unchanged.
    @Test func preservesLineEndingsAndWhitespace() {
        let source = "line one\n\n\n\tindented line\ntrailing spaces    \n\n"
        let view = RawTextView()
        view.display(source)
        #expect(view.textView.string == source)
    }

    // The preview is read-only.
    @Test func textViewIsNotEditable() {
        let view = RawTextView()
        #expect(view.textView.isEditable == false)
    }

    // The user can select and copy the source.
    @Test func textViewIsSelectable() {
        let view = RawTextView()
        #expect(view.textView.isSelectable == true)
    }

    // The formatter's monospaced font is applied.
    @Test func textViewUsesMonospacedFormatterFont() {
        let view = RawTextView()
        #expect(view.textView.font?.fontName == RawTextFormatter.font.fontName)
        #expect(view.textView.font?.pointSize == RawTextFormatter.font.pointSize)
    }

    // The source is treated as plain text, never as styled rich text.
    @Test func textViewRendersPlainText() {
        let view = RawTextView()
        #expect(view.textView.isRichText == false)
    }

    // The text view is embedded in a scroll view that can scroll vertically.
    @Test func textViewIsScrollable() {
        let view = RawTextView()
        #expect(view.scrollView.hasVerticalScroller == true)
        #expect(view.scrollView.documentView === view.textView)
    }
}
