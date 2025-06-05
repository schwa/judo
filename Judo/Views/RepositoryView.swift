import Collections
import Everything
import SwiftTerm
import SwiftUI

struct RepositoryView: View {
    @Environment(AppModel.self)
    private var appModel

    @Environment(Repository.self)
    private var repository

    @State
    private var head: ChangeID?

    @State
    private var selection: Set<ChangeID> = []

    @State
    private var revisionQuery: String = ""

    @State
    private var commits: OrderedDictionary<ChangeID, CommitRecord> = [:]

    @State
    private var isRawViewPresented: Bool = false

    var body: some View {
        VStack {
            RevsetEditorView(revisionQuery: $revisionQuery) { text in
                revisionQuery = text
                Task {
                    await refresh()
                }
            }
            .padding()
            if !isRawViewPresented {
                if appModel.isNewTimelineViewEnabled {
                    RevisionTimelineViewNEW(selection: $selection, commits: $commits)
                }
                else {
                    RevisionTimelineView(selection: $selection, commits: $commits)

                }
            } else {
                RawTimelineView(revisionQuery: revisionQuery)
            }
        }
        .navigationDocument(repository.path.url)
        .navigationSubtitle("\(repository.path.description)")
        .toolbar {
            toolbar
        }
        .task {
            head = repository.head
            await refresh()
        }
        .inspector(isPresented: .constant(true)) {
            inspector
        }
        .environment(repository)
    }

    var selectedCommits: [CommitRecord] {
        selection
            .sorted { lhs, rhs in
                let lhs = commits.index(forKey: lhs) ?? -1 // TODO: -1?
                let rhs = commits.index(forKey: rhs) ?? -1 // TODO: -1?
                return lhs < rhs
            }
            .compactMap { commits[$0] } // Filter commits based on selection

    }

    func refresh() async {
        do {
            commits = try await repository.scan(revset: revisionQuery)
        } catch {
            print("Error scanning repository: \(error)")
        }
    }

    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Undo") {
                Task {
                    try await repository.undo()
                    await refresh()
                }
            }
            .disabled(!repository.canUndo)
        }

        ToolbarItem(placement: .primaryAction) {
            Button("Abandon") {
                Task {
                    try await repository.abandon(commits: OrderedSet(selection))
                    await refresh()
                }
            }
            .disabled(selection.isEmpty)
        }

        ToolbarItem(placement: .primaryAction) {
            ValueView(value: false) { value in
                let selectedCommits = self.selectedCommits
                let targetCommit = selectedCommits.first
                let sourceCommits = selectedCommits.dropFirst().map { $0 }
                Button("Squash") {
                    let descriptions = selectedCommits.compactMap { $0.description.isEmpty ? nil : $0.description }
                    if descriptions.count <= 1 {
                        Task {
                            try! await repository.squash(commits: OrderedSet(sourceCommits.map(\.id)), destination: targetCommit!.id, description: descriptions.first ?? "")
                            await refresh()
                        }
                    }
                    else {
                        value.wrappedValue = true
                    }
                }
                .disabled(selection.count < 2)
                .sheet(isPresented: value) {
                    DescriptionEditor(targetCommit: targetCommit, sourceCommits: sourceCommits, isSquash: true) { description in

                        Task {
                            try! await repository.squash(commits: OrderedSet(sourceCommits.map(\.id)), destination: targetCommit!.id, description: description)
                            await refresh()
                        }


                    }
                }
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button("Describe") {
            }
            .disabled(true)
        }

        ToolbarItem(placement: .secondaryAction) {
            Toggle(isOn: $isRawViewPresented) {
                Text("Raw")
            }
        }
    }

    @ViewBuilder
    var inspector: some View {
        if !selectedCommits.isEmpty {
            InspectorView(commits: commits, selectedCommits: selectedCommits)
        } else {
            ContentUnavailableView { Text("(no commits selected)") }
        }
    }
}
