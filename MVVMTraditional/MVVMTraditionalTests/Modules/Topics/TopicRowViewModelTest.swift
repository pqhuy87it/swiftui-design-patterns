import XCTest
@testable import MVVMTraditional

@MainActor
final class TopicRowViewModelTest: XCTestCase {

    private func makeTopic() -> Topic {
        EntityFixtures.topics([("t1", "nature")])[0]
    }

    func test_loadPhotos_success_usesTopicSlug() async {
        let service = MockTopicsService()
        service.topicPhotosHandler = { _, _, _ in EntityFixtures.photos(ids: ["p1", "p2"]) }
        let sut = TopicRowViewModel(topic: makeTopic(), topicsService: service)

        await sut.loadPhotos()

        XCTAssertEqual(sut.photos.map { $0.id }, ["p1", "p2"])
        XCTAssertEqual(service.lastSlug, "nature")
        XCTAssertFalse(sut.hasError)
    }

    func test_loadPhotos_whenAlreadyLoaded_isNoOp() async {
        let service = MockTopicsService()
        var callCount = 0
        service.topicPhotosHandler = { _, _, _ in
            callCount += 1
            return EntityFixtures.photos(ids: ["p1"])
        }
        let sut = TopicRowViewModel(topic: makeTopic(), topicsService: service)

        await sut.loadPhotos()
        await sut.loadPhotos()

        XCTAssertEqual(callCount, 1)
    }

    func test_loadPhotos_failure_setsHasError() async {
        let service = MockTopicsService()
        service.topicPhotosHandler = { _, _, _ in throw TestError() }
        let sut = TopicRowViewModel(topic: makeTopic(), topicsService: service)

        await sut.loadPhotos()

        XCTAssertTrue(sut.hasError)
        XCTAssertTrue(sut.photos.isEmpty)
    }
}
