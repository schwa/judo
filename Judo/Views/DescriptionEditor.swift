import SwiftUI

struct DescriptionEditor: View {

    let targetCommit: CommitRecord?
    let sourceCommits: [CommitRecord]
    let isSquash: Bool
    let callback: (String) -> Void

    @State
    var description: String

    @State
    var textSelection: TextSelection? = nil

    @Environment(\.dismiss)
    var dismiss

    init(targetCommit: CommitRecord? = nil, sourceCommits: [CommitRecord] = [], isSquash: Bool = false, callback: @escaping (String) -> Void) {
        self.targetCommit = targetCommit
        self.sourceCommits = sourceCommits
        self.isSquash = isSquash
        self.callback = callback
        let description = targetCommit?.description ?? ""
        self._description = State(initialValue: description)
        self._textSelection = State(initialValue: .init(range: description.startIndex..<description.endIndex))
    }

    var body: some View {
        Form {
            if let targetCommit {
                MiniCommitView(commit: targetCommit, includeDescription: false)
            }
            TextEditor(text: $description, selection: $textSelection)
            .frame(maxHeight: .infinity)
            .textEditorStyle(.plain)
//            .aspectRatio(1.618033988749895, contentMode: .fill)
            .layoutPriority(1000)

            if isSquash {
                Section("(\(sourceCommits.count)) Squashed Commits") {
                    Button("Use All", systemImage: "doc.on.doc") {
                        let allDescriptions = sourceCommits.map { $0.description }.joined(separator: "\n")
                        description.append(contentsOf: allDescriptions)
                    }
                    .buttonStyle(.borderless)
                    .labelsHidden()
                    List(sourceCommits) { commit in
                        HStack {
                            Button("Use", systemImage: "doc.on.doc") {
                                description.append(contentsOf: commit.description)
                            }
                            .buttonStyle(.borderless)
                            .labelsHidden()
                            MiniCommitView(commit: commit)
                        }
                    }
                    .frame(minHeight: 50)
                }
                .layoutPriority(0)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("OK") {
                    dismiss()
                    callback(description)
                }

            }
        }
    }
}

struct MiniCommitView: View {
    var commit: CommitRecord
    var includeDescription: Bool = true

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(commit.change_id.shortAttributedString).foregroundStyle(.secondary)
                .textSelection(.enabled)

                Text("|")
                Text(commit.commit_id.shortAttributedString).foregroundStyle(.secondary)
                .textSelection(.enabled)

                MiniSignatureView(signature: commit.author)
            }
            if includeDescription {
                Text(commit.description)
            }
        }
    }

}

struct MiniSignatureView: View {
    var signature: Signature

    var body: some View {
        (Text(signature.name) + Text(" (") + Text(signature.timestamp, style: .relative) + Text(")"))
        .textSelection(.enabled)
    }

}
