import JudoSupport
import SwiftUI

struct DescriptionEditor: View {
    let targetChange: Change?
    let sourceChanges: [Change]
    let isSquash: Bool
    let callback: (String) -> Void

    @State
    private var description: String

    @State
    private var textSelection: TextSelection?

    @Environment(\.dismiss)
    var dismiss

    init(targetChange: Change? = nil, sourceChanges: [Change] = [], isSquash: Bool = false, callback: @escaping (String) -> Void) {
        self.targetChange = targetChange
        self.sourceChanges = sourceChanges
        self.isSquash = isSquash
        self.callback = callback
        let description = targetChange?.description ?? ""
        self._description = State(initialValue: description)
        self._textSelection = State(initialValue: .init(range: description.startIndex..<description.endIndex))
    }

    var body: some View {
        Form {
            if let targetChange {
                MiniChangeView(change: targetChange, includeDescription: false)
            }
            TextEditor(text: $description, selection: $textSelection)
                .frame(maxHeight: .infinity)
                .textEditorStyle(.plain)
                //            .aspectRatio(1.618033988749895, contentMode: .fill)
                .layoutPriority(1_000)

            if isSquash {
                Section("(\(sourceChanges.count)) Squashed Changes") {
                    Button("Use All", systemImage: "doc.on.doc") {
                        let allDescriptions = sourceChanges.map(\.description).joined(separator: "\n")
                        description.append(contentsOf: allDescriptions)
                    }
                    .buttonStyle(.borderless)
                    .labelsHidden()
                    List(sourceChanges) { change in
                        HStack {
                            Button("Use", systemImage: "doc.on.doc") {
                                description.append(contentsOf: change.description)
                            }
                            .buttonStyle(.borderless)
                            .labelsHidden()
                            MiniChangeView(change: change)
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

struct MiniChangeView: View {
    var change: Change
    var includeDescription: Bool = true

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                IDView(change.changeID, variant: .changeID)
                Text("|")
                IDView(change.commitID, variant: .commitID)

                MiniSignatureView(signature: change.author)
            }
            if includeDescription {
                Text(change.description)
            }
        }
    }
}

struct MiniSignatureView: View {
    var signature: Signature

    var body: some View {
        Text("\(signature.name) (\(signature.timestamp, style: .relative))")
            .textSelection(.enabled)
    }
}
