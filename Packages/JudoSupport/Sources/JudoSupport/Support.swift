import Foundation
import System
import AppKit
import Subprocess

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
        let icon = NSWorkspace.shared.icon(forFile: fileURL.path)
        return icon
    }

    static func + (lhs: FilePath, rhs: String) -> FilePath {
        return lhs.appending(rhs)
    }

    // TODO: Deprecate.
    var path: String {
        return withCString { cString in
            String(cString: cString)
        }
    }

    static var temporaryDirectory: FilePath {
        FilePath(FileManager.default.temporaryDirectory)
    }

    var url: URL {
        return URL(fileURLWithPath: self.path)
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
    if useShell  {
        let shell: String
        if let pw = getpwuid(getuid()), let shellCString = pw.pointee.pw_shell {
            shell = String(cString: shellCString)
        }
        else {
            shell = "/bin/sh"
        }
        arguments = ["-l", "-c", try executable.resolveExecutablePath(in: environment).string] + arguments
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

func printTable(_ rows: [[String]]) {
    // Determine the number of columns (max number of elements in any row)
    let columnCount = rows.map { $0.count }.max() ?? 0

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
        print(line)
    }
}

extension Character {
    func boxMerge(with other: Character) -> Character {
        guard self != other else {
            return self
        }
        switch (self, other) {
        case (" ", _):
            return other
        case ("─", "│"), ("|", "─"):
            return "┼"
        case ("─", "╰"), ("─", "╯"):
            return "┴"
        case ("─", "╭"), ("─", "╮"):
            return "┬"
        case ("│", "╰"), ("│", "╭"):
            return "├"
        case ("│", "╯"), ("│", "╮"):
            return "┤"
        case ("╰", "│"), ("│", "╰"):
            return "├"
        default:
            return other
        }
    }
}
