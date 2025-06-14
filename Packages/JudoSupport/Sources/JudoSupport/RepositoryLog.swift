import Collections

public struct RepositoryLog: Sendable {
    public var revset: String? // TODO: Make non optional
    public var changes: OrderedDictionary<ChangeID, Change>
    public var bookmarks: OrderedDictionary<String, CommitRef>

    public init(revset: String? = nil, changes: OrderedDictionary<ChangeID, Change> = [:], bookmarks: OrderedDictionary<String, CommitRef> = [:]) {
        self.revset = revset
        self.changes = changes
        self.bookmarks = bookmarks
    }
}

public extension RepositoryLog {
    func makeGraph() -> Graph<ChangeID> {

        Graph(adjacency: changes.values.map { ($0.changeID, $0.parents) })

    }
}

#if DEBUG

extension RepositoryLog {
    static func demo() -> RepositoryLog {
        var log = RepositoryLog()
        log.revset = ""
        //        log.changes["zzzzz"] = Change(changeID: <#T##ChangeID#>, commitID: <#T##CommitID#>, author: <#T##Signature#>, description: <#T##String#>, isRoot: <#T##Bool#>, isEmpty: <#T##Bool#>, isImmutable: <#T##Bool#>, isGitHead: <#T##Bool#>, isConflict: <#T##Bool#>, parents: <#T##[ChangeID]#>, bookmarks: <#T##[String]#>, totalAdded: <#T##Int#>, totalRemoved: <#T##Int#>)

        return log
    }
}


#endif
