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
    
    // Cache for command results
    private struct CachedResult {
        let data: Data
        let timestamp: Date
    }
    private var cache: [Command: CachedResult] = [:]
    private let cacheExpiration: TimeInterval = 0.5 // Cache for 0.5 seconds
    public var cacheEnabled: Bool = true
    
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
    public func run(subcommand: String, arguments: [String], invalidatesCache: Bool, useShell: Bool = false) async throws -> Data {
        let command = Command(
            executable: jujutsu.binaryPath,
            subcommand: subcommand,
            arguments: arguments,
            workingDirectory: repositoryPath,
            useShell: useShell,
            shell: useShell ? userShell : nil
        )
        
        if invalidatesCache && cacheEnabled {
            clearCache()
            logger?.info("🧹 Cache cleared for write operation: \(subcommand)")
        }
        let result = try await execute(command)
        return result
    }
    
    @discardableResult
    public func execute(_ command: Command) async throws -> Data {
        // Check if cache is enabled
        if cacheEnabled {
            // Periodically clean expired cache entries
            if cache.count > 10 {
                cleanExpiredCache()
            }
            
            // Check cache first
            if let cached = cache[command] {
                let age = Date().timeIntervalSince(cached.timestamp)
                if age < cacheExpiration {
                    logger?.info("📦 Cache hit: \(command.description) (age: \(String(format: "%.2f", age))s)")
                    return cached.data
                } else {
                    logger?.info("⏰ Cache expired: \(command.description) (age: \(String(format: "%.2f", age))s, max: \(self.cacheExpiration)s)")
                    cache.removeValue(forKey: command)
                }
            } else {
                logger?.debug("Cache miss: \(command.description)")
            }
        }
        
        // Chain this task after the current one
        let previousTask = currentTask
        
        let task = Task<Data, Error> {
            // Wait for previous task to complete
            await previousTask?.value
            
            // Now run our command
            let data = try await self.executeCommand(command)
            
            // Cache the result
            self.cacheResult(data, for: command)
            
            return data
        }
        
        // Store this as the new current task
        currentTask = Task {
            _ = try? await task.value
        }
        
        // Return the result
        return try await task.value
    }
    
    private func cacheResult(_ data: Data, for command: Command) {
        guard cacheEnabled else { return }
        
        cache[command] = CachedResult(data: data, timestamp: Date())
        logger?.info("💾 Cached: \(command.description) (\(data.count) bytes)")
    }
    
    public func clearCache() {
        let count = cache.count
        cache.removeAll()
        if count > 0 {
            logger?.debug("Cleared \(count) cached commands")
        }
    }
    
    private func cleanExpiredCache() {
        let now = Date()
        let expired = cache.compactMap { key, value in
            now.timeIntervalSince(value.timestamp) >= cacheExpiration ? key : nil
        }
        
        for key in expired {
            cache.removeValue(forKey: key)
        }
        
        if !expired.isEmpty {
            logger?.debug("Removed \(expired.count) expired cache entries")
        }
    }
    
    private func executeCommand(_ command: Command) async throws -> Data {
        logger?.info("🚀 Executing: \(command.description)")
        
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
