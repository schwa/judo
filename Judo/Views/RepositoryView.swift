import Collections
import Everything
import SwiftTerm
import SwiftUI
import JudoSupport

struct RepositoryView: View {
    init() {
    }

    enum Mode: Hashable, CaseIterable {
        case timeline
        case mixed
        case change
    }

    @State
    var mode: Mode = .mixed

    @State
    var actionHost: ActionHost?

    @Environment(Repository.self)
    var repository

    @State
    var status: Status = .waiting

    @State
    private var selection: Set<ChangeID> = []

    var body: some View {
        Group {
            switch mode {
            case .timeline:
                ChangesGraphView(selection: $selection)
            case .mixed:
                MixedModeRepositoryView(selection: $selection)
            case .change:
                ChangesDetailView(changes: selectedChanges)
            }
        }
        .environment(\.actionHost, actionHost)
        .navigationDocument(repository.path.url)
        .navigationSubtitle("\(repository.path.description)")
        .toolbar {
            toolbar
        }
        .onAppear {
            actionHost = ActionHost(status: $status)
        }
        .task {
            try! await repository.refresh()
        }
    }

    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Picker("Mode", selection: $mode) {
                Text("Timeline").tag(Mode.timeline)
                    .keyboardShortcut("1", modifiers: [.command])
                Text("Mixed").tag(Mode.mixed)
                    .keyboardShortcut("2", modifiers: [.command])
                Text("Change").tag(Mode.change)
                    .keyboardShortcut("3", modifiers: [.command])
            }
            .pickerStyle(.segmented)
        }
        ToolbarItem(placement: .status) {
            StatusView(status: $status)
//                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
        }
    }

    var selectedChanges: [Change] {
        let log = repository.currentLog
        return selection
            .sorted { lhs, rhs in
                let lhs = log.changes.index(forKey: lhs) ?? -1 // TODO: -1?
                let rhs = log.changes.index(forKey: rhs) ?? -1 // TODO: -1?
                return lhs < rhs
            }
            .compactMap { log.changes[$0] } // Filter changes based on selection

    }

}
