import Foundation
import RegexBuilder
import SwiftUI

public enum LineChangeType {
    case addition
    case deletion
    case unchanged
}

public struct LineChange {
    public var type: LineChangeType
    public var content: String
}

public struct Hunk {
    public var header: String
    public var oldStart: Int
    public var oldCount: Int
    public var newStart: Int
    public var newCount: Int
    public var changes: [LineChange]
}

public struct FileDiff {
    public var oldPath: String
    public var newPath: String
    public var hunks: [Hunk]
}

public struct Diff {
    public var files: [FileDiff]
}

public enum GitDiffParser {
    public static func parse(diffText: String) -> Diff {
        let hunkHeaderRegex = Regex {
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
            } else if line.starts(with: "--- ") {
                let path = line
                    .removingPrefix("--- ")
                    .trimmingCharacters(in: .whitespaces)
                    .removingPrefix("a/")
                currentFile?.oldPath = path
            } else if line.starts(with: "+++ ") {
                let path = line
                    .removingPrefix("+++ ")
                    .trimmingCharacters(in: .whitespaces)
                    .removingPrefix("b/")
                currentFile?.newPath = path
            } else if line.starts(with: "@@") {
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
            } else if line.starts(with: "+") || line.starts(with: "-") || line.starts(with: " ") {
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
            } else {
                logger?.debug("Unrecognized line in diff: '\(line)'")
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

// import Playgrounds
// #Playground {
//    let sampleDiffText = """
//    diff --git a/foo.txt b/foo.txt
//    --- a/foo.txt
//    +++ b/foo.txt
//    @@ -0,0 +1 @@
//    +hello
//    """
//    _ = GitDiffParser.parse(diffText: sampleDiffText)
//
//    let sample2 = """
//    diff --git a/file_1.txt b/file_1.txt
//    new file mode 100644
//    index 0000000000..01709e248d
//    --- /dev/null
//    +++ b/file_1.txt
//    @@ -0,0 +1,1 @@
//    +File 1 Content
//    """
//    _ = GitDiffParser.parse(diffText: sample2)
//
//    let sample3 = """
//        diff --git a/Judo/Support/Support.swift b/Judo/Support/Support.swift
//        index 32df63de9c..4f78b5e4e9 100644
//        --- a/Judo/Support/Support.swift
//        +++ b/Judo/Support/Support.swift
//        @@ -1,6 +1,9 @@
//        +import os
//         import Collections
//         import SwiftUI
//
//        +let logger: Logger? = Logger()
//        +
//         extension Dictionary {
//             init(_ orderedDictionary: OrderedDictionary<Key, Value>) {
//                 self.init(uniqueKeysWithValues: Array(orderedDictionary))
//        """
//    _ = GitDiffParser.parse(diffText: sample3)
//
//
// }
