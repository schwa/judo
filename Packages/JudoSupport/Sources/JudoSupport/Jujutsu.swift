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

        // TODO: try!
        try! makeTemplates()
    }

    public func makeTemplates() throws {
        // TODO: We shouldn't need to do these every time.

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
        logger?.info(">>> \(tempConfigPath.string)")
    }

    @discardableResult
    public func run(subcommand: String, arguments: [String], repository: Repository) async throws -> Data {
        do {
            let arguments = Arguments([subcommand] + arguments)
            let result = try await Subprocess.run(.path(binaryPath), arguments: arguments, workingDirectory: repository.path, output: .data, error: .string)
            if !result.terminationStatus.isSuccess {
                logger?.log("Error running jujutsu: \(result.standardError ?? "")")
                throw JudoError.generic("TODO")
            }
            return result.standardOutput
        } catch {
            print(binaryPath, subcommand, arguments.joined(separator: " "))
            ////            logger?.log("Error running jujutsu: \(error)")
            throw error
        }
    }
}
