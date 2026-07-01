import ComposableArchitecture
import UIKit

@DependencyClient
struct ImageClient {
    var loadImage: (_ url: URL) async throws -> UIImage
}

extension ImageClient: DependencyKey {
    static let liveValue: ImageClient = {
        let imagesRepository = ImagesRepository(session: .shared)

        return Self(
            loadImage: { url in
                try await imagesRepository.loadImage(url: url)
            }
        )
    }()

    static let previewValue = Self(
        loadImage: { _ in UIImage(systemName: "photo") ?? UIImage() }
    )
}

extension DependencyValues {
    var imageClient: ImageClient {
        get { self[ImageClient.self] }
        set { self[ImageClient.self] = newValue }
    }
}
