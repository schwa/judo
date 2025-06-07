import SwiftUI

public extension Color {
    static let magenta = Color(nsColor: .magenta)

    static let judoBookmarkColor = Color.purple
    static let judoHeadColor = Color.green
    static let judoConflictColor = Color.red
    static let judoShortChangeIDColor = Color.blue
    static let judoShortCommitIDColor = Color.magenta
    static let judoEmptyCommitLabelColor = Color.green
    static let judoLanesColor = Color.black
    static let judoTimestampColor = Color.cyan
}

public extension Color {
}

public extension ShapeStyle where Self == Color {
    static var magenta: Self { .magenta }

    static var judoBookmarkColor: Self { .judoBookmarkColor }
    static var judoHeadColor: Self { .judoHeadColor}
    static var judoConflictColor: Self { .judoConflictColor}
    static var judoShortChangeIDColor: Self { .judoShortChangeIDColor}
    static var judoShortCommitIDColor: Self { .judoShortCommitIDColor}
    static var judoEmptyCommitLabelColor: Self { .judoEmptyCommitLabelColor}
    static var judoLanesColor: Self { .judoLanesColor}
    static var judoTimestampColor: Self { .judoTimestampColor}
}
