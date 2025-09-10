import JudoSupport
import SwiftUI

struct ChangeDetailView: View {
    @Environment(AppModel.self)
    var appModel

    @Environment(RepositoryViewModel.self)
    var repositoryViewModel

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
        ChangeMetadataFullView(change: change)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    var entries: some View {
        AsyncValueView { value in
            if value.diff.files.isEmpty {
                ContentUnavailableView("No files", systemImage: "gear")
            } else {
                List(value.diff.files, id: \.path, selection: $selectedFile) { f in
                    HStack {
                        f.status.view.frame(width: 18, height: 18)
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

    var color: Color {
        switch self {
            case .modified: return .blue
            case .added: return .green
            case .removed: return .red
            case .copied: return .cyan
            case .renamed: return .purple
        }
    }

    var systemImageName: String {
        switch self {
        case .modified: return "pencil"
        case .added: return "plus"
        case .removed: return "minus"
        case .copied: return "doc.on.doc"
        case .renamed: return "arrow.right.arrow.left"
        }
    }

    var view: some View {
        ZStack {
            color
                .aspectRatio(1, contentMode: .fill)
            Image(systemName: systemImageName)
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    VStack {
        ForEach(TreeDiffEntry.Status.allCases, id: \.self) { status in
            status.view
                .frame(width: 50)
                .padding()
                .border(Color.black)
        }
    }
    .padding()
}
