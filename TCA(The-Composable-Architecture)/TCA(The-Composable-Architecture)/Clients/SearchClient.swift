import Foundation
import SwiftData
import ComposableArchitecture

@DependencyClient
struct SearchClient {
    var searchPhotos: (_ query: String, _ page: Int, _ perPage: Int) async throws -> SearchResult
    var getHistory: () async throws -> [String]
    var saveKeyword: (_ keyword: String) async throws -> Void
}

extension SearchClient: DependencyKey {
    static let liveValue: SearchClient = {
        let container = try! ModelContainer.appModelContainer()
        let dbRepository = MainDBRepository(modelContainer: container)
        let searchRepository = SearchRepository(session: .shared, dbRepository: dbRepository)

        return Self(
            searchPhotos: { query, page, perPage in
                let dto = try await searchRepository.searchPhotos(query: query, page: page, perPage: perPage)
                return dto.toDomain()
            },
            getHistory: {
                let dbHistory = try await searchRepository.fetchSearchHistory()
                
                return dbHistory.map { $0.keyword }
            },
            saveKeyword: { keyword in
                try await searchRepository.saveSearchKeyword(keyword)
            }
        )
    }()
    
    static let previewValue = Self(
        searchPhotos: { _, _, _ in SearchResult(total: 100, totalPages: 10, results: [.mock]) },
        getHistory: { ["Cat", "Nature", "Space"] },
        saveKeyword: { _ in }
    )
}

extension DependencyValues {
    var searchClient: SearchClient {
        get { self[SearchClient.self] }
        set { self[SearchClient.self] = newValue }
    }
}
