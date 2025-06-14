import SwiftUI
import Everything
import JudoSupport
import System
import Subprocess

struct SettingsScene: Scene {
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @SwiftUI.Environment(AppModel.self)
    var appModel

    @SwiftUI.Environment(\.openWindow)
    var openWindow

    @AppStorage("judo.debug-ui")
    var debugUI: Bool = false

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
                    appModel.binaryPath = FilePath(binaryPath)
                }

            Spacer()

            Section(header: Text("Debug")) {

                Toggle("Debug UI", isOn: $debugUI)

                Button("Generate Demo Repo") {
                    Task {
                        let scriptURL = Bundle.main.url(forResource: "generate-demo-repo", withExtension: "sh")!
                        _ = try! await run(.path(FilePath(scriptURL.path)), useShell: true)
                        openWindow(value: FilePath("/tmp/fake-repo"))
                    }
                }
            }
        }
        .frame(width: 480, height: 320)
        .padding()
    }
}

