import XCTest
@testable import TCA_The_Composable_Architecture_

/// `liveValue` dùng `URLSession.shared` nên phải đăng ký `MockURLProtocol`
/// toàn cục qua `URLProtocol.registerClass` thay vì inject session như repository test.
final class PhotosClientTest: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - liveValue

    func test_liveValue_fetchPhotos_mapsDTOsToDomain() async throws {
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200),
             JSONFixtures.photosArray(ids: ["a", "b"]))
        }

        let photos = try await PhotosClient.liveValue.fetchPhotos(1, 30)

        XCTAssertEqual(photos.map(\.id), ["a", "b"])
        // Kiểm tra mapping DTO -> domain giữ nguyên dữ liệu lồng nhau
        XCTAssertEqual(photos.first?.urls.thumb.absoluteString, "https://example.com/a/thumb.jpg")
        XCTAssertEqual(photos.first?.user.username, "johndoe")
    }

    func test_liveValue_fetchPhotos_httpError_propagates() async {
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 404), Data("{}".utf8))
        }

        await assertThrowsAPIError(.httpCode(404)) {
            _ = try await PhotosClient.liveValue.fetchPhotos(1, 30)
        }
    }

    // MARK: - previewValue

    func test_previewValue_returnsMockPhoto() async throws {
        let photos = try await PhotosClient.previewValue.fetchPhotos(1, 30)

        XCTAssertEqual(photos, [.mock])
    }
}
