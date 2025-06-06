import Observation
import Everything
import Foundation
import Collections

@Observable
public class AppModel {
    // TODO: Cheap & cheesy persistence.
    public var binaryPath: FSPath {
        didSet {
            UserDefaults.standard.set(binaryPath.path, forKey: "judo.binaryPath")
            jujutsu.binaryPath = binaryPath
        }
    }

    // TODO: standardize paths.
    public var recentRepositories: Collections.OrderedSet<FSPath> {
        didSet {
            UserDefaults.standard.set(recentRepositories.map { $0.path }, forKey: "judo.recentRepositories")
        }
    }

    public var isNewTimelineViewEnabled = true

    public var jujutsu: Jujutsu

    public init() {
        UserDefaults.standard.register(defaults: [
            "judo.binaryPath": "/opt/homebrew/bin/jj",
            "judo.recentRepositories": [],
        ])
        let binaryPath = FSPath(UserDefaults.standard.string(forKey: "judo.binaryPath")!)
        self.binaryPath = binaryPath
        recentRepositories = OrderedSet(UserDefaults.standard.array(forKey: "judo.recentRepositories")!.map { path in
            return FSPath(path as! String)
        })
        jujutsu = Jujutsu(binaryPath: binaryPath)
    }
}
