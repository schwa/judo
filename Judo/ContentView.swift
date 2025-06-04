import SwiftUI
import Everything
import Collections
import SwiftTerm

struct ContentView: View {

    @State
    var repository = Repository(path: "/tmp/fake-repo")

    @State
    var head: ChangeID?

    @State
    var selection: Set<ChangeID> = []

    @State
    var revisionQuery: String = ""

    @State
    var commits: OrderedDictionary<ChangeID, CommitRecord> = [:]

    @State
    var isRawViewPresented: Bool = false

    var body: some View {
        VStack {
            RevsetEditorView(revisionQuery: $revisionQuery) { text in
                self.revisionQuery = text
                Task {
                    await refresh()
                }
            }
            .padding()
            if !isRawViewPresented {
                RevisionTimelineViewNEW(selection: $selection, commits: $commits)
            }
            else {
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
        }
        catch {
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
                }
                catch {
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
        }
        else {
            ContentUnavailableView(label: { Text("(no commits selected)") })

        }
    }
}

struct ChangeIDView: View {
    var changeID: ChangeID

    var body: some View {
        if let shortest = changeID.shortest {
            Text(shortest)
                .foregroundStyle(Color(nsColor: NSColor.magenta))
            + Text(changeID.rawValue.trimmingPrefix(shortest).prefix(7))
                .foregroundStyle(.secondary)
        }
        else {
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



struct InspectorView: View {
    @Environment(Repository.self)
    var repository

    @State
    var commitIndex: Int = 0

    var commits: OrderedDictionary<ChangeID, CommitRecord>

    var selectedCommits: [CommitRecord]

    var body: some View {
        VStack {
            Text("Commit \(commitIndex + 1) of \(selectedCommits.count)")
            if let commit = selectedCommits.first {
                CommitDetailView(commits: commits, commit: commit)

            }
        }
    }
}

struct CommitRowView: View {
    @Environment(Repository.self)
    var repository

    var commit: CommitRecord

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                ChangeIDView(changeID: commit.change_id).monospaced()
                if let email = commit.author.email {
                    Text(email)
                }
                Text(commit.author.timestamp, style: .relative)
                    .foregroundStyle(.cyan)
                if commit.bookmarks.isEmpty == false {
                    Text("\(commit.bookmarks.joined(separator: ", "))")
                        .foregroundStyle(.purple)
                }
                if commit.git_head {
                    Text("git_head()").italic()
                        .foregroundStyle(.green)
                }
                if commit.root {
                    Text("root()").italic()
                        .foregroundStyle(.green)
                }
                CommitIDView(commitID: commit.commit_id)
                if commit.conflict {
                    Text("conflict()").italic()
                        .foregroundStyle(.red)
                }
            }
            .font(.subheadline)
            if commit.empty && commit.root == false {
                Text("(empty)").italic().foregroundStyle(.green)
            }

            Group {
                if commit.description.isEmpty && commit.root == false  {
                    Text("(no description set").italic()
                }
                else {
                    let description = commit.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    Text(verbatim: description).lineLimit(1)
                }
            }
            .font(.body)
        }
        Spacer()
        VStack {
            Text("\(commit.parents.count)")
            Text(commit.parents.count == 1 ? "parent" : "parents")
                .font(.caption)
        }
        .foregroundStyle(.secondary)

    }

}

struct CommitDetailView: View {

    @Environment(Repository.self)
    var repository

    var commits: OrderedDictionary<ChangeID, CommitRecord>


    var commit: CommitRecord

    @State
    var description: String = ""

