import Collections
import Everything
import SwiftTerm
import SwiftUI

struct ContentView: View {
    @State
    private var repository = Repository(path: "/tmp/fake-repo")

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
                RevisionTimelineViewNEW(selection: $selection, commits: $commits)
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

    func refresh() async {
        do {
            commits = try await repository.scan(revset: revisionQuery)
        } catch {
            print("Error scanning repository: \(error)")
        }
    }

    @ViewBuilder
    var toolbar: some View {
        ValueView(value: false) { value in
            Button("Open…") {
                value.wrappedValue = true
            }
            .fileImporter(isPresented: value, allowedContentTypes: [.directory], allowsMultipleSelection: false) { result in
                do {
                    let urls = try result.get()
                    guard let url = urls.first else { return }
                    repository.path = FSPath(url)
                    Task {
                        try await refresh()
                    }
                } catch {
                    print("Error selecting directory: \(error)")
                }
            }
        }

        Toggle(isOn: $isRawViewPresented) {
            Text("Raw")
        }
    }

    @ViewBuilder
    var inspector: some View {
        let selectedCommits = selection
            .sorted { lhs, rhs in
                let lhs = commits.index(forKey: lhs) ?? -1 // TODO: -1?
                let rhs = commits.index(forKey: rhs) ?? -1 // TODO: -1?
                return lhs < rhs
            }
            .compactMap { commits[$0] } // Filter commits based on selection

        if !selectedCommits.isEmpty {
            InspectorView(commits: commits, selectedCommits: selectedCommits)
        } else {
            ContentUnavailableView { Text("(no commits selected)") }
        }
    }
}

// MARK: -

struct ChangeIDView: View {
    var changeID: ChangeID

    var body: some View {
        if let shortest = changeID.shortest {
            Text(shortest)
                .foregroundStyle(Color(nsColor: NSColor.magenta))
                + Text(changeID.rawValue.trimmingPrefix(shortest).prefix(7))
                .foregroundStyle(.secondary)
        } else {
            Text(changeID.rawValue.prefix(8))
                .foregroundStyle(.secondary)
        }
    }
}

struct CommitIDView: View {
    var commitID: CommitID

    var body: some View {
        Text(commitID.shortest)
            .foregroundStyle(.blue)
            + Text(commitID.rawValue.trimmingPrefix(commitID.shortest).prefix(7))
            .foregroundStyle(.secondary)
    }
}

#Preview {
    ContentView()
}






