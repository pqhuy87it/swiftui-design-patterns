import XCTest
import ComposableArchitecture
@testable import TCA_The_Composable_Architecture_

@MainActor
final class PhotosFeatureTest: XCTestCase {

    // MARK: - onAppear

    func test_onAppear_success_loadsFirstPage() async {
        let photos = Photo.fixtures(count: 30)
        let store = TestStore(initialState: PhotosFeature.State()) {
            PhotosFeature()
        } withDependencies: {
            $0.photosClient.fetchPhotos = { @Sendable page, perPage in
                XCTAssertEqual(page, 1)
                XCTAssertEqual(perPage, 30)
                return photos
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.fetchPhotosResponse(.success(photos))) {
            $0.isLoading = false
            $0.photos = photos
            // Đủ 30 ảnh -> còn trang tiếp theo
            $0.canLoadMore = true
        }
    }

    func test_onAppear_lastPage_disablesLoadMore() async {
        let photos = Photo.fixtures(count: 10)
        let store = TestStore(initialState: PhotosFeature.State()) {
            PhotosFeature()
        } withDependencies: {
            $0.photosClient.fetchPhotos = { @Sendable _, _ in photos }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.fetchPhotosResponse(.success(photos))) {
            $0.isLoading = false
            $0.photos = photos
            $0.canLoadMore = false
        }
    }

    func test_onAppear_failure_setsErrorMessage() async {
        let store = TestStore(initialState: PhotosFeature.State()) {
            PhotosFeature()
        } withDependencies: {
            $0.photosClient.fetchPhotos = { @Sendable _, _ in throw AppError.network("Boom") }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.fetchPhotosResponse(.failure(.network("Boom")))) {
            $0.isLoading = false
            $0.errorMessage = "Boom"
        }
    }

    // MARK: - loadMorePhotos

    func test_loadMorePhotos_success_appendsAndAdvancesPage() async {
        let existing = Photo.fixtures(count: 30)
        let more = [Photo.fixture(id: "photo-more")]
        let store = TestStore(
            initialState: PhotosFeature.State(photos: existing, currentPage: 1)
        ) {
            PhotosFeature()
        } withDependencies: {
            $0.photosClient.fetchPhotos = { @Sendable page, _ in
                XCTAssertEqual(page, 2)
                return more
            }
        }

        await store.send(.loadMorePhotos) {
            $0.isLoadingMore = true
        }
        await store.receive(.loadMorePhotosResponse(.success(more))) {
            $0.isLoadingMore = false
            $0.photos = existing + more
            $0.currentPage = 2
            // Trang mới trả về < 30 ảnh -> hết trang
            $0.canLoadMore = false
        }
    }

    func test_loadMorePhotos_whenCannotLoadMore_doesNothing() async {
        let store = TestStore(
            initialState: PhotosFeature.State(canLoadMore: false)
        ) {
            PhotosFeature()
        }

        await store.send(.loadMorePhotos)
    }

    func test_loadMorePhotos_whileLoading_doesNothing() async {
        let store = TestStore(
            initialState: PhotosFeature.State(isLoadingMore: true)
        ) {
            PhotosFeature()
        }

        await store.send(.loadMorePhotos)
    }

    func test_loadMorePhotos_failure_setsErrorMessage() async {
        let store = TestStore(initialState: PhotosFeature.State()) {
            PhotosFeature()
        } withDependencies: {
            $0.photosClient.fetchPhotos = { @Sendable _, _ in throw AppError.network("Boom") }
        }

        await store.send(.loadMorePhotos) {
            $0.isLoadingMore = true
        }
        await store.receive(.loadMorePhotosResponse(.failure(.network("Boom")))) {
            $0.isLoadingMore = false
            $0.errorMessage = "Boom"
        }
    }

    // MARK: - photoTapped

    func test_photoTapped_setsSelectedPhoto() async {
        let photo = Photo.fixture(id: "p1")
        let store = TestStore(initialState: PhotosFeature.State()) {
            PhotosFeature()
        }

        await store.send(.photoTapped(photo)) {
            $0.selectedPhoto = photo
        }
    }
}
