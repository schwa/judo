import Collections
import SwiftUI
import JudoSupport

struct ChangeDetailView: View {
    @Environment(AppModel.self)
    var appModel

    @Environment(Repository.self)
    var repository

    var changes: OrderedDictionary<ChangeID, Change>

    // TODO: This is not getting reloaded when description changes??
    var change: Change

    @State
    private var description: String = ""

    var body: some View {
        Form {
            HStack {
                IDView(change.changeID, style: .changeID)
                Text("|")
                IDView(change.commitID, style: .commitID)
            }
            LabeledContent("Author") {
                Text(change.author.name)
                Text(change.author.timestamp, style: .relative)
            }
            TextEditor(text: $description)
                .disabled(change.isImmutable)
            HStack {
                if !change.isImmutable {
                    Spacer()
                    if change.description != description {
                        Button("Describe") {
                            Task {
                                do {
                                    let arguments = ["describe", "-r", change.changeID.description, "-m", description]
                                    print("Describing commit with arguments: \(arguments)")
                                    let process = SimpleAsyncProcess(executableURL: repository.binaryPath.url, arguments: arguments, currentDirectoryURL: repository.path.url)
                                    _ = try await process.run()
                                    print("Change described successfully.")
                                } catch {
                                    print("Error describing change: \(error)")
                                }
                            }
                        }
                    }
                }
            }

            LabeledContent("Parent") {
                ForEach(change.parents, id: \.self) { parent in
                    HStack {
                        IDView(parent, style: .changeID)
                        if let parentChange = changes[parent] {
                            Text(parentChange.description).lineLimit(1)
                        }
                    }
                }
            }
        }
        .onChange(of: change.description) {
            description = change.description
        }
    }
}
