import SwiftUI

@main
struct JudoApp: App {
    @State
    var appModel: AppModel = AppModel()

    @Environment(\.openWindow)
    var openWindow

    var body: some Scene {
        Group {
            WindowGroup {
                ContentView()
            }

            WindowGroup(id: "template-demo") {
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
        .environment(appModel)
    }
}

