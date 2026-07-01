import Foundation

struct SearchResult: Codable {
    let total: Int
    let totalPages: Int
    let results: [Photo]

    enum CodingKeys: String, CodingKey {
        case total, results
        case totalPages = "total_pages"
    }
}
