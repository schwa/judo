import SwiftUI
import Everything

struct ContentView: View {

    @State
    var repository = Repository(path: "/Users/schwa/Projects/Ultraviolence")

    @State
    var head: ChangeID?

    @State
    var selection: Set<CommitID> = []

    @State
    var revisionQuery: String = ""

    @State
    var commits: [CommitRecord] = []

    let revsetShortcuts: [(String, String)] = [
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

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {

                    HStack {
                        TextField("revset", text: $revisionQuery).monospaced()
                            .onSubmit {
                                Task {
                                    try await refresh()
                                }

                            }
                        Button("Refresh") {
                            Task {
                                try await refresh()
                            }
                        }
                    }
                    HStack {
                        ForEach(revsetShortcuts, id: \.0) { name, query in
                            Button(name) {
                                revisionQuery = query
                                Task {
                                    try await refresh()
                                }
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                        }
                    }
                }

            }
            .padding()

            List(commits, id: \.commit_id, selection: $selection) { commit in
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
        }
        .navigationDocument(repository.path.url)
        .navigationSubtitle("\(repository.path.description)")
        .toolbar {
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

        }
        .task {
            head = repository.head
            do {
                try await refresh()
            }
            catch {
                print("Error refreshing repository: \(error)")
            }
        }
    }

    func refresh() async throws {
        do {
            commits = try await repository.scan(revset: revisionQuery)
        }
        catch {
            print("Error scanning repository: \(error)")
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


