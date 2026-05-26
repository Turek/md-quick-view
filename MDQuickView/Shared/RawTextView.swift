import AppKit

// A scrollable, selectable, read-only surface that presents Markdown source verbatim
// for the Raw viewing mode.
// The text is shown without soft wrapping so that every line ending and run of
// whitespace appears exactly as stored on disk; long lines extend horizontally.
final class RawTextView: NSView {

    // The scroll view that hosts the text view and provides scrolling.
    let scrollView = NSScrollView()

    // The native text view that renders the unmodified source.
    let textView = NSTextView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }

    // Replaces the displayed text with the given source, preserving it verbatim,
    // and reapplies the formatter across the new content.
    func display(_ source: String) {
        textView.string = source
        applyFormatting()
    }

    // Builds the non-wrapping, read-only text view and installs it in the scroll view.
    private func configure() {
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = false
        textView.drawsBackground = true
        textView.backgroundColor = RawTextFormatter.backgroundColor
        textView.textColor = RawTextFormatter.textColor
        textView.font = RawTextFormatter.font
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.setAccessibilityLabel("Markdown source")

        // A container that does not track the view width disables soft wrapping, so the
        // only line breaks shown are the ones present in the source.
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = false

        textView.defaultParagraphStyle = Self.paragraphStyle
        textView.typingAttributes = Self.attributes

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = RawTextFormatter.backgroundColor
        scrollView.autoresizingMask = [.width, .height]
        scrollView.frame = bounds

        addSubview(scrollView)
    }

    // Applies the formatter's font, colour, and line spacing across the whole document.
    // Setting the text view's string resets attributes, so this runs after each update.
    private func applyFormatting() {
        guard let textStorage = textView.textStorage else { return }
        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.setAttributes(Self.attributes, range: fullRange)
    }

    // The paragraph style carrying the formatter's line spacing.
    private static var paragraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = RawTextFormatter.lineSpacing
        return style
    }

    // The full attribute set applied to the source text.
    private static var attributes: [NSAttributedString.Key: Any] {
        [
            .font: RawTextFormatter.font,
            .foregroundColor: RawTextFormatter.textColor,
            .paragraphStyle: paragraphStyle
        ]
    }
}
