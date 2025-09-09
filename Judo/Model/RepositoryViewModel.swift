import Observation
import JudoSupport
import SwiftUI

@Observable
class RepositoryViewModel {
    var repository: Repository

    init(repository: Repository) {
        self.repository = repository
    }
}

extension FocusedValues {
    @Entry
    var repositoryViewModel: RepositoryViewModel?
}

