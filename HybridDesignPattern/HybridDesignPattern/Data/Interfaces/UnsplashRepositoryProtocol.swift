import Foundation

protocol UnsplashRepositoryProtocol {
    func fetchPhotos(page: Int, perPage: Int) async throws -> [Photo]
    func fetchTopicPhotos(slug: String, page: Int, perPage: Int) async throws -> [Photo]
    func fetchTopics(page: Int, perPage: Int) async throws -> [Topic]
    func searchPhotos(query: String, page: Int, perPage: Int) async throws -> SearchResult
}
