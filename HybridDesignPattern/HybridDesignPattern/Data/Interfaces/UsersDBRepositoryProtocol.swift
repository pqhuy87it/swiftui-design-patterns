import SwiftData
import Foundation

protocol UsersDBRepositoryProtocol {
    @MainActor func fetchLocalUsers() async throws -> [DBModel.User]
    func store(users: [User]) async throws
}
