import Everything
import JudoSupport
import SwiftTerm
import SwiftUI
import System

struct RawTimelineView: View {
    @Environment(RepositoryViewModel.self)
    var repositoryViewModel

    var revisionQuery: String

    var body: some View {
        ViewAdaptor<LocalProcessTerminalView> {
            LocalProcessTerminalView(frame: .zero)
        }
        update: { view in
            var env = Terminal.getEnvironmentVariables(termName: "xterm-256color")
            FilePath.currentDirectory = repositoryViewModel.repository.path
            env.append("PWD=\(repositoryViewModel.repository.path.path)")
            var args = ["log"]
            if revisionQuery.isEmpty == false {
                args.append(contentsOf: ["-r", revisionQuery])
            }

            view.startProcess(executable: repositoryViewModel.repository.jujutsu.binaryPath.path, args: args, environment: env)
        }
        .padding()
        .background(Color.black)
    }
}
