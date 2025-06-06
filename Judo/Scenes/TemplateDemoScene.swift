import SwiftUI
import JudoSupport

struct TemplateDemoScene: Scene {
    @Environment(\.openWindow)
    var openWindow

    var body: some Scene {
        Window(Text("Template Demo"), id: "template-demo") {
            TemplateDemoView()
        }
        .commands {
            CommandGroup(after: .singleWindowList) {
                Button("Template Demo") {
                    openWindow(id: "template-demo")
                }
            }
        }
    }
}


struct TemplateDemoView: View {

    @Environment(AppModel.self)
    private var appModel

    @State
    private var path: String = "/Users/schwa/Projects/Ultraviolence"

    @State
    private var template: String = ""

    @State
    private var revset: String = ""

    @State
    private var output: String = ""

    var body: some View {
        VStack {
            Form {
                TextField("Path", text: $path)
                TextField("Template", text: $template)
                TextField("Revset", text: $revset)
                Button("Run") {
                    run()
                }
            }
            .padding()
            ScrollView {
                Text(output).frame(maxWidth: .infinity).monospaced()
            }
        }
    }

    func run() {
        Task {
            var arguments: [String] = ["log"]

            if !revset.isEmpty {
                arguments.append(contentsOf: ["-r", revset])
            }
            if !template.isEmpty {
                arguments.append(contentsOf: ["--template", template])
            }

            let process = SimpleAsyncProcess(executableURL: appModel.binaryPath.url, arguments: arguments, currentDirectoryURL: URL(fileURLWithPath: path))
            do {
                let data = try await process.run()
                output = String(data: data, encoding: .utf8) ?? "Failed to decode output"
            } catch {
                output = "Error: \(error)"
            }
        }
    }
}
