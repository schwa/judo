import JudoSupport
import SwiftUI


struct ChangeDescriptionView: View {
    let change: Change

    var body: some View {
        Text(change.description.isEmpty ? "No description" : change.description)
            .foregroundStyle(change.description.isEmpty ? .secondary : .primary)
    }
}


struct ChangeDescriptionEditor: View {
    @Environment(AppModel.self)
    private var appModel
    
    @Environment(RepositoryViewModel.self)
    private var repositoryViewModel
    
    let change: Change
    
    @State
    private var editedDescription: String = ""
    
    @State
    private var isEditingDescription = false
    
    init(change: Change) {
        self.change = change
    }
    
    var body: some View {
        Group {
            if isEditingDescription {
                editingView
            } else {
                displayView
            }
        }
        .onChange(of: change.description, initial: true) {
            if !isEditingDescription {
                editedDescription = change.description
            }
        }
    }
    
    @ViewBuilder
    private var displayView: some View {
        Text(change.description.isEmpty ? "No description" : change.description)
            .foregroundStyle(change.description.isEmpty ? .secondary : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if !change.isImmutable {
                    startEditing()
                }
            }
            .contextMenu {
                if !change.isImmutable {
                    Button("Edit Description") {
                        startEditing()
                    }
                }
                if !change.description.isEmpty {
                    CopyButton("Description", value: change.description)
                }
            }
    }
    
    @ViewBuilder
    private var editingView: some View {
        TextEditor(text: $editedDescription)
            .font(.body)
            .frame(minHeight: 60, maxHeight: 120)
        HStack {
            Button("Cancel") {
                cancelEditing()
            }
            .buttonStyle(.plain)
            
            Button("Save") {
                Task {
                    await saveDescription()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(editedDescription == change.description)
        }
    }
    
    private func startEditing() {
        editedDescription = change.description
        isEditingDescription = true
    }
    
    private func cancelEditing() {
        editedDescription = change.description
        isEditingDescription = false
    }
    
    @MainActor
    private func saveDescription() async {
        do {
            try await repositoryViewModel.repository.describe(
                jujutsu: appModel.jujutsu,
                changes: [change.changeID],
                description: editedDescription
            )
            isEditingDescription = false
            try await repositoryViewModel.refreshLog()
        } catch {
            print("Failed to update description: \(error)")
            // Reset to original on error
            editedDescription = change.description
            isEditingDescription = false
        }
    }
}
