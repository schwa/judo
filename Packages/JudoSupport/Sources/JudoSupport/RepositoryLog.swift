import Collections

public struct RepositoryLog {
    public var revset: String?
    public var commits: OrderedDictionary<ChangeID, CommitRecord>
    public var head: ChangeID?

    public init(revset: String? = nil, commits: OrderedDictionary<ChangeID, CommitRecord> = [:], head: ChangeID? = nil) {
        self.revset = revset
        self.commits = commits
        self.head = head
    }
}
