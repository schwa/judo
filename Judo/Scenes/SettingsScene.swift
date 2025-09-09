import Everything
import JudoSupport
import Subprocess
import SwiftUI
import System

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
    private var binaryPath: String = ""

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
            
            Section(header: Text("Command Line Interface")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Drag the 'judo' command to install it in your PATH")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "terminal.fill")
                            .font(.largeTitle)
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading) {
                            Text("judo")
                                .font(.headline)
                            Text("Command-line tool v1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .onDrag {
                        // Create a file provider for the judo.sh script
                        if let scriptURL = Bundle.main.url(forResource: "judo", withExtension: "sh") {
                            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("judo")
                            try? FileManager.default.copyItem(at: scriptURL, to: tempURL)
                            
                            // Make it executable
                            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempURL.path)
                            
                            return NSItemProvider(object: tempURL as NSURL)
                        }
                        return NSItemProvider()
                    }
                    
                    Text("Drag to /usr/local/bin, ~/.local/bin, or any directory in your PATH")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

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
        .frame(width: 480, height: 380)
        .padding()
    }
}
