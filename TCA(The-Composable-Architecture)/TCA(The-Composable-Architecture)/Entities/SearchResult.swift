import Foundation

nonisolated struct SearchResult: Codable, Equatable, Sendable {
    let total: Int
    let totalPages: Int
    let results: [Photo]
}
