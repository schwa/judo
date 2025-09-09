import Collections
import Everything
import Foundation
import Observation
import System
import SwiftUI
import JudoSupport

@Observable
class AppModel {

    // TODO: #16 Cheap & cheesy persistence.
    var binaryPath: FilePath {
        didSet {
            UserDefaults.standard.set(binaryPath.path, forKey: "judo.binaryPath")
            jujutsu.binaryPath = binaryPath
        }
    }

    // TODO: #16 standardize paths.
    var recentRepositories: Collections.OrderedSet<FilePath> {
        didSet {
            UserDefaults.standard.set(recentRepositories.map(\.path), forKey: "judo.recentRepositories")
        }
    }

    var jujutsu: Jujutsu
    var currentRepositoryViewModel: RepositoryViewModel? {
        didSet {
            print("CURRENT REPO VIEW MODEL CHANGED: \(currentRepositoryViewModel)" )
        }
    }

    @MainActor
    var openDocument: ((URL) async throws -> Void)?

    init() {
        UserDefaults.standard.register(defaults: [
            "judo.binaryPath": "/opt/homebrew/bin/jj",
            "judo.recentRepositories": []
        ])
        let binaryPath = FilePath(UserDefaults.standard.string(forKey: "judo.binaryPath")!)
        self.binaryPath = binaryPath
        recentRepositories = OrderedSet(UserDefaults.standard.array(forKey: "judo.recentRepositories")!.map { path in
            FilePath(path as! String)
        })
        jujutsu = Jujutsu(binaryPath: binaryPath)
    }
}

extension AppModel: Identifiable {
    var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}
