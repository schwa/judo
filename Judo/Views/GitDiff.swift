import Foundation
import SwiftUI
import RegexBuilder

enum LineChangeType {
    case addition
    case deletion
    case unchanged
}

struct LineChange {
    var type: LineChangeType
    var content: String
}

struct Hunk {
    var header: String
    var oldStart: Int
    var oldCount: Int
    var newStart: Int
    var newCount: Int
    var changes: [LineChange]
}

struct FileDiff {
    var oldPath: String
    var newPath: String
    var hunks: [Hunk]
}

struct Diff {
    var files: [FileDiff]
}

struct GitDiffParser {
    static let hunkHeaderRegex = try! Regex {
        "@@ -"
        Capture {
            OneOrMore(.digit)
        }
        Optionally {
            ","
            Capture {
                OneOrMore(.digit)
            }
        }
        " +"
        Capture {
            OneOrMore(.digit)
        }
        Optionally {
            ","
            Capture {
                OneOrMore(.digit)
            }
        }
        " @@"
    }

    static func parse(diffText: String) -> Diff {
        var files: [FileDiff] = []
        var lines = diffText.components(separatedBy: .newlines)

        var currentFile: FileDiff?
        var currentHunk: Hunk?

        while !lines.isEmpty {
            let line = lines.removeFirst()

            if line.starts(with: "diff --git") {
                if let file = currentFile {
                    files.append(file)
                }
                currentFile = FileDiff(oldPath: "", newPath: "", hunks: [])
                currentHunk = nil
            }
            else if line.starts(with: "--- ") {
                currentFile?.oldPath = String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            }
            else if line.starts(with: "+++ ") {
                currentFile?.newPath = String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            }
            else if line.starts(with: "@@") {
                // Finish prior hunk
                if let hunk = currentHunk {
                    currentFile?.hunks.append(hunk)
                }

                guard let match = line.firstMatch(of: hunkHeaderRegex) else {
                    // skip malformed hunk
                    continue
                }

                let oldStart = Int(match.output.1)!
                let oldCount = match.output.2.map { Int($0)! } ?? 1
                let newStart = Int(match.output.3)!
                let newCount = match.output.4.map { Int($0)! } ?? 1

                currentHunk = Hunk(
                    header: line,
                    oldStart: oldStart,
                    oldCount: oldCount,
                    newStart: newStart,
                    newCount: newCount,
                    changes: []
                )
            }
            else if line.starts(with: "+") || line.starts(with: "-") || line.starts(with: " ") {
                guard var hunk = currentHunk else { continue }

                let type: LineChangeType
                if line.starts(with: "+") {
                    type = .addition
                } else if line.starts(with: "-") {
                    type = .deletion
                } else {
                    type = .unchanged
                }

                let content = String(line.dropFirst())

                hunk.changes.append(LineChange(type: type, content: content))
                currentHunk = hunk
            }
            else {
                // Skip unrelated lines
            }
        }

        // Finish last hunk/file
        if let hunk = currentHunk {
            currentFile?.hunks.append(hunk)
        }
        if let file = currentFile {
            files.append(file)
        }

        return Diff(files: files)
    }
}

struct LineChangeView: View {
    let change: LineChange

    var body: some View {
        HStack(spacing: 4) {
            Text(prefixSymbol)
                .frame(width: 20, alignment: .trailing)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(prefixColor)

            Text(change.content)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 4)
        .background(backgroundColor)
    }

    private var prefixSymbol: String {
        switch change.type {
        case .addition: return "+"
        case .deletion: return "-"
        case .unchanged: return " "
        }
    }

    private var prefixColor: Color {
        switch change.type {
        case .addition: return .green
        case .deletion: return .red
        case .unchanged: return .secondary
        }
    }

    private var backgroundColor: Color {
        switch change.type {
        case .addition: return Color.green.opacity(0.1)
        case .deletion: return Color.red.opacity(0.1)
        case .unchanged: return Color.clear
        }
    }
}

struct GitDiffView: View {

    var parsedDiff: Diff

    var body: some View {
        List {
            ForEach(Array(parsedDiff.files.indices), id: \.self) { fileIndex in
                let file = parsedDiff.files[fileIndex]
                Section(header: Text("\(file.oldPath) → \(file.newPath)")) {

                    //
                    //                    .font(.headline)
                    //                    .padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(file.hunks.indices, id: \.self) { hunkIndex in
                            let hunk = file.hunks[hunkIndex]
                            Text(hunk.header)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 2)

                            ForEach(hunk.changes.indices, id: \.self) { changeIndex in
                                LineChangeView(change: hunk.changes[changeIndex])
                                //                        Text("?")
                            }
                        }
                    }
                }
            }
        }
    }
}
