import Observation
import Everything
import Foundation
import Collections

@Observable
class AppModel {
    // TODO: Cheap & cheesy persistence.
    var binaryPath: FSPath {
        didSet {
            UserDefaults.standard.set(binaryPath.path, forKey: "judo.binaryPath")
        }
    }

    // TODO: standardize paths.
    var recentRepositories: Collections.OrderedSet<FSPath> {
        didSet {
            UserDefaults.standard.set(recentRepositories.map { $0.path }, forKey: "judo.recentRepositories")
        }
    }

    var isNewTimelineViewEnabled = true

    init() {
        UserDefaults.standard.register(defaults: [
            "judo.binaryPath": "/opt/homebrew/bin/jj",
            "judo.recentRepositories": [],
        ])
        binaryPath = FSPath(UserDefaults.standard.string(forKey: "judo.binaryPath")!)
        recentRepositories = OrderedSet(UserDefaults.standard.array(forKey: "judo.recentRepositories")!.map { path in
            return FSPath(path as! String)
        })
    }
}
