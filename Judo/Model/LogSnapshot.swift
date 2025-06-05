
import Collections
import Everything
import Foundation
import Observation
import TOMLKit

@Observable
public class LogSnapshot {
    var repository: Repository
    var revset: String
    var commits: OrderedDictionary<ChangeID, CommitRecord>

    init(repository: Repository, revset: String, commits: OrderedDictionary<ChangeID, CommitRecord>) {
        self.repository = repository
        self.revset = revset
        self.commits = commits
    }
}
