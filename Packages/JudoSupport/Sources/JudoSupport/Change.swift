public struct Change {
    public var id: ChangeID { changeID }
    public var changeID: ChangeID
    public var commitID: CommitID
    public var author: Signature
    public var description: String
    public var isRoot: Bool
    public var isEmpty: Bool
    public var isImmutable: Bool
    public var isGitHead: Bool
    public var isConflict: Bool
    public var isHead: Bool?
    public var parents: [ChangeID]
    public var bookmarks: [String]
    public var totalAdded: Int
    public var totalRemoved: Int

    // TODO: #11 Make sure everything is escaped properly (esp. parents and bookmarks
    public static let template = Template(name: "JUDO_CHANGE", content: """
        "{\\n"
        ++ "\t'change_id': " ++ JUDO_ID(change_id) ++ ",\\n"
        ++ "\t'commit_id': " ++ JUDO_ID(commit_id) ++ ",\\n"
        ++ "\t'author': " ++ JUDO_SIGNATURE(author) ++ ",\\n"
        ++ "\t'description': " ++ description.escape_json() ++ ",\\n"
        ++ "\t'root': " ++ root ++ ",\\n"
        ++ "\t'empty': " ++ empty ++ ",\\n"
        ++ "\t'git_head': " ++ git_head ++ ",\\n"
        ++ "\t'conflict': " ++ conflict ++ ",\\n"
        ++ "\t'immutable': " ++ immutable ++ ",\\n"
        ++ "\t'head': " ++ self.contained_in("@") ++ ",\\n"
        ++ "\t'diff_stat_total_added': " ++ diff.stat().total_added() ++ ",\\n"
        ++ "\t'diff_stat_total_removed': " ++ diff.stat().total_removed() ++ ",\\n"
        ++ "\t'parents': [" ++ parents.map(|c| JUDO_ID(c.change_id())).join(",") ++ "],\\n"
        ++ "\t'bookmarks': [" ++ bookmarks.map(|c| "'" ++ c ++ "'").join(",") ++ "],\\n"
        ++ "},\\n"
        """)
}

extension Change: Sendable {
}

extension Change: Equatable {
}

extension Change: Identifiable {
}

extension Change: Decodable {
    enum CodingKeys: String, CodingKey {
        case changeID = "change_id"
        case commitID = "commit_id"
        case author
        case description
        case isRoot = "root"
        case isEmpty = "empty"
        case isImmutable = "immutable"
        case isGitHead = "git_head"
        case isConflict = "conflict"
        case isHead = "head"
        case parents
        case bookmarks
        case totalAdded = "diff_stat_total_added"
        case totalRemoved = "diff_stat_total_removed"
    }
}
