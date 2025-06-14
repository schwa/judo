import SwiftUI
import JudoSupport

@main
struct JudoApp: App {
    @State
    var appModel: AppModel = AppModel()

    @Environment(\.openWindow)
    var openWindow

    var body: some Scene {
        Group {
            SplashScene()
            JudoDocumentScene()
            RepositoryScene() // TODO: Remove.
            TemplateDemoScene()
            SettingsScene()
        }
        .environment(appModel)
    }
}

