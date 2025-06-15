import Collections
import JudoSupport
import SwiftUI

struct MixedModeChangeDetailView: View {
    @Environment(AppModel.self)
    var appModel

    @Environment(Repository.self)
    var repository

    // TODO: This is not getting reloaded when description changes??
    var change: Change

    @State
    private var description: String = ""

    var body: some View {
        Form {
            HStack {
                IDView(change.changeID, variant: .changeID)
                Text("|")
                IDView(change.commitID, variant: .commitID)
            }
            LabeledContent("Author") {
                ContactView(name: change.author.name, email: change.author.email)
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
                                    let arguments = ["-r", change.changeID.description, "-m", description]
                                    _ = try await appModel.jujutsu.run(subcommand: "describe", arguments: arguments, repository: repository)
                                } catch {
                                    logger?.error("Error describing change: \(error)")
                                }
                            }
                        }
                    }
                }
            }

            LabeledContent("Parent") {
                ForEach(change.parents, id: \.self) { parent in
                    HStack {
                        IDView(parent, variant: .changeID)
                        if let parentChange = repository.currentLog.changes[parent] {
                            Text(parentChange.description).lineLimit(1)
                        }
                    }
                }
            }

            AsyncValueView { value in
                List(value.diff.files, id: \.path) { f in
                    VStack {
                        HStack {
                            Text(describing: f.path)
                            Text(describing: f.status)
                        }
                        Text(describing: f.source.path)
                        Text(describing: f.source.conflict)
                        Text(describing: f.source.fileType)
                        Text(describing: f.source.executable)
                        Text(describing: f.target.path)
                        Text(describing: f.target.conflict)
                        Text(describing: f.target.fileType)
                        Text(describing: f.target.executable)
                    }
                }
                .debugBackground()
            }
            task: {
                try await repository.fullChange(change: change.changeID)
            }
            .id(change.changeID)
        }
        .onChange(of: change.description) {
            description = change.description
        }
    }
}

struct AsyncValueView<Value, Content>: View where Content: View, Value: Sendable {
    @ViewBuilder
    var content: (Value) -> Content
    var task: () async throws -> Value

    @State
    private var result: Result<Value, Error>?

    var body: some View {
        Group {
            switch result {
            case .none:
                ProgressView()

            case .some(.success(let value)):
                content(value)

            case .some(.failure(let error)):
                ContentUnavailableView {
                    Text("Error: \(error.localizedDescription)")
                }
            }
        }
        .task {
            do {
                let value = try await task()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
        }
    }
}
