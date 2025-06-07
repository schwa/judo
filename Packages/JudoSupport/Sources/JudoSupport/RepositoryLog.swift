import Collections

public struct RepositoryLog {
    public var revset: String?
    public var commits: OrderedDictionary<ChangeID, CommitRecord>

    public init(revset: String? = nil, commits: OrderedDictionary<ChangeID, CommitRecord> = [:]) {
        self.revset = revset
        self.commits = commits
    }
}
