import Foundation

struct TopicsService: APIRepositoryProtocol, TopicsServiceProtocol {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchTopics(page: Int, perPage: Int) async throws -> [Topic] {
        try await call(
            endpoint: API.topics(page: page, perPage: perPage, clientId: clientId)
        )
    }

    func fetchTopicPhotos(slug: String, page: Int, perPage: Int) async throws -> [Photo] {
        try await call(
            endpoint: API.topicPhotos(slug: slug, page: page, perPage: perPage, clientId: clientId)
        )
    }
}

// MARK: - Configure Endpoints for Unsplash

extension TopicsService {
    enum API {
        case topics(page: Int, perPage: Int, clientId: String)
        case topicPhotos(slug: String, page: Int, perPage: Int, clientId: String)
    }
}

extension TopicsService.API: APICall {
    var path: String {
        switch self {
        case let .topics(page, perPage, _):
            return "/topics?page=\(page)&per_page=\(perPage)"
        case let .topicPhotos(slug, page, perPage, _):
            // Photos belonging to a specific topic
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
        case let .topics(_, _, key),
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
