import Foundation

nonisolated struct User: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let username: String
    let name: String?
    let firstName: String?
    let lastName: String?
    let instagramUsername: String?
    let twitterUsername: String?
    let portfolioUrl: URL?
    let totalCollections: Int
    let profileImage: ProfileImage

    nonisolated struct ProfileImage: Codable, Hashable, Sendable {
        let small: URL
        let medium: URL
        let large: URL
    }
}
