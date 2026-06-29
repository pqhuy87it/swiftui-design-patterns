import Foundation
import UIKit

struct ImagesRepository: ImagesRepositoryProtocol {

    // Chỉ cần session để tải dữ liệu ảnh; không có baseURL vì tải trực tiếp từ URL tuyệt đối.
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func loadImage(url: URL) async throws -> UIImage {
        let (localURL, _) = try await session.download(from: url)
        let data = try Data(contentsOf: localURL)
        guard let image = UIImage(data: data) else {
            throw APIError.imageDeserialization
        }
        return image
    }
}

struct StubImagesInteractor: ImagesInteractorProtocol {
    let shouldFail: Bool
    
    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }
    
    func loadImage(url: URL) async throws -> UIImage {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        if shouldFail {
            throw NSError(domain: "StubError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load mock image"])
        }
        
        let placeholderImage = UIImage(systemName: "photo.artframe") ?? UIImage()
        
        return placeholderImage
    }
}
