import SwiftUI
import Everything

struct RepositoryScene: Scene {

    @Environment(AppModel.self)
    var appModel: AppModel

    var body: some Scene {
        WindowGroup("Judo", for: FSPath.self) { path in
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
