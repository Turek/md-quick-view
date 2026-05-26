//
//  FrontMatterParser.swift
//  MDQuickView
//
//  Created by Turek on 26/05/2026.
//

import Foundation

// Extracts YAML front matter from a Markdown source and returns the remaining body.
// Scoped to flat key/value pairs, inline arrays, and shallow nested blocks as raw strings.
// No third-party YAML dependency.
enum FrontMatterParser {

    // A parsed key/value pair preserving the order it appeared in the source.
    typealias Field = (key: String, value: String)

    // Detects a front matter block delimited by a leading and matching closing `---`.
    // Returns the extracted fields and the Markdown body with the block stripped.
    // When no valid block is present, returns no fields and the full source as body.
    nonisolated static func parse(_ source: String) -> (fields: [Field], body: String) {
        let lines = source.components(separatedBy: "\n")

        // Front matter must open on the very first line.
        guard let first = lines.first, isDelimiter(first) else {
            return ([], source)
        }

        // Locate the matching closing delimiter.
        guard let closingIndex = (1..<lines.count).first(where: { isDelimiter(lines[$0]) }) else {
            return ([], source)
        }

        let blockLines = Array(lines[1..<closingIndex])
        let bodyLines = lines[(closingIndex + 1)...]
        let body = bodyLines.joined(separator: "\n")

        return (parseFields(blockLines), body)
    }

    // A delimiter line is exactly `---` once surrounding whitespace is removed.
    nonisolated private static func isDelimiter(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespacesAndNewlines) == "---"
    }

    // Walks the front matter lines, pairing top-level keys with scalar, inline-array, or nested values.
    nonisolated private static func parseFields(_ lines: [String]) -> [Field] {
        var fields: [Field] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]

            // Skip blank lines and comments.
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                index += 1
                continue
            }

            // Only unindented lines introduce a new key.
            if line.first == " " || line.first == "\t" {
                index += 1
                continue
            }

            guard let colon = line.firstIndex(of: ":") else {
                index += 1
                continue
            }

            let key = String(line[..<colon]).trimmingCharacters(in: .whitespacesAndNewlines)
            let rawValue = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespacesAndNewlines)

            if rawValue.isEmpty {
                // An empty value may be followed by an indented nested block.
                let (nested, next) = collectNestedBlock(lines, startingAfter: index)
                fields.append((key, nested))
                index = next
            } else {
                fields.append((key, formatScalar(rawValue)))
                index += 1
            }
        }

        return fields
    }

    // Gathers indented lines following a key into a single raw string and reports the next index.
    nonisolated private static func collectNestedBlock(_ lines: [String], startingAfter index: Int) -> (value: String, nextIndex: Int) {
        var nestedLines: [String] = []
        var cursor = index + 1

        while cursor < lines.count {
            let line = lines[cursor]
            if line.first == " " || line.first == "\t" {
                nestedLines.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
                cursor += 1
            } else if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                cursor += 1
            } else {
                break
            }
        }

        return (nestedLines.joined(separator: "\n"), cursor)
    }

    // Renders a scalar value, expanding inline arrays into a readable comma-separated string.
    nonisolated private static func formatScalar(_ value: String) -> String {
        if value.hasPrefix("[") && value.hasSuffix("]") {
            let inner = value.dropFirst().dropLast()
            // Simple comma split: quoted elements containing commas are not supported in v1.
            let elements = inner
                .split(separator: ",")
                .map { unquote($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .filter { !$0.isEmpty }
            return elements.joined(separator: ", ")
        }
        return unquote(value)
    }

    // Removes a single matching pair of surrounding single or double quotes.
    nonisolated private static func unquote(_ value: String) -> String {
        guard value.count >= 2 else { return value }
        let first = value.first
        let last = value.last
        if (first == "\"" && last == "\"") || (first == "'" && last == "'") {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
}
