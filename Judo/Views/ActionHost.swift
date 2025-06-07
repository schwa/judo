import JudoSupport
import SwiftUI

struct ActionHost {

    @Binding
    var status: Status

    func with(action: Action) {
        Task {
            do {
                try await action.closure()
                status = .success(action)
            }
            catch {
                print("Action failed: \(action.name), error: \(error)")
                status = .failure(action, error)
            }
        }
    }
}

extension EnvironmentValues {
    @Entry
    var actionHost: ActionHost?
}

