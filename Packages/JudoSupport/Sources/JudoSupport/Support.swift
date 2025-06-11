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
