import Foundation

protocol PhotosRepositoryProtocol {
    func fetchPhotos(page: Int, perPage: Int) async throws -> [PhotoDTO]
    func searchPhotos(query: String, page: Int, perPage: Int) async throws -> SearchResultDTO
}
