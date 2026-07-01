import Foundation

struct Topic: Codable, Identifiable, Hashable {
    let id: String
    let slug: String
    let title: String
    let description: String?
    let coverPhoto: Photo?

    enum CodingKeys: String, CodingKey {
        case id, slug, title, description
        case coverPhoto = "cover_photo"
    }
}
