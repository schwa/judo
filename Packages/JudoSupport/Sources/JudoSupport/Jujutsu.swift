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
    public func run(subcommand: String, arguments: [String], repository: Repository, useShell: Bool = true) async throws -> Data {
        let configuration = if !useShell {
            Subprocess.Configuration(executable: .path(binaryPath), arguments: Arguments([subcommand] + arguments), workingDirectory: repository.path)
        }
        else {

            // TODO: HERE
            Subprocess.Configuration(executable: .path(binaryPath), arguments: Arguments([subcommand] + arguments), workingDirectory: repository.path)
        }

        logger?.info("Running jujutsu: \(subcommand) \(arguments)")

        do {
            let result = try await Subprocess.run(configuration, output: .data, error: .string)

            if !result.terminationStatus.isSuccess {
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
