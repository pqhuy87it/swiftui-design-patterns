import ComposableArchitecture
import Foundation

@DependencyClient
struct PhotosClient {
    var fetchPhotos: (_ page: Int, _ perPage: Int) async throws -> [Photo]
}

extension PhotosClient: DependencyKey {
    static let liveValue: PhotosClient = {
        let photosRepository = PhotosRepository(session: .shared)

        return Self(
            fetchPhotos: { page, perPage in
                let dtos = try await photosRepository.fetchPhotos(page: page, perPage: perPage)
                return dtos.map { $0.toDomain() }
            }
        )
    }()
    
    static let previewValue = Self(
        fetchPhotos: { _, _ in [.mock] }
    )
}

extension DependencyValues {
    var photosClient: PhotosClient {
        get { self[PhotosClient.self] }
        set { self[PhotosClient.self] = newValue }
    }
}
