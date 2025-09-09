import AppKit
import Foundation
import Subprocess
import System

public extension FilePath {
    var displayName: String {
        FileManager.default.displayName(atPath: self.path)
    }

    init(_ url: URL) {
        precondition(url.isFileURL, "FilePath can only be initialized with a file URL.")
        self.init(url.path)
    }

    var icon: NSImage {
        let fileURL = URL(fileURLWithPath: self.path)
        return NSWorkspace.shared.icon(forFile: fileURL.path)
    }

    static func + (lhs: FilePath, rhs: String) -> FilePath {
        lhs.appending(rhs)
    }

    // TODO: #17 Deprecate.
    var path: String {
        withCString { cString in
            String(cString: cString)
        }
    }

    static var temporaryDirectory: FilePath {
        FilePath(FileManager.default.temporaryDirectory)
    }

    var url: URL {
        URL(fileURLWithPath: self.path)
    }

    static var currentDirectory: FilePath {
        get {
            guard let currentPath = FileManager.default.currentDirectoryPath as String? else {
                fatalError("Could not retrieve current directory path.")
            }
            return FilePath(currentPath)
        }
        set {
            FileManager.default.changeCurrentDirectoryPath(newValue.path)
        }
    }
}

public enum JudoError: Swift.Error {
    case generic(String)
}

public func run<
    Input: InputProtocol,
    Output: OutputProtocol,
    Error: OutputProtocol
>(
    _ executable: Executable,
    useShell: Bool,
    arguments: [String] = [],
    environment: Subprocess.Environment = .inherit,
    workingDirectory: FilePath? = nil,
    platformOptions: PlatformOptions = PlatformOptions(),
    input: Input = .none,
    output: Output = .string,
    error: Error = .discarded
) async throws -> CollectedResult<Output, Error> {
    var executable = executable
    var arguments = arguments
    if useShell {
        let shell: String
        if let pw = getpwuid(getuid()), let shellCString = pw.pointee.pw_shell {
            shell = String(cString: shellCString)
        } else {
            shell = "/bin/sh"
        }
        arguments = ["-l", "-c", try executable.resolveExecutablePath(in: environment).string] + arguments
        print(arguments)
        executable = .path(FilePath(shell))
    }
    let configuration = Configuration(
        executable: executable,
        arguments: Arguments(arguments),
        environment: environment,
        workingDirectory: workingDirectory,
        platformOptions: platformOptions
    )
    return try await run(
        configuration,
        input: input,
        output: output,
        error: error
    )
}

internal extension Array {
    /// Decompose the array into its first element and the remaining elements.
    /// Returns nil if the array is empty.
    func uncons() -> (head: Element, tail: Array)? {
        guard let head = self.first else { return nil }
        let tail = Array(self.dropFirst())
        return (head, tail)
    }
}

func formatTable(_ rows: [[String]]) -> String {
    var result = ""

    // Determine the number of columns (max number of elements in any row)
    let columnCount = rows.map(\.count).max() ?? 0

    // Determine the maximum width of each column
    var columnWidths = Array(repeating: 0, count: columnCount)
    for row in rows {
        for (index, cell) in row.enumerated() {
            columnWidths[index] = max(columnWidths[index], cell.count)
        }
    }

    // Print each row
    for row in rows {
        var line = ""
        for i in 0..<columnCount {
            line += "| "
            if i < row.count {
                let cell = row[i]
                let paddedCell = cell.padding(toLength: columnWidths[i], withPad: " ", startingAt: 0)
                line += paddedCell + " "
            } else {
                let emptyCell = String(repeating: " ", count: columnWidths[i])
                line += emptyCell + " "
            }
        }
        line += "|"
        result.append(line + "\n")
    }

    return result
}

extension Character {
    func boxMerge(with other: Character) -> Character {
        // Try to get BoxSegments for each character
        let segmentsA = BoxSegments(self) ?? []
        let segmentsB = BoxSegments(other) ?? []

        // Merge the segment sets
        let combined = segmentsA.union(segmentsB)

        return combined.character
    }
}

struct BoxSegments: OptionSet {
    let rawValue: Int

    static let top = Self(rawValue: 1 << 0)
    static let bottom = Self(rawValue: 1 << 1)
    static let left = Self(rawValue: 1 << 2)
    static let right = Self(rawValue: 1 << 3)

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    init?(_ character: Character) {
        switch character {
        case "┼": self = [.top, .bottom, .left, .right]
        case "┤": self = [.top, .bottom, .left]
        case "├": self = [.top, .bottom, .right]
        case "┴": self = [.top, .left, .right]
        case "┬": self = [.bottom, .left, .right]
        case "│": self = [.top, .bottom]
        case "─": self = [.left, .right]
        case "╯": self = [.top, .left]
        case "╰": self = [.top, .right]
        case "╮": self = [.bottom, .left]
        case "╭": self = [.bottom, .right]
        case "╵": self = [.top]
        case "╷": self = [.bottom]
        case "╴": self = [.left]
        case "╶": self = [.right]
        case " ": self = []
        default: return nil
        }
    }

    var character: Character {
        switch self {
        case [.top, .bottom, .left, .right]:
            return "┼"

        case [.top, .bottom, .left]:
            return "┤"

        case [.top, .bottom, .right]:
            return "├"

        case [.top, .left, .right]:
            return "┴"

        case [.bottom, .left, .right]:
            return "┬"

        case [.top, .bottom]:
            return "│"

        case [.left, .right]:
            return "─"

        case [.top, .left]:
            return "╯"

        case [.top, .right]:
            return "╰"

        case [.bottom, .left]:
            return "╮"

        case [.bottom, .right]:
            return "╭"

        case [.top]:
            return "╵"

        case [.bottom]:
            return "╷"

        case [.left]:
            return "╴"

        case [.right]:
            return "╶"

        default:
            return " "
        }
    }
}

public extension String {
    func escaped() -> String {
        self.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    func removingPrefix(_ prefix: String) -> String {
        if hasPrefix(prefix) {
            return String(dropFirst(prefix.count))
        }
        return self
    }
}

public extension Data {
    func wrapped(prefix: String, suffix: String) -> Data {
        let prefixData = prefix.data(using: .utf8) ?? Data()
        let suffixData = suffix.data(using: .utf8) ?? Data()
        return prefixData + self + suffixData
    }
}
