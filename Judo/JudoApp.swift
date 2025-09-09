import JudoSupport
import SwiftUI

@main
struct JudoApp: App {
    @State
    private var appModel = AppModel()

    @FocusedValue(Repository.self)
    private var repository

    @Environment(\.openDocument)
    var openDocument

    var body: some Scene {
        Group {
            SplashScene()
            JudoDocumentScene()
            TemplateDemoScene()
            SettingsScene()
        }
        .environment(appModel)
        .onChange(of: repository?.path) {
            appModel.currentRepository = repository
        }
        .onChange(of: appModel.id, initial: true) {
            appModel.openDocument = { try await openDocument(at: $0) }
        }
    }
}
