import SwiftUI
import Everything
import JudoSupport

struct SettingsScene: Scene {
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @Environment(AppModel.self)
    var appModel

    @Environment(\.openWindow)
    var openWindow

    @State
    var binaryPath: String = ""

    var body: some View {
        @Bindable
        var appModel = appModel

        Form {
            TextField("Binary Path", text: $binaryPath)
                .onChange(of: appModel.binaryPath, initial: true) {
                    binaryPath = appModel.binaryPath.path
                }
                .onChange(of: binaryPath) {
                    appModel.binaryPath = FSPath(binaryPath)
                }

            Spacer()

            Section(header: Text("Debug")) {

                Button("Generate Demo Repo") {
                    Task {
                        let scriptURL = Bundle.main.url(forResource: "generate-demo-repo", withExtension: "sh")!
                        _ = try await SimpleAsyncProcess(executableURL: scriptURL, useShell: true).run()
//                        print(String(data: data, encoding: .utf8) ?? "No output")
                        openWindow(value: FSPath("/tmp/fake-repo"))
                    }
                }
            }
        }
        .frame(width: 480, height: 320)
        .padding()

    }
}
