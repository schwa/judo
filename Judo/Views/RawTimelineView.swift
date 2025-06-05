import Everything
import SwiftUI
import SwiftTerm

struct RawTimelineView: View {
    @Environment(Repository.self)
    var repository

    var revisionQuery: String

    var body: some View {
        ViewAdaptor<LocalProcessTerminalView> {
            LocalProcessTerminalView(frame: .zero)
        }
        update: { view in
            var env = Terminal.getEnvironmentVariables(termName: "xterm-256color")
            FSPath.currentDirectory = repository.path
            env.append("PWD=\(repository.path.path)")
            var args = ["log"]
            if revisionQuery.isEmpty == false {
                args.append(contentsOf: ["-r", revisionQuery])
            }

            view.startProcess(executable: repository.binaryPath.path, args: args, environment: env)
        }
        .padding()
        .background(Color.black)
    }
}
