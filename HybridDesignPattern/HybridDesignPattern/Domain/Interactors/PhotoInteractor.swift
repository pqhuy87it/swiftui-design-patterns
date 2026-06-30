import Foundation

struct PhotosInteractor: PhotosInteractorProtocol {
    let photosRepository: PhotosRepositoryProtocol
    let dbRepository: SearchDBRepositoryProtocol

    func fetchPhotos(page: Int = 1, perPage: Int = 10) async throws -> [Photo] {
        let dtos = try await photosRepository.fetchPhotos(page: page, perPage: perPage)
        return dtos.map { $0.toDomain() }
    }

    func searchPhotos(query: String, page: Int = 1, perPage: Int = 10) async throws -> SearchResult {
        let dto = try await photosRepository.searchPhotos(query: query, page: page, perPage: perPage)
        return dto.toDomain()
    }

    func getSearchHistory() async throws -> [String] {
        let history = try await dbRepository.fetchSearchHistory()
        return history.map { $0.keyword }
    }

    func saveSearchKeyword(_ keyword: String) async throws {
        try await dbRepository.saveSearchKeyword(keyword)
    }
}
