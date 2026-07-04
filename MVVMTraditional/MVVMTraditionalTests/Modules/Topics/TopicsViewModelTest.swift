import XCTest
@testable import MVVMTraditional

@MainActor
final class TopicsViewModelTest: XCTestCase {

    func test_loadTopics_success_setsTopics() async {
        let service = MockTopicsService()
        service.topicsHandler = { _, _ in EntityFixtures.topics([("t1", "nature"), ("t2", "wallpapers")]) }
        let sut = TopicsViewModel(topicsService: service)

        await sut.loadTopics()

        XCTAssertEqual(sut.topics.map { $0.id }, ["t1", "t2"])
        XCTAssertNil(sut.errorMessage)
    }

    func test_loadTopics_whenAlreadyLoaded_doesNotReload() async {
        let service = MockTopicsService()
        service.topicsHandler = { _, _ in EntityFixtures.topics([("t1", "nature")]) }
        let sut = TopicsViewModel(topicsService: service)

        await sut.loadTopics()
        await sut.loadTopics()

        XCTAssertEqual(service.topicsCallCount, 1)
    }

    func test_loadTopics_failure_setsErrorMessage() async {
        let service = MockTopicsService()
        service.topicsHandler = { _, _ in throw TestError() }
        let sut = TopicsViewModel(topicsService: service)

        await sut.loadTopics()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.topics.isEmpty)
    }

    func test_refresh_reloadsEvenWhenLoaded() async {
        let service = MockTopicsService()
        service.topicsHandler = { _, _ in EntityFixtures.topics([("t1", "nature")]) }
        let sut = TopicsViewModel(topicsService: service)

        await sut.loadTopics()
        await sut.refresh()

        XCTAssertEqual(service.topicsCallCount, 2)
    }
}
