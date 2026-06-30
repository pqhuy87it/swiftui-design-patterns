import Foundation

protocol UsersRepositoryProtocol {
    func fetchUsers() async throws -> [User]
}
