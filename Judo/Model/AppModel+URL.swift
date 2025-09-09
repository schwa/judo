import SwiftUI
import Foundation
import System

extension AppModel {
    @MainActor
    func handle(_ url: URL) {
        print(url)
        guard url.scheme == "x-judo" else {
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }

        let path = FilePath(components.path)

        // Verify the path exists (and is a directory, since we deal with repositories)
        let pathString = path.string
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: pathString, isDirectory: &isDir)
        guard exists else {
            // If you have a logger, prefer logger?.error(...)
            print("Path does not exist: \(pathString)")
            return
        }
        // If you specifically require a directory, keep this guard; otherwise remove it.
        guard isDir.boolValue else {
            print("Path is not a directory: \(pathString)")
            return
        }

        // Check for query parameters to determine mode

        print("Current repo: \(currentRepositoryViewModel)")
        // Perform document opening on the MainActor to keep UI/document work serialized
        // and avoid passing a non-Sendable closure across concurrency boundaries.
        Task { @MainActor in
            try await openDocument?(path.url)
        }
        Task {
            let queryItems = components.queryItems ?? []
            var targetMode: RepositoryViewModel.Mode? = nil
            if queryItems.contains(where: { $0.name == "show" }) {
                targetMode = .change
            }
            // TODO: Using sleep to wait for repository setup is a hack.
            // Should use proper async coordination or notifications
            print("New? repo: \(currentRepositoryViewModel)")
            
            // After opening, switch to the appropriate mode if specified
            if let targetMode = targetMode {
                try await Task.sleep(for: .seconds(0.01667))
                // TODO: Using sleep to wait for mode switch is a hack.
                // Should use proper async coordination or notifications
                currentRepositoryViewModel?.mode = targetMode
                print("Switched to mode: \(targetMode)")
            }
        }
    }
}
