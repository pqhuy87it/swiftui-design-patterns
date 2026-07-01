import Foundation

struct PhotosService: APIRepositoryProtocol, PhotosServiceProtocol {
    func fetchPhotos(page: Int, perPage: Int) async throws -> [Photo] {
        try await call(
            endpoint: API.latestPhotos(page: page, perPage: perPage, clientId: clientId)
        )
    }
    
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
}

// MARK: - Configure Endpoints for Unsplash

extension PhotosService {
    enum API {
        case latestPhotos(page: Int, perPage: Int, clientId: String)
    }
}

extension PhotosService.API: APICall {
    var path: String {
        switch self {
        case let .latestPhotos(page, perPage, _):
            // Attach query parameters directly to the path
            return "/photos?page=\(page)&per_page=\(perPage)"
        }
    }

    var method: String {
        return "GET"
    }

    var headers: [String: String]? {
        // Extract API key to inject into header
        let clientId: String
        switch self {
        case let .latestPhotos(_, _, key):
            clientId = key
        }

        // Unsplash requires Accept-Version and Authorization headers
        return [
            "Accept-Version": "v1",
            "Authorization": "Client-ID \(clientId)",
            "Accept": "application/json"
        ]
    }

    func body() throws -> Data? {
        return nil // GET method does not have a body
    }
}
