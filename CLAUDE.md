# CLAUDE.md

Guidance for Claude when working in this repository.

## Project

**MDQuickView** — a macOS Quick Look extension for Markdown files, distributed via the Mac App Store. Press Space on a `.md` file in Finder → polished preview with YAML front matter table and three viewing modes (Preview / Raw / Side-by-side).

Authoritative spec: `Docs/01-mdquickview_technical_spec.md` (located outside this repo at `/Users/turek/Documents/Claude/Projects/MDQuickView/Docs/`). Always consult it before making architectural decisions.

## Stack & constraints

- **Swift 6**, strict concurrency enabled.
- **macOS 26.0** minimum deployment target. Do not add fallbacks for older macOS — the legacy `.qlgenerator` model is deliberately unsupported.
- **Xcode 26**, automatic signing, sandboxed for App Store.
- **No actual network use, no JavaScript execution, no file writes.** This is a read-only preview product. Keep it that way — it is load-bearing for App Review. Note: the extensions set `ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES` (synthesises `com.apple.security.network.client`) because WebKit's out-of-process Networking helper is sandbox-killed without it — the rendered panes show nothing otherwise. This entitlement is required by WebKit's process architecture, not because app code makes requests: JavaScript is disabled and every navigation but the local content load is refused. Do not remove it.

## Architecture

Three targets sharing one body of code:

| Target | Role |
|---|---|
| `MDQuickView` | Minimal SwiftUI host app — exists to register the extensions |
| `PreviewExtension.appex` | Quick Look preview with the three modes |
| `ThumbnailExtension.appex` | Finder thumbnails |

Shared code lives in `MDQuickView/Shared/` and is added to all three targets via shared source membership. When adding a new shared file, add it to all three target memberships in the Xcode project.

Single parsed model (`MarkdownDocumentModel`) backs all three preview modes. Parse once per file open; mode switching must not reparse.

## Pipeline (do not reorder)

1. Read file as UTF-8.
2. Detect + extract YAML front matter only when the file starts with `---` and has a matching closing `---`.
3. Preserve the original full source for Raw mode (do not normalize).
4. Pass the body (front matter stripped) to `cmark-gfm`.
5. Wrap the HTML fragment in a full document with inlined CSS — no external assets.
6. Bind the result into the three UI modes from the single shared model.

`cmark-gfm` does NOT parse front matter. Front matter handling is our code, always before the renderer.

## Dependencies

- **`cmark-gfm`** via a Swift Package Manager wrapper — required, added to all three targets.
- **No YAML library.** The front matter parser is intentionally small and scoped to flat `key: value` pairs, simple scalars, and inline arrays. Do not pull in a full YAML dependency for v1.
- Resist adding anything else without a clear reason.

## UI conventions

- Mode switch is a **native segmented control** (`Picker` with `.segmented` style, or `NSSegmentedControl`). Default selection: `Preview`. No custom skinning.
- Rendered pane = WebKit with fully inlined CSS, `color-scheme` set for light/dark.
- Raw pane = native AppKit text view, monospaced, selectable.
- Side-by-side = native split view; independent scrolling is fine for v1.

## Sandbox reality

Quick Look extensions inherit the host sandbox. Relative-path images in Markdown may or may not load depending on what the sandboxed process can reach — attempt best-effort resolution using the file's parent directory as the HTML `baseURL`, and treat failure as expected, not as a bug.

## What's out of scope for v1 (don't volunteer these)

Editing, Mermaid, KaTeX/MathJax, network features, telemetry, persistent settings storage, full YAML object graph rendering, syntax highlighting in Raw mode (unless trivial).

## Working style

- Keep code compact. This is a small, focused product — every abstraction should earn its place.
- Follow the implementation order in the spec (§ Suggested implementation order) unless there's a real reason to deviate.
- When touching shared code, remember it ships inside two sandboxed extensions — no assumptions about being in the host app process.
