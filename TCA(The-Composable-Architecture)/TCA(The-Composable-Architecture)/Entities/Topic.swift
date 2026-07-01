import Foundation

nonisolated struct Topic: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let slug: String
    let title: String
    let description: String?
    let coverPhoto: Photo?
}
