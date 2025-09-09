import JudoSupport
import SwiftUI

@main
struct JudoApp: App {
    @State
    private var appModel = AppModel()

    @FocusedValue(\.repositoryViewModel)
    private var repositoryViewModel

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
        .onChange(of: repositoryViewModel?.repository.path) {
            print("Focused repository changed to \(repositoryViewModel)")
            appModel.currentRepository = repositoryViewModel?.repository
        }
        .onChange(of: appModel.id, initial: true) {
            appModel.openDocument = { try await openDocument(at: $0) }
        }
    }
}
