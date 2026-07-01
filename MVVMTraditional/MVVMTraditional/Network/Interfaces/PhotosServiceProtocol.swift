import Foundation

protocol PhotosServiceProtocol {
    func fetchPhotos(page: Int, perPage: Int) async throws -> [Photo]
}
