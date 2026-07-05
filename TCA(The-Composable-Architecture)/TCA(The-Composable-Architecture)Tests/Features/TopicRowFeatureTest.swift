import XCTest
import ComposableArchitecture
@testable import TCA_The_Composable_Architecture_

@MainActor
final class TopicRowFeatureTest: XCTestCase {
    private let topic = Topic.fixture(id: "t1", slug: "nature")

    // MARK: - onAppear

    func test_onAppear_success_loadsPhotos() async {
        let photos = Photo.fixtures(count: 3)
        let store = TestStore(initialState: TopicRowFeature.State(topic: topic)) {
            TopicRowFeature()
        } withDependencies: {
            $0.topicsClient.fetchTopicPhotos = { @Sendable slug, page, perPage in
                XCTAssertEqual(slug, "nature")
                XCTAssertEqual(page, 1)
                XCTAssertEqual(perPage, 10)
                return photos
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.fetchPhotosResponse(.success(photos))) {
            $0.isLoading = false
            $0.photos = photos
        }
    }

    func test_onAppear_whenPhotosAlreadyLoaded_doesNothing() async {
        let store = TestStore(
            initialState: TopicRowFeature.State(topic: topic, photos: [.fixture(id: "p1")])
        ) {
            TopicRowFeature()
        }

        await store.send(.onAppear)
    }

    func test_onAppear_failure_stopsLoadingSilently() async {
        let store = TestStore(initialState: TopicRowFeature.State(topic: topic)) {
            TopicRowFeature()
        } withDependencies: {
            $0.topicsClient.fetchTopicPhotos = { @Sendable _, _, _ in throw AppError.network("Boom") }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.fetchPhotosResponse(.failure(.network("Boom")))) {
            $0.isLoading = false
        }
    }

    // MARK: - photoTapped

    func test_photoTapped_forwardsToDelegate() async {
        let photo = Photo.fixture(id: "p1")
        let store = TestStore(initialState: TopicRowFeature.State(topic: topic)) {
            TopicRowFeature()
        }

        await store.send(.photoTapped(photo))
        await store.receive(.delegate(.photoTapped(photo)))
    }
}
