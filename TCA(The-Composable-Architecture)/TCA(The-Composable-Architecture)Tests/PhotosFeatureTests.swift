import ComposableArchitecture
import XCTest
@testable import TCA_The_Composable_Architecture_

@MainActor
final class PhotosFeatureTests: XCTestCase {

    func testFetchPhotosSuccess() async {
        let store = TestStore(initialState: PhotosFeature.State()) {
            PhotosFeature()
        } withDependencies: {
            $0.photosClient.fetchPhotos = { _, _ in [.mock] }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.fetchPhotosResponse.success) {
            $0.isLoading = false
            $0.photos = [.mock]
            $0.canLoadMore = false
        }
    }

    func testFetchPhotosFailure() async {
        let store = TestStore(initialState: PhotosFeature.State()) {
            PhotosFeature()
        } withDependencies: {
            $0.photosClient.fetchPhotos = { _, _ in throw APIError.unexpectedResponse }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.fetchPhotosResponse.failure) {
            $0.isLoading = false
            $0.errorMessage = "Unexpected response from the server"
        }
    }
}
