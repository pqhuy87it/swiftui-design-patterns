import Foundation

nonisolated struct Photo: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let width: Int
    let height: Int
    let color: String?
    let description: String?
    let altDescription: String?
    let urls: Urls
    let user: User
    
    nonisolated struct Urls: Codable, Hashable, Sendable {
        let raw: URL
        let full: URL
        let regular: URL
        let small: URL
        let thumb: URL
    }
}
