import Collections
import Everything
import SwiftTerm
import SwiftUI
import JudoSupport

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
    private var isRawViewPresented: Bool = false

    @State
    private var status: Status = .waiting

    @State
    var actionHost: ActionHost?

    @State
    var isInspectorPresented: Bool = true

    init() {
    }

    var body: some View {

        @Bindable
        var repository = self.repository

        VStack {
            RevsetEditorView(revset: $revisionQuery) { text in
                revisionQuery = text
                Task {
                    await refresh()
                }
            }
            .padding()
            if !isRawViewPresented {
                RepositoryLogView(log: repository.currentLog, selection: $selection)


                bookmarksView

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
        .onAppear {
            actionHost = ActionHost(status: $status)
        }
        .environment(repository)
        .environment(\.actionHost, actionHost)
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

    func refresh() async {
        do {
            try await repository.log(revset: revisionQuery)
        } catch {
            print("Error scanning repository: \(error)")
        }
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
        ToolbarItem(placement: .status) {
            StatusView(status: $status)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
        }
        ToolbarItem(placement: .primaryAction) {
            Button("New") {
                with(action: Action(name: "new") {
                    try await repository.new(changes: selectedChanges.map(\.changeID))
                    await refresh()
                })
            }
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
                    try await repository.abandon(changes: selectedChanges.map(\.changeID))
                    await refresh()
                })
            }
            .disabled(selection.isEmpty)
        }

        ToolbarItem(placement: .primaryAction) {
            ValueView(value: false) { value in
                let selectedChanges = self.selectedChanges
                let targetChange = selectedChanges.first
                let sourceChanges = selectedChanges.dropFirst().map { $0 }
                Button("Squash") {
                    let descriptions = selectedChanges.compactMap { $0.description.isEmpty ? nil : $0.description }
                    if descriptions.count <= 1 {
                        with(action: Action(name: "Squash") {
                            try await repository.squash(changes: sourceChanges.map(\.id), destination: targetChange!.id, description: descriptions.first ?? "")
                            await refresh()
                        })
                    }
                    else {
                        value.wrappedValue = true
                    }
                }
                .disabled(selection.count < 2)
                .sheet(isPresented: value) {
                    DescriptionEditor(targetChange: targetChange, sourceChanges: sourceChanges, isSquash: true) { description in
                        with(action: Action(name: "Squash") {
                            try await repository.squash(changes: sourceChanges.map(\.id), destination: targetChange!.id, description: description)
                            await refresh()
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

        ToolbarItem(placement: .primaryAction) {
            Toggle(isOn: $isRawViewPresented) {
                Text("Raw")
            }
        }
    }

    @ViewBuilder
    var inspector: some View {
        if !selectedChanges.isEmpty {
            InspectorView(changes: repository.currentLog.changes, selectedChanges: selectedChanges)
        } else {
            ContentUnavailableView { Text("(no changes selected)") }
        }
    }

    func with(action: Action) {
        actionHost!.with(action: action)
    }
}


