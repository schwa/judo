import SwiftUI
import Everything

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

            Section(header: Text("Debug"), footer: Text("(these settings are not persistent))")) {
                Toggle("isNewTimelineViewEnabled", isOn: $appModel.isNewTimelineViewEnabled)

            }

        }
        .frame(width: 480, height: 320)
        .padding()

    }
}
