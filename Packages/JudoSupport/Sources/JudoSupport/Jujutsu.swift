import Everything
import Foundation
import os
import Subprocess
import System
import TOMLKit

public struct Jujutsu: Sendable {
    public var binaryPath: FilePath
    public var tempConfigPath: FilePath
    private let logger: Logger?

    public init(binaryPath: FilePath, logger: Logger? = nil) {
        self.binaryPath = binaryPath
        self.tempConfigPath = FilePath.temporaryDirectory + "judo.toml"
        self.logger = logger

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
}
