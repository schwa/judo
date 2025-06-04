import SwiftUI

struct TemplateDemoView: View {
    @State
    var template: String = ""

    @State
    var revset: String = ""

    @State
    var output: String = ""

    var body: some View {
        VStack {
            TextField("Template", text: $template)
            TextField("Revset", text: $revset)
            Button("Run") {
                run()
            }
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

            let process = SimpleAsyncProcess(executableURL: URL(fileURLWithPath: "/opt/homebrew/bin/jj"), arguments: arguments, currentDirectoryURL: URL(fileURLWithPath: "/Users/schwa/Projects/Ultraviolence"))
            do {
                let data = try await process.run()
                output = String(data: data, encoding: .utf8) ?? "Failed to decode output"
            } catch {
                output = "Error: \(error)"
            }
        }
    }
}
