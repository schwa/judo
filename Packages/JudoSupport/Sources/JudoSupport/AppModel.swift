import Collections
import Everything
import Foundation
import Observation
import System
import SwiftUI

@Observable
public class AppModel: Identifiable {

    public var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }

    // TODO: #16 Cheap & cheesy persistence.
    public var binaryPath: FilePath {
        didSet {
            UserDefaults.standard.set(binaryPath.path, forKey: "judo.binaryPath")
            jujutsu.binaryPath = binaryPath
        }
    }

    // TODO: #16 standardize paths.
    public var recentRepositories: Collections.OrderedSet<FilePath> {
        didSet {
            UserDefaults.standard.set(recentRepositories.map(\.path), forKey: "judo.recentRepositories")
        }
    }

    public var jujutsu: Jujutsu
    public var currentRepository: Repository?
    public var openDocument: ((URL) async throws -> Void)?

    public init() {
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
