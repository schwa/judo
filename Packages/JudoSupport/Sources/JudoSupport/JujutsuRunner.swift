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
    
    @discardableResult
    public func run(subcommand: String, arguments: [String], useShell: Bool = false) async throws -> Data {
        let command = Command(
            executable: jujutsu.binaryPath,
            subcommand: subcommand,
            arguments: arguments,
            workingDirectory: repositoryPath,
            useShell: useShell,
            shell: useShell ? userShell : nil
        )
        
        return try await execute(command)
    }
    
    @discardableResult
    public func execute(_ command: Command) async throws -> Data {
        // Chain this task after the current one
        let previousTask = currentTask
        
        let task = Task<Data, Error> {
            // Wait for previous task to complete
            await previousTask?.value
            
            // Now run our command
            return try await self.executeCommand(command)
        }
        
        // Store this as the new current task
        currentTask = Task {
            _ = try? await task.value
        }
        
        // Return the result
        return try await task.value
    }
    
    private func executeCommand(_ command: Command) async throws -> Data {
        logger?.info("Executing: \(command.description)")
        
        let configuration = command.configuration
        
        do {
            let result = try await Subprocess.run(configuration, output: .data, error: .string)
            if !result.terminationStatus.isSuccess {
                throw JujutsuCLIError(command: command, result: result)
            }
            return result.standardOutput
        } catch {
            logger?.error("Error executing command: \(error)")
            throw error
        }
    }
}

struct JujutsuCLIError: Error {
    var command: Command
    var result: CollectedResult<DataOutput, StringOutput<Unicode.UTF8>>
}
