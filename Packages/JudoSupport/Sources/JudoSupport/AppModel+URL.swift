import SwiftUI
import Foundation
import System

public extension AppModel {
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

        print("Current repo: \(currentRepository)")
        // Perform document opening on the MainActor to keep UI/document work serialized
        // and avoid passing a non-Sendable closure across concurrency boundaries.
        Task { @MainActor in
            try await openDocument?(path.url)
        }
        Task {
            try await Task.sleep(for: .seconds(0.01667))
            print("New? repo: \(currentRepository)")
        }
    }
}
