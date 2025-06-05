import Everything
import Foundation

struct Jujutsu {

    var binaryPath: FSPath

    func run(subcommand: String, arguments: [String], repository: Repository) async throws -> Data {
        let process = SimpleAsyncProcess(executableURL: binaryPath.url, arguments: [subcommand] + arguments, currentDirectoryURL: repository.path.url)
        return try await process.run()
    }
}
