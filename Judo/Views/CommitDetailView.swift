import Collections
import SwiftUI
import JudoSupport

struct CommitDetailView: View {
    @Environment(AppModel.self)
    var appModel

    @Environment(Repository.self)
    var repository

    var commits: OrderedDictionary<ChangeID, CommitRecord>

    // TODO: This is not getting reloaded when description changes??
    var commit: CommitRecord

    @State
    private var description: String = ""

    var body: some View {
        Form {
            HStack {
                IDView(commit.change_id, style: .changeID)
                Text("|")
                IDView(commit.commit_id, style: .commitID)
            }
            LabeledContent("Author") {
                Text(commit.author.name)
                Text(commit.author.timestamp, style: .relative)
            }
            TextEditor(text: $description)
                .disabled(commit.immutable)
            HStack {
                if !commit.immutable {
                    Spacer()
                    if commit.description != description {
                        Button("Describe") {
                            Task {
                                do {
                                    let arguments = ["describe", "-r", commit.change_id.description, "-m", description]
                                    print("Describing commit with arguments: \(arguments)")
                                    let process = SimpleAsyncProcess(executableURL: repository.binaryPath.url, arguments: arguments, currentDirectoryURL: repository.path.url)
                                    _ = try await process.run()
                                    print("Commit described successfully.")
                                } catch {
                                    print("Error describing commit: \(error)")
                                }
                            }
                        }
                    }
                }
            }

            LabeledContent("Parent") {
                ForEach(commit.parents, id: \.self) { parent in
                    HStack {
                        IDView(parent, style: .changeID)
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
