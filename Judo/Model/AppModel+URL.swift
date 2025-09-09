import SwiftUI
import Foundation
import System
import JudoSupport

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
            
            // Handle mode parameter
            var targetMode: RepositoryViewModel.Mode? = nil
            if let modeValue = queryItems.first(where: { $0.name == "mode" })?.value {
                switch modeValue {
                case "log", "timeline":
                    targetMode = .timeline
                case "show", "change":
                    targetMode = .change
                case "mixed":
                    targetMode = .mixed
                default:
                    print("Unknown mode: \(modeValue)")
                }
            }
            
            // Handle selection parameter
            let changeID = queryItems.first(where: { $0.name == "selection" })?.value
            
            // Apply the changes after a brief delay to ensure the document is loaded
            // TODO: Using sleep to wait for mode switch is a hack.
            try await Task.sleep(for: .seconds(0.01667))
            
            if let targetMode = targetMode {
                currentRepositoryViewModel?.mode = targetMode
                print("Switched to mode: \(targetMode)")
            }
            
            if let changeID = changeID {
                // Set the selection to the specified change
                currentRepositoryViewModel?.selection = [ChangeID(changeID)]
                print("Selected change: \(changeID)")
            }
        }
    }
}

/*
 URL scheme examples:
 x-judo://<path to repo>/?mode=timeline
 x-judo://<path to repo>/?mode=timeline&selection=zzzzz
 x-judo://<path to repo>/?mode=mixed
 x-judo://<path to repo>/?mode=mixed&selection=zzzzz
 x-judo://<path to repo>/?mode=change
 x-judo://<path to repo>/?mode=change&selection=zzzzz
*/
