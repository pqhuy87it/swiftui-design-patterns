import XCTest
@testable import MVVMTraditional

@MainActor
final class PhotosServiceTest: XCTestCase {

    private func makeSUT() -> PhotosService {
        MockURLProtocol.reset()
        return PhotosService(session: .mocked())
    }

    func test_fetchPhotos_success_decodesEntities() async throws {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200),
             JSONFixtures.photosArray(ids: ["a", "b", "c"]))
        }

        let photos = try await sut.fetchPhotos(page: 1, perPage: 30)

        XCTAssertEqual(photos.map { $0.id }, ["a", "b", "c"])
        XCTAssertEqual(photos.first?.urls.small.absoluteString, "https://example.com/a/small.jpg")
        XCTAssertEqual(photos.first?.user.username, "johndoe")
    }

    func test_fetchPhotos_buildsCorrectRequest() async throws {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200),
             JSONFixtures.photosArray(ids: ["a"]))
        }

        _ = try await sut.fetchPhotos(page: 2, perPage: 15)

        let url = try XCTUnwrap(MockURLProtocol.lastRequest?.url)
        XCTAssertEqual(url.host, "api.unsplash.com")
        XCTAssertEqual(url.path, "/photos")
        let query = try XCTUnwrap(url.query)
        XCTAssertTrue(query.contains("page=2"))
        XCTAssertTrue(query.contains("per_page=15"))
    }

    func test_fetchPhotos_httpError_throwsHTTPCode() async {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 404), Data("{}".utf8))
        }

        await assertThrowsAPIError(.httpCode(404)) {
            _ = try await sut.fetchPhotos(page: 1, perPage: 30)
        }
    }

    func test_fetchPhotos_invalidJSON_throwsUnexpectedResponse() async {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200), Data("not json".utf8))
        }

        await assertThrowsAPIError(.unexpectedResponse) {
            _ = try await sut.fetchPhotos(page: 1, perPage: 30)
        }
    }
}
