import Collections
import Everything
import JudoSupport
import SwiftTerm
import SwiftUI

struct MixedModeRepositoryView: View {
    @Binding
    var selection: Set<ChangeID>

    @Environment(AppModel.self)
    private var appModel

    @Environment(Repository.self)
    private var repository

    @Environment(\.actionRunner)
    private var actionRunner

    @State
    private var search: String = ""

    @State
    private var isInspectorPresented: Bool = true

    var body: some View {
        @Bindable
        var repository = self.repository

        VStack {
            //            RevsetEditorView(revset: $revisionQuery) { text in
            //                revisionQuery = text
            //                Task {
            //                    try! await repository.refresh()
            //                }
            //            }
            //            .padding()
            RepositoryLogView(log: repository.currentLog, selection: $selection)

            //            bookmarksView
            //            Text("\(repository.currentLog.changes.count)")
        }
        .toolbar {
            toolbar
        }
        .inspector(isPresented: $isInspectorPresented) {
            inspector
                .inspectorColumnWidth(min: 200, ideal: 320)
                .toolbar {
                    Spacer()
                    Button("Toggle Inspector", systemImage: "sidebar.leading") {
                        isInspectorPresented.toggle()
                    }
                }
        }

        // TODO: macOS 26
        //        .searchable(text: $search, placement: .toolbarPrincipal)
        .searchable(text: $search, placement: .automatic)
        .searchScopes($scope, activation: .onSearchPresentation) {
            Text("Revset").tag(SearchScope.revset)
            Text("Description").tag(SearchScope.description)
        }
        .searchPresentationToolbarBehavior(.avoidHidingContent)
        .onSubmit(of: .search) {
            performSearch()
        }
    }

    @State
    private var scope: SearchScope = .revset

    enum SearchScope: Hashable {
        case description
        case revset
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

    @ViewBuilder
    var bookmarksView: some View {
        HStack {
            ForEach(repository.currentLog.bookmarks.values) { bookmark in
                TagView(bookmark.name)
                    .backgroundStyle(.judoBookmarkColor)
            }
        }
        .padding(.bottom, 4)
    }

    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("New") {
                actionRunner?.with(action: Action(name: "new") {
                    try await repository.new(changes: selectedChanges.map(\.changeID))
                    try await repository.refresh()
                })
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button("Undo") {
                actionRunner?.with(action: Action(name: "Undo") {
                    try await repository.undo()
                    try await repository.refresh()
                })
            }
            .disabled(!repository.canUndo)
        }

        ToolbarItem(placement: .primaryAction) {
            Button("Abandon") {
                actionRunner?.with(action: Action(name: "Abandon") {
                    try await repository.abandon(changes: selectedChanges.map(\.changeID))
                    try await repository.refresh()
                })
            }
            .disabled(selection.isEmpty)
        }

        ToolbarItem(placement: .primaryAction) {
            ValueView(value: false) { value in
                let selectedChanges = selectedChanges
                let targetChange = selectedChanges.first
                let sourceChanges = selectedChanges.dropFirst().map(\.self)
                Button("Squash") {
                    let descriptions = selectedChanges.compactMap { $0.description.isEmpty ? nil : $0.description }
                    if descriptions.count <= 1 {
                        actionRunner?.with(action: Action(name: "Squash") {
                            try await repository.squash(changes: sourceChanges.map(\.id), destination: targetChange!.id, description: descriptions.first ?? "")
                            try await repository.refresh()
                        })
                    } else {
                        value.wrappedValue = true
                    }
                }
                .disabled(selection.count < 2)
                .sheet(isPresented: value) {
                    DescriptionEditor(targetChange: targetChange, sourceChanges: sourceChanges, isSquash: true) { description in
                        actionRunner?.with(action: Action(name: "Squash") {
                            try await repository.squash(changes: sourceChanges.map(\.id), destination: targetChange!.id, description: description)
                            try await repository.refresh()
                        })
                    }
                }
            }
        }

        //        ToolbarItem(placement: .primaryAction) {
        //            Button("Describe") {
        //            }
        //            .disabled(true)
        //        }
    }

    @ViewBuilder
    var inspector: some View {
        if !selectedChanges.isEmpty {
            MixedModeChangesDetailView(selectedChanges: selectedChanges)
        } else {
            ContentUnavailableView { Text("(no changes selected)") }
        }
    }

    func performSearch() {
        let revset: String
        switch scope {
        case .description:
            // Search by description
            var search = search.trimmingCharacters(in: .whitespacesAndNewlines)
            if search.isEmpty {
                revset = ""
            } else {
                search = search.replacingOccurrences(of: "\"", with: "\\\"")
                revset = "description(\"\(search)\")"
            }

        case .revset:
            revset = search
        }
        Task {
            logger?.log("Search submitted: \(revset)")
            try? await repository.log(revset: revset)
        }
    }
}
