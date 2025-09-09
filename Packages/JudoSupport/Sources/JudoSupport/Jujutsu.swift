import Everything
import Foundation
import Subprocess
import System
import TOMLKit

public struct Jujutsu: Sendable {
    public var binaryPath: FilePath
    public var tempConfigPath: FilePath

    public init(binaryPath: FilePath) {
        self.binaryPath = binaryPath
        tempConfigPath = FilePath.temporaryDirectory + "judo.toml"

        // TODO: #29 try!
        try! makeTemplates()
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

    public func makeTemplates() throws {
        // TODO: #12 We shouldn't need to do these every time.

        let temporaryConfig = JujutsuConfig(templateAliases: [
            CommitRef.template.key: CommitRef.template.content,
            Change.template.key: Change.template.content,
            JujutsuID.template.key: JujutsuID.template.content,
            Signature.template.key: Signature.template.content,
            FullChangeRecord.template.key: FullChangeRecord.template.content,
            TreeDiff.template.key: TreeDiff.template.content,
            TreeDiffEntry.template.key: TreeDiffEntry.template.content,
            TreeEntry.template.key: TreeEntry.template.content
        ])

        try TOMLEncoder().encode(temporaryConfig).write(toFile: tempConfigPath.path, atomically: true, encoding: .utf8)
        logger?.info("Using temporary jujutsu config at: \(tempConfigPath.string)")
    }

    // TODO: #13 Make generic by output type
    @discardableResult
    public func run(subcommand: String, arguments: [String], repository: Repository, useShell: Bool = false) async throws -> Data {

        print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
        defer {
            print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
        }

        let configuration: Subprocess.Configuration
        if !useShell {
            logger?.info("Running jujutsu directly: \(binaryPath.string) \(subcommand) \(arguments.joined(separator: " "))")
            configuration = Subprocess.Configuration(executable: .path(binaryPath), arguments: Arguments(["--no-pager", "--color=never"] + [subcommand] + arguments), workingDirectory: repository.path)
        }
        else {
            let shellCommand = shellify([binaryPath.string] + ["--no-pager", "--color=never"] + [subcommand] + arguments)
            logger?.info("Running jujutsu via shell: \(userShell) -c \(shellCommand)")
            configuration = Subprocess.Configuration(executable: .path(userShell), arguments: Arguments(["-c", shellCommand]), workingDirectory: repository.path)
        }
        do {
            let result = try await Subprocess.run(configuration, output: .data, error: .string)
            if !result.terminationStatus.isSuccess {
                fatalError("\(configuration), \(result)")
                throw JujutsuCLIError(configuration: configuration, result: result)
            }
            return result.standardOutput
        } catch {
            logger?.log("Error running jujutsu: \(error)")
            throw error
        }
    }
}

struct JujutsuCLIError: Error {
    var configuration: Subprocess.Configuration
    var result:  CollectedResult<DataOutput, StringOutput<Unicode.UTF8>>
}
