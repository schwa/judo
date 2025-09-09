import JudoSupport
import SwiftUI

@main
struct JudoApp: App {
    @State
    private var appModel = AppModel()

    @FocusedValue(Repository.self)
    private var repository

    var body: some Scene {
        Group {
            SplashScene()
            JudoDocumentScene()
            TemplateDemoScene()
            SettingsScene()
        }
        .environment(appModel)
        .onChange(of: repository?.path) {
            print("REPO CHANGED: \(repository?.path)")
        }
    }
}
