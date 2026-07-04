import XCTest
@testable import MVVMTraditional

@MainActor
final class TopicsServiceTest: XCTestCase {

    private func makeSUT() -> TopicsService {
        MockURLProtocol.reset()
        return TopicsService(session: .mocked())
    }

    // MARK: - fetchTopics

    func test_fetchTopics_success_decodesEntities() async throws {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200),
             JSONFixtures.topicsArray([("t1", "nature"), ("t2", "wallpapers")]))
        }

        let topics = try await sut.fetchTopics(page: 1, perPage: 10)

        XCTAssertEqual(topics.map { $0.id }, ["t1", "t2"])
        XCTAssertEqual(topics.first?.slug, "nature")
        XCTAssertEqual(topics.first?.coverPhoto?.id, "cover-t1")
    }

    func test_fetchTopics_buildsCorrectRequest() async throws {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200),
             JSONFixtures.topicsArray([("t1", "nature")]))
        }

        _ = try await sut.fetchTopics(page: 3, perPage: 5)

        let url = try XCTUnwrap(MockURLProtocol.lastRequest?.url)
        XCTAssertEqual(url.path, "/topics")
        let query = try XCTUnwrap(url.query)
        XCTAssertTrue(query.contains("page=3"))
        XCTAssertTrue(query.contains("per_page=5"))
    }

    func test_fetchTopics_httpError_throwsHTTPCode() async {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 500), Data("{}".utf8))
        }

        await assertThrowsAPIError(.httpCode(500)) {
            _ = try await sut.fetchTopics(page: 1, perPage: 10)
        }
    }

    // MARK: - fetchTopicPhotos

    func test_fetchTopicPhotos_success_decodesEntities() async throws {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200),
             JSONFixtures.photosArray(ids: ["p1", "p2"]))
        }

        let photos = try await sut.fetchTopicPhotos(slug: "nature", page: 1, perPage: 10)

        XCTAssertEqual(photos.map { $0.id }, ["p1", "p2"])
    }

    func test_fetchTopicPhotos_buildsSlugPath() async throws {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200),
             JSONFixtures.photosArray(ids: ["p1"]))
        }

        _ = try await sut.fetchTopicPhotos(slug: "nature", page: 1, perPage: 10)

        let url = try XCTUnwrap(MockURLProtocol.lastRequest?.url)
        XCTAssertEqual(url.path, "/topics/nature/photos")
    }

    func test_fetchTopicPhotos_invalidJSON_throwsUnexpectedResponse() async {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200), Data("<html/>".utf8))
        }

        await assertThrowsAPIError(.unexpectedResponse) {
            _ = try await sut.fetchTopicPhotos(slug: "nature", page: 1, perPage: 10)
        }
    }
}
