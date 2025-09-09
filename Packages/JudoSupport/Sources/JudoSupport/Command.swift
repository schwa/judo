import Foundation
import Subprocess
import System

nonisolated public struct Command: Hashable, Sendable {
    public let executable: FilePath
    public let subcommand: String
    public let arguments: [String]
    public let workingDirectory: FilePath
    public let useShell: Bool
    public let shell: FilePath?
    
    public init(
        executable: FilePath,
        subcommand: String,
        arguments: [String],
        workingDirectory: FilePath,
        useShell: Bool = false,
        shell: FilePath? = nil
    ) {
        self.executable = executable
        self.subcommand = subcommand
        self.arguments = arguments
        self.workingDirectory = workingDirectory
        self.useShell = useShell
        self.shell = shell
    }
    
    public var configuration: Subprocess.Configuration {
        if useShell, let shell = shell {
            let shellCommand = shellify([executable.string] + globalArguments + [subcommand] + arguments)
            return Subprocess.Configuration(
                executable: .path(shell),
                arguments: Subprocess.Arguments(["-c", shellCommand]),
                workingDirectory: workingDirectory
            )
        } else {
            return Subprocess.Configuration(
                executable: .path(executable),
                arguments: Subprocess.Arguments(globalArguments + [subcommand] + arguments),
                workingDirectory: workingDirectory
            )
        }
    }
    
    // Global arguments that should be added to all jj commands
    private var globalArguments: [String] {
        ["--no-pager", "--color=never"]
    }
    
    private func shellify(_ arguments: [String]) -> String {
        arguments
            .map { arg in
                // Escape special characters for shell
                let escaped = arg
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                    .replacingOccurrences(of: "$", with: "\\$")
                    .replacingOccurrences(of: "`", with: "\\`")
                return "\"\(escaped)\""
            }
            .joined(separator: " ")
    }
    
    public var description: String {
        if useShell, let shell = shell {
            let shellCommand = shellify([executable.string] + globalArguments + [subcommand] + arguments)
            return "\(shell) -c \(shellCommand)"
        } else {
            return "\(executable.string) \(globalArguments.joined(separator: " ")) \(subcommand) \(arguments.joined(separator: " "))"
        }
    }
}