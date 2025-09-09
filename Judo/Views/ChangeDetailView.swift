import JudoSupport
import SwiftUI

struct ChangeDetailView: View {
    @Environment(AppModel.self)
    var appModel

    @Environment(RepositoryViewModel.self)
    var repositoryViewModel

    @State
    private var editedDescription: String = ""

    @State
    var selectedFile: String? // TODO: FIlePath?

    // TODO: #8 This is not getting reloaded when description changes??
    var change: Change

    var body: some View {
        NavigationSplitView {
            sidebar
            .frame(minWidth: 320)
        }
        detail: {
            detail
        }
        .onChange(of: change.description, initial: true) {
            editedDescription = change.description
        }
    }

    @ViewBuilder
    var sidebar: some View {
        VSplitView {
            metadata
            entries
        }
    }

    @ViewBuilder
    var detail: some View {
        AsyncValueView { data in
            GitDiffingView(data: data)
        }
        task: {
            try await repositoryViewModel.repository.runner.run(subcommand: "diff", arguments: ["-r", change.changeID.description, "--git"], invalidatesCache: false)
        }
        .id(change.changeID)
    }

    @ViewBuilder
    var metadata: some View {
        Form {
            IDView(change.changeID, variant: .changeID)
            IDView(change.commitID, variant: .commitID)
            HStack {
                Image(systemName: "gear")
                ContactView(name: change.author.name, email: change.author.email)
                Text("\(change.author.timestamp, style: .relative)")
            }
            TextEditor(text: $editedDescription)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .frame(maxHeight: 120)
        }
        .padding()
    }

    @ViewBuilder
    var entries: some View {
        AsyncValueView { value in
            if value.diff.files.isEmpty {
                ContentUnavailableView("No files", systemImage: "gear")
            } else {
                List(value.diff.files, id: \.path, selection: $selectedFile) { f in
                    HStack {
                        f.status.view
                        Text(describing: f.path)
                    }
                }
            }
        }
        task: {
            try await repositoryViewModel.repository.fullChange(jujutsu: appModel.jujutsu, change: change.changeID)
        }
        .id(change.changeID)
    }
}

extension TreeDiffEntry.Status {
    var view: some View {
        switch self {
        case .modified:
            Image(systemName: "pencil")
                .foregroundStyle(.white)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 2))

        case .added:
            Image(systemName: "plus")
                .foregroundStyle(.white)
                .background(Color.green, in: RoundedRectangle(cornerRadius: 2))

        case .removed:
            Image(systemName: "minus")
                .foregroundStyle(.white)
                .background(Color.red, in: RoundedRectangle(cornerRadius: 2))

        case .copied:
            Image(systemName: "doc.on.doc")
                .foregroundStyle(.white)
                .background(Color.cyan, in: RoundedRectangle(cornerRadius: 2))

        case .renamed:
            Image(systemName: "arrow.right.arrow.left")
                .foregroundStyle(.white)
                .background(Color.purple, in: RoundedRectangle(cornerRadius: 2))
        }
    }
}
