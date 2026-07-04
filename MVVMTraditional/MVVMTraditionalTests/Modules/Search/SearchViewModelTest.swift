import XCTest
@testable import MVVMTraditional

@MainActor
final class SearchViewModelTest: XCTestCase {

    func test_performSearch_success_setsResultsAndSavesKeyword() async {
        let service = MockSearchService()
        service.searchHandler = { _, _, _ in
            EntityFixtures.searchResult(total: 100, totalPages: 5, photoIDs: ["a", "b"])
        }
        let sut = SearchViewModel(searchService: service)

        await sut.performSearch("cat")

        XCTAssertEqual(sut.photos.map { $0.id }, ["a", "b"])
        XCTAssertTrue(sut.hasSearched)
        XCTAssertEqual(service.savedKeywords, ["cat"])
        XCTAssertEqual(service.lastQuery, "cat")
    }

    func test_performSearch_blankQuery_isIgnored() async {
        let service = MockSearchService()
        let sut = SearchViewModel(searchService: service)

        await sut.performSearch("   ")

        XCTAssertEqual(service.searchCallCount, 0)
        XCTAssertFalse(sut.hasSearched)
    }

    func test_performSearch_failure_setsErrorMessage() async {
        let service = MockSearchService()
        service.searchHandler = { _, _, _ in throw TestError() }
        let sut = SearchViewModel(searchService: service)

        await sut.performSearch("cat")

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.hasSearched)
    }

    func test_loadHistory_setsSearchHistory() async {
        let service = MockSearchService()
        service.historyResult = .success([
            DBModel.SearchHistory(keyword: "cat"),
            DBModel.SearchHistory(keyword: "nature")
        ])
        let sut = SearchViewModel(searchService: service)

        await sut.loadHistory()

        XCTAssertEqual(sut.searchHistory, ["cat", "nature"])
    }

    func test_loadMore_appendsNextPage() async {
        let service = MockSearchService()
        service.searchHandler = { _, page, _ in
            page == 1
                ? EntityFixtures.searchResult(total: 100, totalPages: 5, photoIDs: ["a", "b"])
                : EntityFixtures.searchResult(total: 100, totalPages: 5, photoIDs: ["c"])
        }
        let sut = SearchViewModel(searchService: service)

        await sut.performSearch("cat")
        await sut.loadMore()

        XCTAssertEqual(sut.photos.map { $0.id }, ["a", "b", "c"])
    }

    func test_clearSearch_resetsState() async {
        let service = MockSearchService()
        service.searchHandler = { _, _, _ in
            EntityFixtures.searchResult(total: 10, totalPages: 1, photoIDs: ["a"])
        }
        let sut = SearchViewModel(searchService: service)

        await sut.performSearch("cat")
        sut.clearSearch()

        XCTAssertFalse(sut.hasSearched)
        XCTAssertTrue(sut.photos.isEmpty)
        XCTAssertNil(sut.errorMessage)
    }
}
