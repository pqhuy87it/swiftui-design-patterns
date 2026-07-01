import Foundation

struct User: Codable, Identifiable, Hashable {
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

    enum CodingKeys: String, CodingKey {
        case id, username, name
        case firstName = "first_name"
        case lastName = "last_name"
        case instagramUsername = "instagram_username"
        case twitterUsername = "twitter_username"
        case portfolioUrl = "portfolio_url"
        case totalCollections = "total_collections"
        case profileImage = "profile_image"
    }

    struct ProfileImage: Codable, Hashable {
        let small: URL
        let medium: URL
        let large: URL
    }
}
