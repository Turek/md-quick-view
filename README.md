# MDQuickView

macOS Quick Look extension for Markdown files. Press Space on a `.md` file in Finder to see a polished rendering with YAML front matter as a table, switchable between **Preview** and **Raw** modes.

> Target: Mac App Store · macOS 26+ · Xcode 26 · Swift 6

## What it ships

| Target | Type | Purpose |
|---|---|---|
| `MDQuickView` | macOS SwiftUI app | Minimal host app that installs and registers the extensions |
| `PreviewExtension` | Quick Look Preview Extension | Full document preview with two viewing modes |
| `ThumbnailExtension` | Quick Look Thumbnail Extension | Finder thumbnails for Markdown files |

Shared parsing and rendering code (`MDQuickView/Shared/`) is compiled into all three targets:

- `DocumentModel.swift` — single parsed model backing both modes
- `FrontMatterParser.swift` — extracts YAML front matter and body
- `MarkdownRenderer.swift` — wraps `cmark-gfm` rendering
- `HTMLBuilder.swift` — builds the full HTML document with inlined CSS
- `Theme.swift` — CSS constants and style tokens
- `RawTextFormatter.swift` — raw source display settings
- `RawTextView.swift` — native AppKit text view backing the Raw mode
- `ThumbnailTitleResolver.swift` — resolves the title drawn on thumbnails

## Features

- GitHub Flavored Markdown rendering via `cmark-gfm` (tables, task lists, autolinks, strikethrough).
- YAML front matter extracted and shown as a metadata table above the rendered body.
- Two preview modes selected via a native segmented control:
  - **Preview** — rendered HTML with front matter table.
  - **Raw** — original file contents, monospaced and selectable.
- Both panes stay mounted; switching modes is instant and never reparses.
- Light and dark mode aware via `color-scheme`.
- Sandboxed, no network access, no JavaScript, no file writes.

## Supported file types

- UTIs: `public.markdown`, `net.daringfireball.markdown`
- Extensions: `.md`, `.markdown`, `.mdown`

## Project layout

```text
MDQuickView/
├── MDQuickView.xcodeproj/
├── MDQuickView/            # Host app target
├── PreviewExtension/       # Quick Look preview .appex
├── ThumbnailExtension/     # Quick Look thumbnail .appex
└── Shared/                 # Code shared across all three targets
```

## Building

1. Open `MDQuickView/MDQuickView.xcodeproj` in Xcode 26 or later.
2. Build and run the `MDQuickView` scheme once so macOS registers the embedded Quick Look extensions.
3. In Finder, select a `.md` file and press Space.

## Status

Implemented — both Quick Look extensions render and the shared parsing/rendering code is covered by unit tests (`xcodebuild test -scheme MDQuickView -destination 'platform=macOS'`). Architecture details live in `Docs/01-mdquickview_technical_spec.md`.

## Out of scope for v1

Editing, Mermaid, KaTeX/MathJax, network features, persistent annotations, full YAML object graph rendering.
