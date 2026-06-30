import Foundation

protocol PhotosInteractorProtocol {
    func fetchPhotos(page: Int, perPage: Int) async throws -> [Photo]
    func searchPhotos(query: String, page: Int, perPage: Int) async throws -> SearchResult
    func fetchTopics(page: Int, perPage: Int) async throws -> [Topic]
    func fetchTopicPhotos(slug: String, page: Int, perPage: Int) async throws -> [Photo]
    func getSearchHistory() async throws -> [String]
    func saveSearchKeyword(_ keyword: String) async throws
}
