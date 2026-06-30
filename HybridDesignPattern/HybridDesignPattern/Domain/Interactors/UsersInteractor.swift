import Foundation

protocol UsersInteractor {
    func refreshUsers() async throws
}

struct RealUsersInteractor: UsersInteractor {
    let repository: UsersRepositoryProtocol
    let dbRepository: UsersDBRepositoryProtocol

    func refreshUsers() async throws {
        // 1. Fetch new data from Server (DTO) rồi map sang domain entity tại Interactor
        let users = try await repository.fetchUsers().map { $0.toDomain() }
        // 2. Overwrite to local Database
        try await dbRepository.store(users: users)
    }
}
