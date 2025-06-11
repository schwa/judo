import Collections

public struct RepositoryLog: Sendable {
    public var revset: String?
    public var changes: OrderedDictionary<ChangeID, Change>
    public var bookmarks: OrderedDictionary<String, CommitRef>


    public init(revset: String? = nil, changes: OrderedDictionary<ChangeID, Change> = [:], bookmarks: OrderedDictionary<String, CommitRef> = [:]) {
        self.revset = revset
        self.changes = changes
        self.bookmarks = bookmarks
    }
}
