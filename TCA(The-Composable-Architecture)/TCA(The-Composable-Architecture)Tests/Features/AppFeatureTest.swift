import XCTest
import ComposableArchitecture
@testable import TCA_The_Composable_Architecture_

/// AppFeature chỉ compose 3 feature con qua Scope,
/// nên test tập trung xác nhận action được định tuyến đúng vào từng child.
@MainActor
final class AppFeatureTest: XCTestCase {

    func test_photosAction_isRoutedToPhotosFeature() async {
        let photo = Photo.fixture(id: "p1")
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.photos(.photoTapped(photo))) {
            $0.photos.selectedPhoto = photo
        }
    }

    func test_topicsAction_isRoutedToTopicsFeature() async {
        let topic = Topic.fixture(id: "t1", slug: "nature")
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.topics(.fetchTopicsResponse(.success([topic])))) {
            $0.topics.heroTopic = topic
        }
    }

    func test_searchAction_isRoutedToSearchFeature() async {
        let photo = Photo.fixture(id: "p1")
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.search(.photoTapped(photo))) {
            $0.search.selectedPhoto = photo
        }
    }
}
