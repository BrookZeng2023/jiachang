import Foundation
import Observation

@Observable
final class SessionController {
    enum Status: Equatable {
        case idle
        case connecting
        case ready
        case offline(String)
    }

    var credentials: Credentials {
        didSet { credentialsStore.save(credentials) }
    }
    private(set) var status: Status = .idle
    private(set) var repository: (any RecipeRepository)?

    private let credentialsStore: any CredentialsStore
    private let gateway: any SessionGateway

    init(credentialsStore: any CredentialsStore, gateway: any SessionGateway) {
        self.credentialsStore = credentialsStore
        self.gateway = gateway
        credentials = credentialsStore.load()
    }

    func connect() async {
        guard credentials.isComplete else {
            status = .idle
            return
        }
        status = .connecting
        do {
            repository = try await gateway.connect(using: credentials)
            status = .ready
        } catch {
            repository = nil
            status = .offline(error.localizedDescription)
        }
    }
}
