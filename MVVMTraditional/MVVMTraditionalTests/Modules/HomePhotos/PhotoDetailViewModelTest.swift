import XCTest
@testable import MVVMTraditional

@MainActor
final class PhotoDetailViewModelTest: XCTestCase {

    func test_derivedDisplayData() {
        let photo = EntityFixtures.photo(id: "x")
        let sut = PhotoDetailViewModel(photo: photo)

        XCTAssertEqual(sut.imageURL, photo.urls.regular)
        XCTAssertEqual(sut.authorName, "John Doe")           // user.name
        XCTAssertEqual(sut.description, "A description")     // photo.description
        XCTAssertEqual(sut.sizeText, "Original size: 4000 x 3000")
    }
}
