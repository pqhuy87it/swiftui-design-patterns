import Foundation

// Domain abstraction cho nguồn ảnh.
// - Do Domain sở hữu (Dependency Inversion).
// - Trả về domain entity (Photo/Topic/SearchResult), KHÔNG lộ ApiModel hay transport.
// - KHÔNG kế thừa APIRepositoryProtocol; implementation ở tầng Data mới gắn với HTTP.
protocol PhotosRepositoryProtocol {
    func fetchLatestPhotos(page: Int, perPage: Int) async throws -> [Photo]
    func searchPhotos(query: String, page: Int, perPage: Int) async throws -> SearchResult
    func fetchTopics(page: Int, perPage: Int) async throws -> [Topic]
    func fetchTopicPhotos(slug: String, page: Int, perPage: Int) async throws -> [Photo]
}
