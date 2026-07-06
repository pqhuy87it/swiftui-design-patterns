import XCTest
import ComposableArchitecture
@testable import TCA_The_Composable_Architecture_

@MainActor
final class TopicsFeatureTest: XCTestCase {

    // MARK: - onAppear

    func test_onAppear_success_setsHeroAndRows() async {
        let topics = [
            Topic.fixture(id: "t1", slug: "nature"),
            Topic.fixture(id: "t2", slug: "wallpapers"),
            Topic.fixture(id: "t3", slug: "animals")
        ]
        let store = TestStore(initialState: TopicsFeature.State()) {
            TopicsFeature()
        } withDependencies: {
            $0.topicsClient.fetchTopics = { @Sendable page, perPage in
                XCTAssertEqual(page, 1)
                XCTAssertEqual(perPage, 10)
                return topics
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.fetchTopicsResponse(.success(topics))) {
            $0.isLoading = false
            $0.heroTopic = topics[0]
            $0.rows = IdentifiedArray(
                uniqueElements: topics.dropFirst().map { TopicRowFeature.State(topic: $0) }
            )
        }
    }

    func test_onAppear_whenAlreadyLoaded_doesNothing() async {
        let store = TestStore(
            initialState: TopicsFeature.State(
                heroTopic: .fixture(id: "t1", slug: "nature"),
                rows: [TopicRowFeature.State(topic: .fixture(id: "t2", slug: "wallpapers"))]
            )
        ) {
            TopicsFeature()
        }

        await store.send(.onAppear)
    }

    func test_onAppear_failure_setsErrorMessage() async {
        let store = TestStore(initialState: TopicsFeature.State()) {
            TopicsFeature()
        } withDependencies: {
            $0.topicsClient.fetchTopics = { @Sendable _, _ in throw AppError.network("Boom") }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.fetchTopicsResponse(.failure(.network("Boom")))) {
            $0.isLoading = false
            $0.errorMessage = "Boom"
        }
    }

    func test_fetchTopicsResponse_emptyList_keepsStateEmpty() async {
        let store = TestStore(initialState: TopicsFeature.State()) {
            TopicsFeature()
        }

        await store.send(.fetchTopicsResponse(.success([])))
    }

    // MARK: - Row delegate

    func test_rowPhotoTappedDelegate_setsSelectedPhoto() async {
        let topic = Topic.fixture(id: "t2", slug: "wallpapers")
        let photo = Photo.fixture(id: "p1")
        let store = TestStore(
            initialState: TopicsFeature.State(
                heroTopic: .fixture(id: "t1", slug: "nature"),
                rows: [TopicRowFeature.State(topic: topic)]
            )
        ) {
            TopicsFeature()
        }

        await store.send(.row(.element(id: topic.id, action: .delegate(.photoTapped(photo))))) {
            $0.selectedPhoto = photo
        }
    }
}
