//
//  RawTextFormatter.swift
//  MDQuickView
//
//  Created by Turek on 26/05/2026.
//

import AppKit

// Display configuration for the Raw viewing mode's native text view.
// Provides values only; the extension view layer applies them to its NSTextView.
// Values are exposed as computed properties because NSFont and NSColor are not
// Sendable, which keeps the type free of stored non-Sendable global state under
// Swift 6 strict concurrency.
enum RawTextFormatter {

    // The monospaced system font used to render the unmodified source.
    static var font: NSFont {
        .monospacedSystemFont(ofSize: 12, weight: .regular)
    }

    // Extra spacing between lines, in points, for legibility of dense source.
    static let lineSpacing: CGFloat = 2

    // Foreground colour that resolves automatically for the current appearance.
    static var textColor: NSColor { .textColor }

    // Background colour that resolves automatically for the current appearance.
    static var backgroundColor: NSColor { .textBackgroundColor }

    // Explicit foreground colour for a light appearance.
    static var lightTextColor: NSColor {
        NSColor(srgbRed: 0.114, green: 0.114, blue: 0.122, alpha: 1)
    }

    // Explicit foreground colour for a dark appearance.
    static var darkTextColor: NSColor {
        NSColor(srgbRed: 0.961, green: 0.961, blue: 0.969, alpha: 1)
    }
}
