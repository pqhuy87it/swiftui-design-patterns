import XCTest
import UIKit
@testable import TCA_The_Composable_Architecture_

final class ImageClientTest: XCTestCase {
    private let imageURL = URL(string: "https://images.unsplash.com/photo-client.jpg")!

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

    func test_liveValue_loadImage_returnsImage() async throws {
        let pngData = Self.makePNGData()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200), pngData)
        }

        let image = try await ImageClient.liveValue.loadImage(url: imageURL)

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func test_liveValue_loadImage_invalidData_throwsImageDeserialization() async {
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200), Data("not an image".utf8))
        }

        await assertThrowsAPIError(.imageDeserialization) {
            _ = try await ImageClient.liveValue.loadImage(url: self.imageURL)
        }
    }

    // MARK: - previewValue

    func test_previewValue_returnsPlaceholderImage() async throws {
        let image = try await ImageClient.previewValue.loadImage(url: imageURL)

        XCTAssertGreaterThan(image.size.width, 0)
    }

    // MARK: - Helpers

    private static func makePNGData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return image.pngData()!
    }
}
