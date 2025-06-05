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
    private var log: RepositoryLog?

    @State
    private var isRawViewPresented: Bool = false

    @State
    private var status: Status = .waiting

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
                    RevisionTimelineViewNEW(selection: $selection, log: log)
                }
                else {
                    RevisionTimelineView(selection: $selection, log: log)
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
        guard let log = log else { return [] }
        return selection
            .sorted { lhs, rhs in
                let lhs = log.commits.index(forKey: lhs) ?? -1 // TODO: -1?
                let rhs = log.commits.index(forKey: rhs) ?? -1 // TODO: -1?
                return lhs < rhs
            }
            .compactMap { log.commits[$0] } // Filter commits based on selection

    }

    func refresh() async {
        do {
            log = try await repository.log(revset: revisionQuery)
        } catch {
            print("Error scanning repository: \(error)")
        }
    }

    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {

        ToolbarItem(placement: .status) {
            StatusView(status: $status)
                .frame(width: 480)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
        }

        ToolbarItem(placement: .primaryAction) {
            Button("Undo") {
                with(action: Action(name: "Undo") {
                    try await repository.undo()
                    await refresh()
                })
            }
            .disabled(!repository.canUndo)
        }

        ToolbarItem(placement: .primaryAction) {
            Button("Abandon") {
                with(action: Action(name: "Abandon") {
                    try await repository.abandon(commits: OrderedSet(selection))
                    await refresh()
                })
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
                        with(action: Action(name: "Squash") {
                            try await repository.squash(commits: OrderedSet(sourceCommits.map(\.id)), destination: targetCommit!.id, description: descriptions.first ?? "")
                            await refresh()
                        })
                    }
                    else {
                        value.wrappedValue = true
                    }
                }
                .disabled(selection.count < 2)
                .sheet(isPresented: value) {
                    DescriptionEditor(targetCommit: targetCommit, sourceCommits: sourceCommits, isSquash: true) { description in

                        with(action: Action(name: "Squash") {
                            try await repository.squash(commits: OrderedSet(sourceCommits.map(\.id)), destination: targetCommit!.id, description: description)
                            await refresh()
                        })


                    }
                }
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button("Describe") {
            }
            .disabled(true)
        }

        ToolbarItem(placement: .primaryAction) {
            Toggle(isOn: $isRawViewPresented) {
                Text("Raw")
            }
        }
    }

    @ViewBuilder
    var inspector: some View {
        if let log, !selectedCommits.isEmpty {
            InspectorView(commits: log.commits, selectedCommits: selectedCommits)
        } else {
            ContentUnavailableView { Text("(no commits selected)") }
        }
    }

    func with(action: Action) {
        Task {
            do {
                try await action.closure()
                status = .success(action)
            }
            catch {
                status = .failure(action, error)
            }
        }
    }
}
