import Observation
import JudoSupport
import SwiftUI
import Collections
import System

@Observable
class RepositoryViewModel {
    enum Mode: Hashable, CaseIterable {
        case timeline
        case mixed
        case change
    }
    
    var repository: Repository
    var jujutsu: Jujutsu
    var currentLog: RepositoryLog = RepositoryLog()
    var mode: Mode = .mixed
    var selection: Set<ChangeID> = []
    
    // Action runner related properties
    var actionRunner: ActionRunner?
    var actionStatus: Status = .waiting
    var actionPreview: ActionPreview?

    init(jujutsu: Jujutsu, path: FilePath) {
        self.jujutsu = jujutsu
        self.repository = Repository(path: path, jujutsu: jujutsu)
    }
    
    func setupActionRunner() {
        actionRunner = ActionRunner(
            status: Binding(
                get: { self.actionStatus },
                set: { self.actionStatus = $0 }
            ),
            preview: Binding(
                get: { self.actionPreview },
                set: { self.actionPreview = $0 }
            )
        )
    }
}

extension FocusedValues {
    @Entry
    var repositoryViewModel: RepositoryViewModel?
}

extension RepositoryViewModel: Identifiable {
    var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}

extension RepositoryViewModel {
    func refreshLog() async throws {
        currentLog = try await repository.log(jujutsu: jujutsu, revset: currentLog.revset ?? "")
    }

    func log(revset: String) async throws {
        currentLog = try await repository.log(jujutsu: jujutsu, revset: revset)
    }
}