    var body: some View {
        Form {
            HStack {
                ChangeIDView(changeID: commit.change_id)
                Text("|")
                CommitIDView(commitID: commit.commit_id)
            }
            LabeledContent("Author") {
                Text(commit.author.name)
                Text(commit.author.timestamp, style: .relative)
            }
            TextEditor(text: $description)
                .disabled(commit.immutable)
            if commit.description != description {
                Button("Describe") {
                    Task {
                        do {
                            let arguments = ["describe", "-r", commit.change_id.rawValue, "-m", description]
                            print("Describing commit with arguments: \(arguments)")
                            let process = SimpleAsyncProcess(executableURL: repository.binaryPath.url, arguments: arguments, currentDirectoryURL: repository.path.url)
                            _ = try await process.run()
                            print("Commit described successfully.")
                        }
                        catch {
                            print("Error describing commit: \(error)")
                        }
                    }
                }
            }


            LabeledContent("Parent") {
                ForEach(commit.parents, id: \.self) { parent in
                    HStack {
                        ChangeIDView(changeID: parent)
                        if let parentCommit = commits[parent] {
                            Text(parentCommit.description).lineLimit(1)
                        }
                    }
                }
            }

        }
        .onChange(of: commit.description) {
            description = commit.description
        }

    }
}

struct RevsetEditorView: View {
    static let revsetShortcuts: [(String, String)] = [
        ("default", ""),
        ("all", "all()"),
        ("visible_heads", "visible_heads()"),
        ("latest 10", "latest(all(), 10)"),
        ("merges", "merges()"),
        ("empty", "empty()"),
        ("empty description", "description(exact:\"\")"),
        ("WIP description", "description(\"WIP\")"),
        ("mine", "mine()"),
        ("not mine", "~mine()"),
        ("conflicts", "conflicts()"),
        ("immutable", "immutable()"),
        ("tagged", "tags()"),
        ("remote_bookmarks", "remote_bookmarks()"),
    ]

    @Binding
    var revisionQuery: String

    var submit: (String) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    TextField("revset", text: $revisionQuery).monospaced()
                        .onSubmit {
                            submit(revisionQuery)
                        }
                    Button("Refresh") {
                        submit(revisionQuery)
                    }
                }
                HStack {
                    ForEach(Self.revsetShortcuts, id: \.0) { name, query in
                        Button(name) {
                            revisionQuery = query
                            submit(revisionQuery)
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                    }
                }
            }

        }

    }
}

struct RevisionTimelineView: View {

    @State
    var repository = Repository(path: "/Users/schwa/Projects/Ultraviolence")

    @State
    var head: ChangeID?

    @Binding
    var selection: Set<ChangeID>

    @Binding
    var commits: OrderedDictionary<ChangeID, CommitRecord>

    var body: some View {
        List(commits.values, selection: $selection) { commit in
            HStack {
                if commit.immutable {
                    Image(systemName: "diamond.fill")
                }
                else {
                    if commit.change_id == head {
                        Text("@")
                    }
                    else {
                        Image(systemName: "circle")
                    }
                }
                CommitRowView(commit: commit)
            }
        }

    }
}

struct RevisionTimelineViewNEW: View {

    @State
    var repository = Repository(path: "/Users/schwa/Projects/Ultraviolence")

    @State
    var head: ChangeID?

    @Binding
    var selection: Set<ChangeID>

    @Binding
    var commits: OrderedDictionary<ChangeID, CommitRecord>

    var body: some View {


        let rows = buildGraphRows(from: Array(commits.values), allCommits: self.commits)
        let columnCount = rows.map { row -> Int in
            switch row {
            case let .commit(_, _, lanes):
                return lanes.count
            case let .elision(_, _):
                return 0
            }
        }.max() ?? 0


        List(Array(rows.enumerated()), id: \.offset) { index, row in
            HStack {
                Group {
                    switch row {
                    case let .commit(commit, _, lanes):
                        LanesView(row: row, columnCount: columnCount)
//                        CommitGraphRowView(row: row, columnCount: columnCount)
                    case let .elision(parents, lanes):
                        Text("...")
                    }
                }
                .frame(width: 12 * CGFloat(columnCount))

                switch row {
                case let .commit(commit, _, _):
                    CommitRowView(commit: commit)
                case let .elision(parents, _):
                    Spacer()
                }

            }


        }

    }
}

extension Dictionary {
    init(_ orderedDictionary: OrderedDictionary<Key, Value>) {
        self.init(uniqueKeysWithValues: Array(orderedDictionary))
    }
}

struct RawTimelineView: View {
    @Environment(Repository.self)
    var repository

    var revisionQuery: String

    var body: some View {
        ViewAdaptor<LocalProcessTerminalView> {
            return LocalProcessTerminalView(frame: .zero)
        }
        update: { view in
            var env = Terminal.getEnvironmentVariables(termName: "xterm-256color")
            FSPath.currentDirectory = repository.path
            env.append("PWD=\(repository.path.path)")
            var args = ["log"]
            if revisionQuery.isEmpty == false {
                args.append(contentsOf: ["-r", revisionQuery])
            }



            view.startProcess(executable: repository.binaryPath.path, args: args, environment: env)
        }
        .padding()
        .background(Color.black)
    }
}
