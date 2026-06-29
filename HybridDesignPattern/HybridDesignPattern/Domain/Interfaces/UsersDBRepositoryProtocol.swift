import SwiftData
import Foundation

// Đặt cùng tầng Domain như SearchDBRepositoryProtocol. Nhận/đọc theo domain User,
// không nhận ApiModel để Domain không phụ thuộc tầng Network.
protocol UsersDBRepositoryProtocol {
    @MainActor func fetchLocalUsers() async throws -> [DBModel.User]
    func store(users: [User]) async throws
}
