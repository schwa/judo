public struct CommitRef: Codable, Sendable {
    public var name: String

    public static let template = Template(name: "judo_bookmark", content: """
    "{'name':" ++ name.escape_json() ++ "}"
    """.replacingOccurrences(of: "'", with: "\\\""))
}

extension CommitRef: Identifiable {
    public var id: String {
        name
    }
}

//    .name() -> RefSymbol: Local bookmark or tag name.
//    .remote() -> Option<RefSymbol>: Remote name if this is a remote ref.
//    .present() -> Boolean: True if the ref points to any commit.
//    .conflict() -> Boolean: True if the bookmark or tag is conflicted.
//    .normal_target() -> Option<Commit>: Target commit if the ref is not conflicted and points to a commit.
//    .removed_targets() -> List<Commit>: Old target commits if conflicted.
//    .added_targets() -> List<Commit>: New target commits. The list usually contains one "normal" target.
//    .tracked() -> Boolean: True if the ref is tracked by a local ref. The local ref might have been deleted (but not pushed yet.)
//    .tracking_present() -> Boolean: True if the ref is tracked by a local ref, and if the local ref points to any commit.
//    .tracking_ahead_count() -> SizeHint: Number of commits ahead of the tracking local ref.
//    .tracking_behind_count() -> SizeHint: Number of commits behind of the tracking local ref.
