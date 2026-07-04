import XCTest
import UIKit
@testable import MVVMTraditional

@MainActor
final class ImageViewModelTest: XCTestCase {
    private let url = URL(string: "https://images.unsplash.com/photo-1.jpg")!

    func test_loadImage_success_setsImage() async {
        let service = MockImagesService()
        service.result = .success(Self.makeImage())
        let sut = ImageViewModel(imageURL: url, imagesService: service)

        await sut.loadImage()

        XCTAssertNotNil(sut.image)
        XCTAssertFalse(sut.hasError)
        XCTAssertEqual(service.lastURL, url)
    }

    func test_loadImage_failure_setsHasError() async {
        let service = MockImagesService()
        service.result = .failure(TestError())
        let sut = ImageViewModel(imageURL: url, imagesService: service)

        await sut.loadImage()

        XCTAssertNil(sut.image)
        XCTAssertTrue(sut.hasError)
    }

    func test_loadImage_whenAlreadyLoaded_doesNotReload() async {
        let service = MockImagesService()
        service.result = .success(Self.makeImage())
        let sut = ImageViewModel(imageURL: url, imagesService: service)

        await sut.loadImage()
        service.result = .failure(TestError()) // nếu gọi lại sẽ thành lỗi
        await sut.loadImage()

        XCTAssertNotNil(sut.image)
        XCTAssertFalse(sut.hasError)
    }

    private static func makeImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }
    }
}
