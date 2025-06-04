import Foundation

struct SimpleAsyncProcess {
    struct Error: Swift.Error {
        let exitCode: Int32
        let stderr: String
    }

    var executableURL: URL
    var arguments: [String] = []
    var currentDirectoryURL: URL?

    func run() async throws -> Data {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectoryURL

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        let stdoutHandle = stdoutPipe.fileHandleForReading
        let stderrHandle = stderrPipe.fileHandleForReading

        // Read stdout as stream
        let stdoutTask = Task {
            var collected = Data()
            for try await byte in stdoutHandle.bytes {
                collected.append(byte)
            }
            return collected
        }

        // Read stderr as a full block (non-streaming, safe)
        let stderrTask = Task {
            try stderrHandle.readToEnd() ?? Data()
        }

        // Wait for process to finish
        try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { _ in
                continuation.resume()
            }
        }

        let stdout = try await stdoutTask.value
        let stderr = try await stderrTask.value

        if process.terminationStatus != 0 {
            let errStr = String(data: stderr, encoding: .utf8) ?? "<non-UTF8 stderr>"
            throw Error(exitCode: process.terminationStatus, stderr: errStr)
        }

        return stdout
    }


}

extension SimpleAsyncProcess {
    func runSync() throws -> Data {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectoryURL

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderr = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        if process.terminationStatus != 0 {
            let errStr = String(data: stderr, encoding: .utf8) ?? "<non-UTF8 stderr>"
            throw Error(exitCode: process.terminationStatus, stderr: errStr)
        }

        return stdout
    }
}
