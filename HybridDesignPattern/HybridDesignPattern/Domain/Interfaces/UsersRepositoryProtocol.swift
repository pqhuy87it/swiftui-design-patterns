import Foundation

// Domain abstraction cho nguồn user — trả về domain entity, không lộ ApiModel/transport.
protocol UsersRepositoryProtocol {
    func fetchUsers() async throws -> [User]
}
