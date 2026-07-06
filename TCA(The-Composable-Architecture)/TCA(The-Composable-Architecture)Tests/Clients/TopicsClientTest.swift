import XCTest
@testable import TCA_The_Composable_Architecture_

final class TopicsClientTest: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - liveValue: fetchTopics

    func test_liveValue_fetchTopics_mapsDTOsToDomain() async throws {
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200),
             JSONFixtures.topicsArray([("t1", "nature"), ("t2", "wallpapers")]))
        }

        let topics = try await TopicsClient.liveValue.fetchTopics(1, 10)

        XCTAssertEqual(topics.map(\.id), ["t1", "t2"])
        XCTAssertEqual(topics.first?.slug, "nature")
        XCTAssertEqual(topics.first?.coverPhoto?.id, "cover-t1")
    }

    func test_liveValue_fetchTopics_httpError_propagates() async {
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 500), Data("{}".utf8))
        }

        await assertThrowsAPIError(.httpCode(500)) {
            _ = try await TopicsClient.liveValue.fetchTopics(1, 10)
        }
    }

    // MARK: - liveValue: fetchTopicPhotos

    func test_liveValue_fetchTopicPhotos_mapsDTOsToDomain() async throws {
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200),
             JSONFixtures.photosArray(ids: ["p1", "p2"]))
        }

        let photos = try await TopicsClient.liveValue.fetchTopicPhotos("nature", 1, 10)

        XCTAssertEqual(photos.map(\.id), ["p1", "p2"])
    }

    func test_liveValue_fetchTopicPhotos_invalidJSON_throwsUnexpectedResponse() async {
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200), Data("<html/>".utf8))
        }

        await assertThrowsAPIError(.unexpectedResponse) {
            _ = try await TopicsClient.liveValue.fetchTopicPhotos("nature", 1, 10)
        }
    }

    // MARK: - previewValue

    func test_previewValue_returnsMocks() async throws {
        let topics = try await TopicsClient.previewValue.fetchTopics(1, 10)
        let photos = try await TopicsClient.previewValue.fetchTopicPhotos("spring", 1, 10)

        XCTAssertEqual(topics, [.mock])
        XCTAssertEqual(photos, [.mock])
    }
}
