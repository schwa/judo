import SwiftUI
import JudoSupport

struct ChangeDetailView: View {

    @Environment(AppModel.self)
    var appModel

    @Environment(Repository.self)
    var repository

    @State
    var editedDescription: String = ""

    // TODO: This is not getting reloaded when description changes??
    var change: Change

    var body: some View {

        HSplitView {
            sidebar
            .frame(minWidth: 200)
            .border(Color.red)
            detail
            .frame(minWidth: 200, maxWidth: .infinity, maxHeight: .infinity)
            .border(Color.red)
        }
        .border(Color.red)

//        NavigationSplitView {
//        } detail: {
//        }
        .onChange(of: change.description, initial: true) {
            editedDescription = change.description
        }
    }

    @ViewBuilder
    var sidebar: some View {
        VSplitView {
            metadata
                .frame(minHeight: 200)
            entries
                .frame(minHeight: 200)
        }
    }

    @ViewBuilder
    var detail: some View {
        AsyncValueView { data in
            GitDiffingView(data: data)
        }
        task: {
            let data = try await appModel.jujutsu.run(subcommand: "diff", arguments: ["-r", change.changeID.description, "--git"], repository: repository)
            return data
        }
        .id(change.changeID)
    }

    @ViewBuilder
    var metadata: some View {
        Form {
            IDView(change.changeID, variant: .changeID)
            IDView(change.commitID, variant: .commitID)
            TextEditor(text: $editedDescription)
                .font(.body)
            HStack {
                Image(systemName: "gear")
                ContactView(name: change.author.name, email: change.author.email)
                Text("\(change.author.timestamp, style: .relative)")
            }
            HStack {
                Image(systemName: "gear")
                ContactView(name: change.author.name, email: change.author.email)
                Text("\(change.author.timestamp, style: .relative)")
            }
        }
        .padding()
    }

    @ViewBuilder
    var entries: some View {
        VStack {
            AsyncValueView { value in
                if value.diff.files.isEmpty {
                    ContentUnavailableView("No files", systemImage: "gear")
                }
                else {
                    List(value.diff.files, id: \.path) { f in
                        HStack {
                            f.status.view
                            Text(describing: f.path)
                        }
                    }
                }
            }
            task: {
                try await repository.fullChange(change: change.changeID)
            }
            .id(change.changeID)
        }
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
