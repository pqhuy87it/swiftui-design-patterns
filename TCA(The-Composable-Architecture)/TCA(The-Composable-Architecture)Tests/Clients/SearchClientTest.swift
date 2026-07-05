import XCTest
@testable import TCA_The_Composable_Architecture_

final class SearchClientTest: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - liveValue: searchPhotos

    func test_liveValue_searchPhotos_mapsDTOToDomain() async throws {
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200),
             JSONFixtures.searchResult(total: 42, totalPages: 2, photoIDs: ["a", "b"]))
        }

        let result = try await SearchClient.liveValue.searchPhotos("cat", 1, 30)

        XCTAssertEqual(result.total, 42)
        XCTAssertEqual(result.totalPages, 2)
        XCTAssertEqual(result.results.map(\.id), ["a", "b"])
    }

    func test_liveValue_searchPhotos_httpError_propagates() async {
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 403), Data("{}".utf8))
        }

        await assertThrowsAPIError(.httpCode(403)) {
            _ = try await SearchClient.liveValue.searchPhotos("cat", 1, 30)
        }
    }

    // MARK: - liveValue: search history
    // liveValue dùng ModelContainer thật (on-disk) của test host nên dữ liệu
    // tồn tại giữa các lần chạy — dùng keyword duy nhất để test ổn định.

    func test_liveValue_saveKeyword_thenGetHistory_returnsKeywordFirst() async throws {
        let keyword = "test-\(UUID().uuidString)"

        try await SearchClient.liveValue.saveKeyword(keyword)
        let history = try await SearchClient.liveValue.getHistory()

        XCTAssertEqual(history.first, keyword)
    }

    // MARK: - previewValue

    func test_previewValue_returnsMocks() async throws {
        let result = try await SearchClient.previewValue.searchPhotos("cat", 1, 30)
        let history = try await SearchClient.previewValue.getHistory()

        XCTAssertEqual(result.total, 100)
        XCTAssertEqual(result.totalPages, 10)
        XCTAssertEqual(result.results, [.mock])
        XCTAssertEqual(history, ["Cat", "Nature", "Space"])
    }
}
