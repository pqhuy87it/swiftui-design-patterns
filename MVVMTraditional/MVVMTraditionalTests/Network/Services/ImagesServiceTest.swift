import XCTest
import UIKit
@testable import MVVMTraditional

@MainActor
final class ImagesServiceTest: XCTestCase {
    private let imageURL = URL(string: "https://images.unsplash.com/photo-1.jpg")!

    private func makeSUT() -> ImagesService {
        MockURLProtocol.reset()
        return ImagesService(session: .mocked())
    }

    func test_loadImage_success_returnsImage() async throws {
        let sut = makeSUT()
        let pngData = Self.makePNGData()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200), pngData)
        }

        let image = try await sut.loadImage(url: imageURL)

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
        XCTAssertEqual(MockURLProtocol.lastRequest?.url, imageURL)
    }

    func test_loadImage_httpError_throwsHTTPCode() async {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 404), Data())
        }

        await assertThrowsAPIError(.httpCode(404)) {
            _ = try await sut.loadImage(url: self.imageURL)
        }
    }

    func test_loadImage_invalidData_throwsImageDeserialization() async {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { request in
            (HTTPResponseFactory.make(url: request.url, statusCode: 200), Data("not an image".utf8))
        }

        await assertThrowsAPIError(.imageDeserialization) {
            _ = try await sut.loadImage(url: self.imageURL)
        }
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
