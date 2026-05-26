//
//  Theme.swift
//  MDQuickView
//
//  Created by Turek on 26/05/2026.
//

import Foundation

// Inlined CSS for the rendered document.
// Colours are expressed as variables resolved per system appearance via prefers-color-scheme,
// so nothing is hardcoded to a single light or dark palette.
enum Theme {

    // The complete stylesheet embedded into every rendered document.
    nonisolated static let css: String = """
    :root {
      color-scheme: light dark;
      --bg: #ffffff;
      --fg: #1d1d1f;
      --muted-fg: #6e6e73;
      --border: #d2d2d7;
      --subtle-bg: #f5f5f7;
      --accent: #0066cc;
      --code-bg: #f5f5f7;
    }

    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #1e1e1e;
        --fg: #f5f5f7;
        --muted-fg: #98989d;
        --border: #3a3a3c;
        --subtle-bg: #2a2a2c;
        --accent: #4ea1ff;
        --code-bg: #2a2a2c;
      }
    }

    html {
      -webkit-text-size-adjust: 100%;
    }

    body {
      margin: 0;
      padding: 24px;
      background: var(--bg);
      color: var(--fg);
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif;
      font-size: 15px;
      line-height: 1.6;
    }

    table.front-matter {
      width: 100%;
      border-collapse: collapse;
      margin: 0 0 24px 0;
      font-size: 13px;
      border: 1px solid var(--border);
      border-radius: 6px;
      overflow: hidden;
    }

    table.front-matter th,
    table.front-matter td {
      text-align: left;
      vertical-align: top;
      padding: 6px 10px;
      border-bottom: 1px solid var(--border);
    }

    table.front-matter tr:last-child th,
    table.front-matter tr:last-child td {
      border-bottom: none;
    }

    table.front-matter th {
      width: 30%;
      font-weight: 600;
      color: var(--muted-fg);
      background: var(--subtle-bg);
      white-space: nowrap;
    }

    table.front-matter td {
      color: var(--fg);
      word-break: break-word;
      white-space: pre-wrap;
    }

    .markdown-body {
      overflow-wrap: break-word;
    }

    .markdown-body h1,
    .markdown-body h2,
    .markdown-body h3,
    .markdown-body h4,
    .markdown-body h5,
    .markdown-body h6 {
      line-height: 1.25;
      margin: 1.4em 0 0.5em;
      font-weight: 600;
    }

    .markdown-body h1 { font-size: 1.8em; }
    .markdown-body h2 {
      font-size: 1.45em;
      padding-bottom: 0.2em;
      border-bottom: 1px solid var(--border);
    }
    .markdown-body h3 { font-size: 1.2em; }

    .markdown-body p {
      margin: 0 0 1em;
    }

    .markdown-body a {
      color: var(--accent);
      text-decoration: none;
    }

    .markdown-body a:hover {
      text-decoration: underline;
    }

    .markdown-body code {
      font-family: ui-monospace, "SF Mono", Menlo, Monaco, "Courier New", monospace;
      font-size: 0.88em;
      background: var(--code-bg);
      padding: 0.15em 0.35em;
      border-radius: 4px;
    }

    .markdown-body pre {
      background: var(--code-bg);
      padding: 12px 14px;
      border-radius: 6px;
      overflow-x: auto;
    }

    .markdown-body pre code {
      background: none;
      padding: 0;
      font-size: 0.85em;
    }

    .markdown-body blockquote {
      margin: 0 0 1em;
      padding: 0.2em 1em;
      color: var(--muted-fg);
      border-left: 3px solid var(--border);
    }

    .markdown-body table {
      border-collapse: collapse;
      margin: 0 0 1em;
      display: block;
      overflow-x: auto;
    }

    .markdown-body th,
    .markdown-body td {
      border: 1px solid var(--border);
      padding: 6px 10px;
    }

    .markdown-body th {
      background: var(--subtle-bg);
      font-weight: 600;
    }

    .markdown-body ul,
    .markdown-body ol {
      margin: 0 0 1em;
      padding-left: 1.6em;
    }

    .markdown-body li {
      margin: 0.2em 0;
    }

    .markdown-body li input[type="checkbox"] {
      margin: 0 0.4em 0 0;
    }

    .markdown-body img {
      max-width: 100%;
      height: auto;
    }

    .markdown-body hr {
      border: none;
      border-top: 1px solid var(--border);
      margin: 1.6em 0;
    }

    .markdown-body del {
      color: var(--muted-fg);
    }
    """
}
