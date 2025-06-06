import Everything
import Foundation

public struct Jujutsu {
    public var binaryPath: FSPath

    public func run(subcommand: String, arguments: [String], repository: Repository) async throws -> Data {
        let process = SimpleAsyncProcess(executableURL: binaryPath.url, arguments: [subcommand] + arguments, currentDirectoryURL: repository.path.url)
        return try await process.run()
    }
}
