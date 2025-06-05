import Collections

struct RepositoryLog {
    var revset: String?
    var commits: OrderedDictionary<ChangeID, CommitRecord>
    var head: ChangeID?

    init(revset: String? = nil, commits: OrderedDictionary<ChangeID, CommitRecord> = [:], head: ChangeID? = nil) {
        self.revset = revset
        self.commits = commits
        self.head = head
    }
}
