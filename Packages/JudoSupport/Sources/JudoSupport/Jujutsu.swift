import Everything
import Foundation
import TOMLKit

public struct Jujutsu {
    public var binaryPath: FSPath
    public var tempConfigPath: FSPath

    public init(binaryPath: FSPath) {
        self.binaryPath = binaryPath
        tempConfigPath = FSPath.temporaryDirectory + "judo.toml"

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
            TreeEntry.template.key: TreeEntry.template.content,
        ])

        try TOMLEncoder().encode(temporaryConfig).write(toFile: tempConfigPath.path, atomically: true, encoding: .utf8)
        print(">>>", tempConfigPath)
    }

    public func run(subcommand: String, arguments: [String], repository: Repository) async throws -> Data {
        let process = SimpleAsyncProcess(executableURL: binaryPath.url, arguments: [subcommand] + arguments, currentDirectoryURL: repository.path.url)
        do {
            return try await process.run()
        }
        catch {
            print(binaryPath, subcommand, arguments.joined(separator: " "))
            throw error
        }
    }
}
