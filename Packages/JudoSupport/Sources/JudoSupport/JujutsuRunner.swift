import Everything
import Foundation
import os
import Subprocess
import System

public actor JujutsuRunner {
    private let jujutsu: Jujutsu
    private let repositoryPath: FilePath
    private let logger: Logger?
    
    // Task chaining to ensure commands run serially
    private var currentTask: Task<Void, Never>?
    
    public init(jujutsu: Jujutsu, repositoryPath: FilePath, logger: Logger? = nil) {
        self.jujutsu = jujutsu
        self.repositoryPath = repositoryPath
        self.logger = logger
    }
    
    private var userShell: FilePath {
        // Method 1: Try POSIX getpwuid to get user's default shell from passwd database
        let uid = getuid()
        if let pw = getpwuid(uid) {
            let shellPtr = pw.pointee.pw_shell
            if let shellPtr = shellPtr, let shell = String(validatingCString: shellPtr), !shell.isEmpty {
                return FilePath(shell)
            }
        }
        
        // Method 2: Check SHELL environment variable (current running shell)
        if let shell = ProcessInfo.processInfo.environment["SHELL"], !shell.isEmpty {
            return FilePath(shell)
        }
        
        // Method 3: Fallback to POSIX-compliant /bin/sh
        return FilePath("/bin/sh")
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
    
    @discardableResult
    public func run(subcommand: String, arguments: [String], useShell: Bool = false) async throws -> Data {
        // Chain this task after the current one
        let previousTask = currentTask
        
        let task = Task<Data, Error> {
            // Wait for previous task to complete
            await previousTask?.value
            
            // Now run our command
            return try await self.executeCommand(subcommand: subcommand, arguments: arguments, useShell: useShell)
        }
        
        // Store this as the new current task
        currentTask = Task {
            _ = try? await task.value
        }
        
        // Return the result
        return try await task.value
    }
    
    private func executeCommand(subcommand: String, arguments: [String], useShell: Bool) async throws -> Data {
        let configuration: Subprocess.Configuration
        if !useShell {
            logger?.info("Running jujutsu directly: \(jujutsu.binaryPath.string) \(subcommand) \(arguments.joined(separator: " "))")
            configuration = Subprocess.Configuration(executable: .path(jujutsu.binaryPath), arguments: Arguments(["--no-pager", "--color=never"] + [subcommand] + arguments), workingDirectory: repositoryPath)
        }
        else {
            let shell = userShell
            let shellCommand = shellify([jujutsu.binaryPath.string] + ["--no-pager", "--color=never"] + [subcommand] + arguments)
            logger?.info("Running jujutsu via shell: \(shell) -c \(shellCommand)")
            configuration = Subprocess.Configuration(executable: .path(shell), arguments: Arguments(["-c", shellCommand]), workingDirectory: repositoryPath)
        }
        do {
            let result = try await Subprocess.run(configuration, output: .data, error: .string)
            if !result.terminationStatus.isSuccess {
                throw JujutsuCLIError(configuration: configuration, result: result)
            }
            return result.standardOutput
        } catch {
            logger?.error("Error running jujutsu: \(error)")
            throw error
        }
    }
}

struct JujutsuCLIError: Error {
    var configuration: Subprocess.Configuration
    var result:  CollectedResult<DataOutput, StringOutput<Unicode.UTF8>>
}
