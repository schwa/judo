import Foundation
import System
import AppKit

public extension FilePath {
    var displayName: String {
        FileManager.default.displayName(atPath: self.path)
    }

    init(_ url: URL) {
        precondition(url.isFileURL, "FilePath can only be initialized with a file URL.")
        self.init(url.path)
    }

    var icon: NSImage {
        let fileURL = URL(fileURLWithPath: self.path)
        let icon = NSWorkspace.shared.icon(forFile: fileURL.path)
        return icon
    }

    static func + (lhs: FilePath, rhs: String) -> FilePath {
        return lhs.appending(rhs)
    }

    // TODO: Deprecate.
    var path: String {
        return withCString { cString in
            String(cString: cString)
        }
    }

    static var temporaryDirectory: FilePath {
        FilePath(FileManager.default.temporaryDirectory)
    }

    var url: URL {
        return URL(fileURLWithPath: self.path)
    }

    static var currentDirectory: FilePath {
        get {
            guard let currentPath = FileManager.default.currentDirectoryPath as String? else {
                fatalError("Could not retrieve current directory path.")
            }
            return FilePath(currentPath)
        }
        set {
            FileManager.default.changeCurrentDirectoryPath(newValue.path)
        }
    }
}

public enum JudoError: Swift.Error {
    case generic(String)
}
