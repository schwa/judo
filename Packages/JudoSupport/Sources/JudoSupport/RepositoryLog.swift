import Collections

public struct RepositoryLog {
    public var revset: String?
    public var changes: OrderedDictionary<ChangeID, Change>

    public init(revset: String? = nil, changes: OrderedDictionary<ChangeID, Change> = [:]) {
        self.revset = revset
        self.changes = changes
    }
}
