import XCTest
import SwiftData
@testable import MVVMTraditional

@MainActor
final class SearchServiceTest: XCTestCase {

    private func makeSUT() -> SearchService {
        MockURLProtocol.reset()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: DBModel.SearchHistory.self, configurations: config)
        let dbRepository = MainDBRepository(modelContainer: container)
        return SearchService(session: .mocked(), dbRepository: dbRepository)
    }

    // MARK: - Network: searchPhotos

    func test_searchPhotos_success_decodesResult() async throws {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200),
             JSONFixtures.searchResult(total: 100, totalPages: 10, photoIDs: ["a", "b"]))
        }

        let result = try await sut.searchPhotos(query: "cat", page: 1, perPage: 30)

        XCTAssertEqual(result.total, 100)
        XCTAssertEqual(result.totalPages, 10)
        XCTAssertEqual(result.results.map { $0.id }, ["a", "b"])
    }

    func test_searchPhotos_encodesQueryAndPaging() async throws {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200),
             JSONFixtures.searchResult(total: 0, totalPages: 0, photoIDs: []))
        }

        _ = try await sut.searchPhotos(query: "spring flowers", page: 2, perPage: 20)

        let url = try XCTUnwrap(MockURLProtocol.lastRequest?.url)
        XCTAssertEqual(url.path, "/search/photos")
        let query = try XCTUnwrap(url.query)
        XCTAssertTrue(query.contains("query=spring%20flowers"))
        XCTAssertTrue(query.contains("page=2"))
        XCTAssertTrue(query.contains("per_page=20"))
    }

    func test_searchPhotos_httpError_throwsHTTPCode() async {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 403), Data("{}".utf8))
        }

        await assertThrowsAPIError(.httpCode(403)) {
            _ = try await sut.searchPhotos(query: "cat", page: 1, perPage: 30)
        }
    }

    // MARK: - Local DB: search history

    func test_saveSearchKeyword_thenFetch_returnsKeyword() async throws {
        let sut = makeSUT()

        try await sut.saveSearchKeyword("nature")
        let history = try await sut.fetchSearchHistory()

        XCTAssertEqual(history.map { $0.keyword }, ["nature"])
    }

    func test_saveSearchKeyword_duplicate_isNotDuplicated() async throws {
        let sut = makeSUT()

        try await sut.saveSearchKeyword("cat")
        try await sut.saveSearchKeyword("cat")
        let history = try await sut.fetchSearchHistory()

        XCTAssertEqual(history.count, 1)
    }

    func test_fetchSearchHistory_sortedByMostRecent() async throws {
        let sut = makeSUT()

        try await sut.saveSearchKeyword("first")
        try await sut.saveSearchKeyword("second")
        let history = try await sut.fetchSearchHistory()

        XCTAssertEqual(history.first?.keyword, "second")
        XCTAssertEqual(history.count, 2)
    }
}
