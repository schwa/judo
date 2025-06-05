import SwiftUI
import Everything

struct RepositoryScene: Scene {

    @Environment(AppModel.self)
    var appModel: AppModel

    var body: some Scene {
        // TODO: We should use Documents here - but trickier to do when our docs are directories.
        WindowGroup("Judo", for: FSPath.self) { path in
            if let path = path.wrappedValue {
                let repository = Repository(appModel: appModel, path: path)
                RepositoryView()
                    .environment(repository)
                    .onChange(of: path, initial: true) {
                        print("OPENING: \(path)")
                        appModel.recentRepositories.append(path)
                    }
            }
        }
    }
}
