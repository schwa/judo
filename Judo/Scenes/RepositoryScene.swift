import Everything
import JudoSupport
import SwiftUI
import System

struct RepositoryScene: Scene {
    @Environment(AppModel.self)
    var appModel: AppModel

    var body: some Scene {
        // TODO: #21 We should use Documents here - but trickier to do when our docs are directories.
        WindowGroup("Judo", for: FilePath.self) { path in
            if let path = path.wrappedValue {
                let repository = Repository(appModel: appModel, path: path)
                RepositoryView()
                    .environment(repository)
                    .onChange(of: path, initial: true) {
                        appModel.recentRepositories.append(path)
                    }
            }
        }
    }
}
