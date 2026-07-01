import UIKit

struct ImagesService: APIRepositoryProtocol, ImagesServiceProtocol {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func loadImage(url: URL) async throws -> UIImage {
        let (data, response) = try await session.data(from: url)

        guard let code = (response as? HTTPURLResponse)?.statusCode else {
            throw APIError.unexpectedResponse
        }
        guard HTTPCodes.success.contains(code) else {
            throw APIError.httpCode(code)
        }
        guard let image = UIImage(data: data) else {
            throw APIError.imageDeserialization
        }

        return image
    }
}
