import Foundation

public struct SimpleAsyncProcess {
    public struct Error: Swift.Error {
        public let exitCode: Int32
        public let stderr: String
    }

    public var executableURL: URL
    public var arguments: [String]
    public var currentDirectoryURL: URL?
    public var useShell: Bool = false

    public init(executableURL: URL, arguments: [String] = [], currentDirectoryURL: URL? = nil, useShell: Bool = false) {
        self.executableURL = executableURL
        self.arguments = arguments
        self.currentDirectoryURL = currentDirectoryURL
        self.useShell = useShell
    }

    public func run() async throws -> Data {
        let process = Process()

        if !useShell {
            process.executableURL = executableURL
            process.arguments = arguments
        }
        else {
            process.executableURL = URL(fileURLWithPath: currentShell)
            let commandLine = ([executableURL.path] + arguments).map { arg in
                "\"\(arg.replacingOccurrences(of: "\"", with: "\\\""))\""
            }.joined(separator: " ")
            process.arguments = ["-l", "-c", commandLine]
        }

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

    var currentShell: String {
        if let pw = getpwuid(getuid()), let shellCString = pw.pointee.pw_shell {
            return String(cString: shellCString)
        }
        return "/bin/sh" // fallback
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
