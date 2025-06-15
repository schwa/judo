import JudoSupport
import SwiftUI

@main
struct JudoApp: App {
    @State
    private var appModel = AppModel()

    @Environment(\.openWindow)
    var openWindow

    var body: some Scene {
        Group {
            SplashScene()
            JudoDocumentScene()
            //            RepositoryScene() // TODO: Remove.
            TemplateDemoScene()
            SettingsScene()
        }
        .environment(appModel)
    }
}
