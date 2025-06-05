import SwiftUI

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
        ("remote_bookmarks", "remote_bookmarks()")
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
