import Foundation

struct SearchService: APIRepositoryProtocol, SearchServiceProtocol {
    let session: URLSession
    private let dbRepository: MainDBRepository

    init(session: URLSession = .shared, dbRepository: MainDBRepository) {
        self.session = session
        self.dbRepository = dbRepository
    }

    // MARK: - Network

    func searchPhotos(query: String, page: Int, perPage: Int) async throws -> SearchResult {
        try await call(
            endpoint: API.searchPhotos(query: query, page: page, perPage: perPage, clientId: clientId)
        )
    }

    // MARK: - Local DB (MainDBRepository)

    @MainActor func fetchSearchHistory() async throws -> [DBModel.SearchHistory] {
        try await dbRepository.fetchSearchHistory()
    }

    func saveSearchKeyword(_ keyword: String) async throws {
        try await dbRepository.saveSearchKeyword(keyword)
    }
}

// MARK: - Configure Endpoints for Unsplash

extension SearchService {
    enum API {
        case searchPhotos(query: String, page: Int, perPage: Int, clientId: String)
    }
}

extension SearchService.API: APICall {
    var path: String {
        switch self {
        case let .searchPhotos(query, page, perPage, _):
            // Encode the keyword so spaces / diacritics are URL-safe
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "/search/photos?query=\(encodedQuery)&page=\(page)&per_page=\(perPage)"
        }
    }

    var method: String {
        return "GET"
    }

    var headers: [String: String]? {
        let clientId: String
        switch self {
        case let .searchPhotos(_, _, _, key):
            clientId = key
        }

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
