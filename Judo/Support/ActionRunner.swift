import JudoSupport
import SwiftUI

struct ActionRunner {
    @Binding
    private var status: Status

    @Binding
    private var preview: ActionPreview?

    init(status: Binding<Status>, preview: Binding<ActionPreview?>) {
        self._status = status
        self._preview = preview
    }

    @MainActor
    func with(action: some ActionProtocol) {
        if let action = action as? any PreviewableActionProtocol {
            let preview = ActionPreview(id: UUID(), body: AnyView(action.body)) {
                Task {
                    do {
                        try await action.closure()
                        status = .success(action)
                    } catch {
                        logger?.error("Action failed: \(action.name), error: \(error)")
                        status = .failure(action, error)
                    }
                }
            }
            self.preview = preview
        } else {
            Task {
                do {
                    try await action.closure()
                    status = .success(action)
                } catch {
                    logger?.error("Action failed: \(action.name), error: \(error)")
                    status = .failure(action, error)
                }
            }
        }
    }
}

extension EnvironmentValues {
    @Entry
    var actionRunner: ActionRunner?
}

struct ActionHostViewModifier: ViewModifier {
    @State
    private var actionRunner: ActionRunner?

    @State
    private var actionStatus: Status = .waiting

    @State
    private var preview: ActionPreview?

    init() {
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .status) {
                    StatusView(status: $actionStatus)
                    //                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
            }
            .onAppear {
                actionRunner = ActionRunner(status: $actionStatus, preview: $preview)
            }
            .sheet(item: $preview) { preview in
                preview.body
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                self.preview = nil
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("OK") {
                                self.preview = nil
                                preview.confirm()
                            }
                        }
                    }
            }
            .environment(\.actionRunner, actionRunner)
    }
}

struct ActionPreview: Identifiable {
    var id: UUID
    var body: AnyView
    var confirm: () -> Void
}
