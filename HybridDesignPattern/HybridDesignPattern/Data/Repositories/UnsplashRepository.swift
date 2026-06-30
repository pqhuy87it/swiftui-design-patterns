import Foundation

// MARK: - Data implementation

struct UnsplashRepository: UnsplashRepositoryProtocol, APIRepositoryProtocol {
    let session: URLSession
    let baseURL: String = "https://api.unsplash.com"

    // API key from Secrets.plist
    let clientId: String = AppConfig.unsplashClientID

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchPhotos(page: Int, perPage: Int) async throws -> [Photo] {
        let dtos: [PhotoDTO] = try await call(
            endpoint: API.latestPhotos(page: page, perPage: perPage, clientId: clientId)
        )
        return dtos.map { $0.toDomain() }
    }

    func searchPhotos(query: String, page: Int, perPage: Int) async throws -> SearchResult {
        let dto: SearchResultDTO = try await call(
            endpoint: API.searchPhotos(query: query, page: page, perPage: perPage, clientId: clientId)
        )
        return dto.toDomain()
    }

    func fetchTopics(page: Int, perPage: Int) async throws -> [Topic] {
        let dtos: [TopicDTO] = try await call(
            endpoint: API.topics(page: page, perPage: perPage, clientId: clientId)
        )
        return dtos.map { $0.toDomain() }
    }

    func fetchTopicPhotos(slug: String, page: Int, perPage: Int) async throws -> [Photo] {
        let dtos: [PhotoDTO] = try await call(
            endpoint: API.topicPhotos(slug: slug, page: page, perPage: perPage, clientId: clientId)
        )
        return dtos.map { $0.toDomain() }
    }
}

// MARK: - Configure Endpoints for Unsplash
extension UnsplashRepository {
    enum API {
        case latestPhotos(page: Int, perPage: Int, clientId: String)
        case searchPhotos(query: String, page: Int, perPage: Int, clientId: String)
        case topics(page: Int, perPage: Int, clientId: String)
        case topicPhotos(slug: String, page: Int, perPage: Int, clientId: String)
    }
}

extension UnsplashRepository.API: APICall {
    var path: String {
        switch self {
        case let .latestPhotos(page, perPage, _):
            // Attach query parameters directly to the path
            return "/photos?page=\(page)&per_page=\(perPage)"
        case let .searchPhotos(query, page, perPage, _):
            // Must encode characters with diacritics/spaces if the user searches for complex keywords
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "/search/photos?query=\(encodedQuery)&page=\(page)&per_page=\(perPage)"
        case let .topics(page, perPage, _):
            // Add path for topics
            return "/topics?page=\(page)&per_page=\(perPage)"
        case let .topicPhotos(slug, page, perPage, _):
            // Append slug to the path exactly like the structure you just saw
            return "/topics/\(slug)/photos?page=\(page)&per_page=\(perPage)"
        }
    }

    var method: String {
        return "GET"
    }

    var headers: [String: String]? {
        // Extract API key to inject into header
        let clientId: String
        switch self {
        case let .latestPhotos(_, _, key),
            let .searchPhotos(_, _, _, key),
            let .topics(_, _, key),
            let .topicPhotos(_, _, _, key):
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

// MARK: - Stub (For Xcode Previews & Unit Tests)
struct StubPhotosInteractor: PhotosInteractorProtocol {
    func fetchPhotos(page: Int, perPage: Int) async throws -> [Photo] {
        // Return an empty array or Mock data for Preview to display immediately
        return []
    }

    func searchPhotos(query: String, page: Int, perPage: Int) async throws -> SearchResult {
        return SearchResult(total: 0, totalPages: 0, results: [])
    }

    func fetchTopics(page: Int, perPage: Int) async throws -> [Topic] {
        return []
    }

    func fetchTopicPhotos(slug: String, page: Int, perPage: Int) async throws -> [Photo] {
        return []
    }

    func getSearchHistory() async throws -> [String] { return ["Cat", "Nature"] }
    func saveSearchKeyword(_ keyword: String) async throws {}
}
