import Foundation

struct PhotoInteractor: PhotoInteractorProtocol {
    let photosRepository: PhotosRepositoryProtocol
    let dbRepository: SearchDBRepositoryProtocol

    func fetchPhotos(page: Int = 1, perPage: Int = 10) async throws -> [Photo] {
        try await photosRepository.fetchLatestPhotos(page: page, perPage: perPage)
    }

    func searchPhotos(query: String, page: Int = 1, perPage: Int = 10) async throws -> SearchResult {
        try await photosRepository.searchPhotos(query: query, page: page, perPage: perPage)
    }

    func fetchTopics(page: Int = 1, perPage: Int = 10) async throws -> [Topic] {
        try await photosRepository.fetchTopics(page: page, perPage: perPage)
    }

    func fetchTopicPhotos(slug: String, page: Int = 1, perPage: Int = 30) async throws -> [Photo] {
        try await photosRepository.fetchTopicPhotos(slug: slug, page: page, perPage: perPage)
    }

    func getSearchHistory() async throws -> [String] {
        let history = try await dbRepository.fetchSearchHistory()
        return history.map { $0.keyword }
    }

    func saveSearchKeyword(_ keyword: String) async throws {
        try await dbRepository.saveSearchKeyword(keyword)
    }
}
