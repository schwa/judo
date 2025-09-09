import Observation
import JudoSupport

@Observable
class RepositoryViewModel {
    var repository: Repository

    init(repository: Repository) {
        self.repository = repository
    }
}

