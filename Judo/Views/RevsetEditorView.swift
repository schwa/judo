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
    var revset: String

    var submit: (String) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    TextField("revset", text: $revset).monospaced()
                        .onSubmit {
                            submit(revset)
                        }
                    Button("Refresh") {
                        submit(revset)
                    }
                }

//                ViewThatFits {
//                    ForEach(Array((1...Self.revsetShortcuts.count).reversed()), id: \.self) { count in
//                        HStack {
//                            ForEach(Self.revsetShortcuts[..<count], id: \.0) { name, query in
//                                queryButton(name: name, query: query)
//                            }
//                            let remaining = Self.revsetShortcuts[count...]
//                            if !remaining.isEmpty {
//                                Menu("…") {
//                                    ForEach(remaining, id: \.0) { name, query in
//                                        queryButton(name: name, query: query)
//                                    }
//                                }
//                                .menuStyle(.borderlessButton)
//                                .fixedSize()
//                            }
//                        }
//                    }
//                }
            }
        }
    }

    func queryButton(name: String, query: String) -> some View {
        Button(name) {
            revset = query
            submit(revset)
        }
        .fixedSize()
        .buttonStyle(.link)
        .font(.caption)
    }
}
