@testable import JudoSupport
import Testing

struct GitDiffParserTests {
    @Test func testBasicDiffParsing() throws {
        let diffText = """
        diff --git a/foo.txt b/foo.txt
        --- a/foo.txt
        +++ b/foo.txt
        @@ -1,3 +1,3 @@
         line1
        -old line
        +new line
         line3
        """
        
        let diff = GitDiffParser.parse(diffText: diffText)
        
        #expect(diff.files.count == 1)
        
        let file = diff.files[0]
        #expect(file.oldPath == "foo.txt")
        #expect(file.newPath == "foo.txt")
        #expect(file.hunks.count == 1)
        
        let hunk = file.hunks[0]
        #expect(hunk.changes.count == 4)
        #expect(hunk.changes[0].type == .unchanged)
        #expect(hunk.changes[1].type == .deletion)
        #expect(hunk.changes[2].type == .addition)
        #expect(hunk.changes[3].type == .unchanged)
    }
    
    @Test func testPrefixStripping() throws {
        let diffText = """
        diff --git a/src/main.swift b/src/main.swift
        --- a/src/main.swift
        +++ b/src/main.swift
        @@ -1 +1 @@
        -hello
        +world
        """
        
        let diff = GitDiffParser.parse(diffText: diffText)
        
        #expect(diff.files.count == 1)
        #expect(diff.files[0].oldPath == "src/main.swift")
        #expect(diff.files[0].newPath == "src/main.swift")
    }

    @Test func testRealWorldDiffParsing() throws {
        let diffText = """
        diff --git a/Judo/Views/GitDiffView.swift b/Judo/Views/GitDiffView.swift
        index c4f7bd04f8..3d2b9d79ac 100644
        --- a/Judo/Views/GitDiffView.swift
        +++ b/Judo/Views/GitDiffView.swift
        @@ -89,7 +89,7 @@
             }
         }

        -struct FileChangeHeaderView {
        +struct FileChangeHeaderView: View {

             var file: FileDiff

        diff --git a/Packages/JudoSupport/Sources/JudoSupport/GitDiff.swift b/Packages/JudoSupport/Sources/JudoSupport/GitDiff.swift
        index c97567f6b0..35ff694952 100644
        --- a/Packages/JudoSupport/Sources/JudoSupport/GitDiff.swift
        +++ b/Packages/JudoSupport/Sources/JudoSupport/GitDiff.swift
        @@ -74,9 +74,17 @@
                         currentFile = FileDiff(oldPath: "", newPath: "", hunks: [])
                         currentHunk = nil
                     } else if line.starts(with: "--- ") {
        -                currentFile?.oldPath = String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)
        +                let path = line
        +                    .removingPrefix("--- ")
        +                    .trimmingCharacters(in: .whitespaces)
        +                    .removingPrefix("a/")
        +                currentFile?.oldPath = path
                     } else if line.starts(with: "+++ ") {
        -                currentFile?.newPath = String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)
        +                let path = line
        +                    .removingPrefix("+++ ")
        +                    .trimmingCharacters(in: .whitespaces)
        +                    .removingPrefix("b/")
        +                currentFile?.newPath = path
                     } else if line.starts(with: "@@") {
                         // Finish prior hunk
                         if let hunk = currentHunk {
        diff --git a/Packages/JudoSupport/Sources/JudoSupport/Support.swift b/Packages/JudoSupport/Sources/JudoSupport/Support.swift
        index fa9128418e..318ff18077 100644
        --- a/Packages/JudoSupport/Sources/JudoSupport/Support.swift
        +++ b/Packages/JudoSupport/Sources/JudoSupport/Support.swift
        @@ -247,6 +247,13 @@
                 self.replacingOccurrences(of: "\\", with: "\\\\")
                     .replacingOccurrences(of: "\"", with: "\\\"")
             }
        +
        +    func removingPrefix(_ prefix: String) -> String {
        +        if hasPrefix(prefix) {
        +            return String(dropFirst(prefix.count))
        +        }
        +        return self
        +    }
         }

         public extension Data {
        """

        let diff = GitDiffParser.parse(diffText: diffText)

        #expect(diff.files.count == 1)

        let file = diff.files[0]
        #expect(file.oldPath == "foo.txt")
        #expect(file.newPath == "foo.txt")
        #expect(file.hunks.count == 1)

        let hunk = file.hunks[0]
        #expect(hunk.changes.count == 4)
        #expect(hunk.changes[0].type == .unchanged)
        #expect(hunk.changes[1].type == .deletion)
        #expect(hunk.changes[2].type == .addition)
        #expect(hunk.changes[3].type == .unchanged)
    }

}
