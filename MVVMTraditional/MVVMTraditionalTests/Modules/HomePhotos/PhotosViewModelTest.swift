import XCTest
@testable import MVVMTraditional

@MainActor
final class PhotosViewModelTest: XCTestCase {

    func test_loadPhotos_success_setsPhotosAndCanLoadMore() async {
        let service = MockPhotosService()
        service.handler = { _, _ in EntityFixtures.photos(ids: (1...30).map { "p\($0)" }) }
        let sut = PhotosViewModel(photosService: service)

        await sut.loadPhotos()

        XCTAssertEqual(sut.photos.count, 30)
        XCTAssertNil(sut.errorMessage)
    }

    func test_loadPhotos_partialPage_stillLoads() async {
        let service = MockPhotosService()
        service.handler = { _, _ in EntityFixtures.photos(ids: ["a", "b"]) }
        let sut = PhotosViewModel(photosService: service)

        await sut.loadPhotos()

        XCTAssertEqual(sut.photos.map { $0.id }, ["a", "b"])
    }

    func test_loadPhotos_whenAlreadyLoaded_doesNotReload() async {
        let service = MockPhotosService()
        service.handler = { _, _ in EntityFixtures.photos(ids: ["a"]) }
        let sut = PhotosViewModel(photosService: service)

        await sut.loadPhotos()
        await sut.loadPhotos() // lần 2 bị guard chặn

        XCTAssertEqual(service.callCount, 1)
    }

    func test_loadPhotos_failure_setsErrorMessage() async {
        let service = MockPhotosService()
        service.handler = { _, _ in throw TestError() }
        let sut = PhotosViewModel(photosService: service)

        await sut.loadPhotos()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.photos.isEmpty)
    }

    func test_refresh_reloadsEvenWhenLoaded() async {
        let service = MockPhotosService()
        service.handler = { _, _ in EntityFixtures.photos(ids: ["a"]) }
        let sut = PhotosViewModel(photosService: service)

        await sut.loadPhotos()
        await sut.refresh()

        XCTAssertEqual(service.callCount, 2)
    }

    func test_loadMore_appendsNextPage() async {
        let service = MockPhotosService()
        service.handler = { page, _ in
            page == 1
                ? EntityFixtures.photos(ids: (1...30).map { "p\($0)" })
                : EntityFixtures.photos(ids: ["n1", "n2"])
        }
        let sut = PhotosViewModel(photosService: service)

        await sut.loadPhotos()   // page 1 (30 -> canLoadMore true)
        await sut.loadMore()     // page 2

        XCTAssertEqual(sut.photos.count, 32)
        XCTAssertEqual(service.requestedPages, [1, 2])
    }

    func test_loadMore_whenCannotLoadMore_isNoOp() async {
        let service = MockPhotosService()
        service.handler = { _, _ in EntityFixtures.photos(ids: ["a"]) } // partial -> canLoadMore false
        let sut = PhotosViewModel(photosService: service)

        await sut.loadPhotos()
        await sut.loadMore()

        XCTAssertEqual(service.callCount, 1)
    }
}
