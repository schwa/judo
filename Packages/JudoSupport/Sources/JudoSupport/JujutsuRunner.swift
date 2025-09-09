import Everything
import Foundation
import Subprocess
import System

public actor JujutsuRunner {
    private let jujutsu: Jujutsu
    private let repositoryPath: FilePath
    
    public init(jujutsu: Jujutsu, repositoryPath: FilePath) {
        self.jujutsu = jujutsu
        self.repositoryPath = repositoryPath
    }
    
    // TODO: Move out of here (and cache)
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
    
    // TODO: #13 Make generic by output type
    @discardableResult
    public func run(subcommand: String, arguments: [String], useShell: Bool = false) async throws -> Data {

        print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
        defer {
            print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
        }

        let configuration: Subprocess.Configuration
        if !useShell {
            await MainActor.run {
                logger?.info("Running jujutsu directly: \(self.jujutsu.binaryPath.string) \(subcommand) \(arguments.joined(separator: " "))")
            }
            configuration = Subprocess.Configuration(executable: .path(jujutsu.binaryPath), arguments: Arguments(["--no-pager", "--color=never"] + [subcommand] + arguments), workingDirectory: repositoryPath)
        }
        else {
            let shell = userShell
            let shellCommand = shellify([jujutsu.binaryPath.string] + ["--no-pager", "--color=never"] + [subcommand] + arguments)
            await MainActor.run {
                logger?.info("Running jujutsu via shell: \(shell) -c \(shellCommand)")
            }
            configuration = Subprocess.Configuration(executable: .path(shell), arguments: Arguments(["-c", shellCommand]), workingDirectory: repositoryPath)
        }
        do {
            let result = try await Subprocess.run(configuration, output: .data, error: .string)
            if !result.terminationStatus.isSuccess {
                fatalError("\(configuration), \(result)")
                throw JujutsuCLIError(configuration: configuration, result: result)
            }
            return result.standardOutput
        } catch {
            await MainActor.run {
                logger?.log("Error running jujutsu: \(error)")
            }
            throw error
        }
    }
}

struct JujutsuCLIError: Error {
    var configuration: Subprocess.Configuration
    var result:  CollectedResult<DataOutput, StringOutput<Unicode.UTF8>>
}