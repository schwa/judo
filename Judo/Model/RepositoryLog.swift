import Collections

struct RepositoryLog {
    var repository: Repository
    var revset: String?
    var commits: OrderedDictionary<ChangeID, CommitRecord>

    init(repository: Repository, revset: String?, commits: OrderedDictionary<ChangeID, CommitRecord>) {
        self.repository = repository
        self.revset = revset
        self.commits = commits
    }
}
