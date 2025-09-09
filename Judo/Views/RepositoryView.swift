import Collections
import Everything
import JudoSupport
import SwiftTerm
import SwiftUI

struct RepositoryView: View {
    init() {
    }

    @Environment(RepositoryViewModel.self)
    var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        
        Group {
            switch viewModel.mode {
            case .timeline:
                ChangesGraphView(selection: $viewModel.selection)

            case .mixed:
                MixedModeRepositoryView(selection: $viewModel.selection)

            case .change:
                ChangesDetailView(changes: selectedChanges)
            }
        }

        .modifier(ActionHostViewModifier())
        .navigationDocument(viewModel.repository.path.url)
        .navigationSubtitle("\(viewModel.repository.path.description)")
        .toolbar {
            toolbar
        }
        .task {
            try! await viewModel.refreshLog()
        }
        .focusable()
        .focusedSceneValue(\.repository, viewModel.repository)
        .focusedSceneValue(\.repositoryViewModel, viewModel)
        .onAppear {
            print("RepositoryView appeared with repository: \(viewModel.repository.path)")
        }
    }

    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        @Bindable var viewModel = viewModel
        
        ToolbarItem(placement: .navigation) {
            Picker("Mode", selection: $viewModel.mode) {
                Text("Timeline").tag(RepositoryViewModel.Mode.timeline)
                Text("Mixed").tag(RepositoryViewModel.Mode.mixed)
                Text("Change").tag(RepositoryViewModel.Mode.change)
            }
            .pickerStyle(.segmented)
        }
    }

    var selectedChanges: [Change] {
        let log = viewModel.currentLog
        return viewModel.selection
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
