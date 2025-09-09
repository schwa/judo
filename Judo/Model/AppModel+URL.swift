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
        Task { @MainActor in
            try await openDocument?(path.url)
        }
        Task {
            let queryItems = components.queryItems ?? []
            var targetMode: RepositoryViewModel.Mode? = nil
            if queryItems.contains(where: { $0.name == "show" }) {
                targetMode = .change
            }
            if let targetMode = targetMode {
                // TODO: Using sleep to wait for mode switch is a hack.
                try await Task.sleep(for: .seconds(0.01667))
                currentRepositoryViewModel?.mode = targetMode
                print("Switched to mode: \(targetMode)")
            }
        }
    }
}

/*
 x-open://<path to repo>/?mode=log
 x-open://<path to repo>/?mode=show
 x-open://<path to repo>/?mode=show&change=zzzzz
*/
