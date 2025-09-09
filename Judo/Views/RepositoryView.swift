import Collections
import Everything
import JudoSupport
import SwiftTerm
import SwiftUI

struct RepositoryView: View {
    init() {
    }

    enum Mode: Hashable, CaseIterable {
        case timeline
        case mixed
        case change
    }

    @State
    private var mode: Mode = .mixed

    @Environment(Repository.self)
    var repository

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

        .modifier(ActionHostViewModifier())
        .navigationDocument(repository.path.url)
        .navigationSubtitle("\(repository.path.description)")
        .toolbar {
            toolbar
        }
        .task {
            try! await repository.refresh()
        }
        .focusable()
        .focusedSceneValue(\.repository, repository)
        .onAppear {
            print("RepositoryView appeared with repository: \(repository.path)")
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
    }

    var selectedChanges: [Change] {
        let log = repository.currentLog
        return selection
            .sorted { lhs, rhs in
                let lhs = log.changes.index(forKey: lhs) ?? -1 // TODO: #7 -1?
                let rhs = log.changes.index(forKey: rhs) ?? -1 // TODO: #7 -1?
                return lhs < rhs
            }
            .compactMap { log.changes[$0] } // Filter changes based on selection

    }
}

extension FocusedValues {
    @Entry
    var repository: Repository?
}
