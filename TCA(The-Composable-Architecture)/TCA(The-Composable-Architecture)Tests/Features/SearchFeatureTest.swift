import XCTest
import ComposableArchitecture
@testable import TCA_The_Composable_Architecture_

@MainActor
final class SearchFeatureTest: XCTestCase {

    // MARK: - History

    func test_onAppear_loadsHistory() async {
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.searchClient.getHistory = { @Sendable in ["cat", "dog"] }
        }

        await store.send(.onAppear)
        await store.receive(.historyResponse(.success(["cat", "dog"]))) {
            $0.searchHistory = ["cat", "dog"]
        }
    }

    func test_historyResponse_failure_isIgnored() async {
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        }

        await store.send(.historyResponse(.failure(.network("Boom"))))
    }

    // MARK: - Typing + debounce

    func test_typingSearchText_debouncesAndSearches() async {
        let photos = [Photo.fixture(id: "p1")]
        let result = SearchResult(total: 1, totalPages: 1, results: photos)
        let mainQueue = DispatchQueue.test
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.mainQueue = mainQueue.eraseToAnyScheduler()
            $0.searchClient.searchPhotos = { @Sendable query, _, _ in
                XCTAssertEqual(query, "cat")
                return result
            }
        }

        // Gõ 2 lần liên tiếp trong cửa sổ debounce 0.5s -> chỉ search từ khóa cuối
        await store.send(.binding(.set(\.searchText, "ca"))) {
            $0.searchText = "ca"
        }
        await store.send(.binding(.set(\.searchText, "cat"))) {
            $0.searchText = "cat"
        }
        await mainQueue.advance(by: .milliseconds(500))

        await store.receive(.search("cat")) {
            $0.isLoading = true
        }
        await store.receive(.searchResponse(.success(result))) {
            $0.isLoading = false
            $0.photos = photos
        }
    }

    func test_clearingSearchText_clearsResultsAndReloadsHistory() async {
        var initialState = SearchFeature.State()
        initialState.searchText = "cat"
        initialState.photos = [.fixture(id: "p1")]
        let store = TestStore(initialState: initialState) {
            SearchFeature()
        } withDependencies: {
            $0.searchClient.getHistory = { @Sendable in ["cat"] }
        }

        await store.send(.binding(.set(\.searchText, ""))) {
            $0.searchText = ""
        }
        await store.receive(.clearResults) {
            $0.photos = []
        }
        await store.receive(.loadHistory)
        await store.receive(.historyResponse(.success(["cat"]))) {
            $0.searchHistory = ["cat"]
        }
    }

    // MARK: - search

    func test_search_success_setsPhotos() async {
        let photos = [Photo.fixture(id: "p1"), Photo.fixture(id: "p2")]
        let result = SearchResult(total: 2, totalPages: 1, results: photos)
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.searchClient.searchPhotos = { @Sendable query, page, perPage in
                XCTAssertEqual(query, "cat")
                XCTAssertEqual(page, 1)
                XCTAssertEqual(perPage, 30)
                return result
            }
        }

        await store.send(.search("  cat  ")) {
            $0.isLoading = true
        }
        await store.receive(.searchResponse(.success(result))) {
            $0.isLoading = false
            $0.photos = photos
        }
    }

    func test_search_whitespaceOnly_doesNothing() async {
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        }

        await store.send(.search("   "))
    }

    func test_search_failure_setsErrorMessage() async {
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.searchClient.searchPhotos = { @Sendable _, _, _ in throw AppError.network("Boom") }
        }

        await store.send(.search("cat")) {
            $0.isLoading = true
        }
        await store.receive(.searchResponse(.failure(.network("Boom")))) {
            $0.isLoading = false
            $0.errorMessage = "Boom"
        }
    }

    // MARK: - performSearch

    func test_performSearch_savesKeywordReloadsHistoryAndSearches() async {
        let recorder = KeywordRecorder()
        let photos = [Photo.fixture(id: "p1")]
        let result = SearchResult(total: 1, totalPages: 1, results: photos)
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.searchClient.saveKeyword = { @Sendable keyword in recorder.append(keyword) }
            $0.searchClient.getHistory = { @Sendable in recorder.values }
            $0.searchClient.searchPhotos = { @Sendable _, _, _ in result }
        }
        // Flow gồm nhiều action lồng nhau (loadHistory + search chạy song song),
        // chỉ kiểm tra các mốc quan trọng và state cuối cùng.
        store.exhaustivity = .off

        await store.send(.performSearch("  cat  ")) {
            $0.searchText = "cat"
        }
        await store.receive(.searchResponse(.success(result)))

        XCTAssertEqual(recorder.values, ["cat"])
        XCTAssertEqual(store.state.searchHistory, ["cat"])
        XCTAssertEqual(store.state.photos, photos)
        XCTAssertFalse(store.state.isLoading)
    }

    func test_performSearch_whitespaceOnly_doesNothing() async {
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        }

        await store.send(.performSearch("   "))
    }

    // MARK: - Misc

    func test_photoTapped_setsSelectedPhoto() async {
        let photo = Photo.fixture(id: "p1")
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        }

        await store.send(.photoTapped(photo)) {
            $0.selectedPhoto = photo
        }
    }

    func test_shouldShowHistory_reflectsState() {
        var state = SearchFeature.State()
        XCTAssertTrue(state.shouldShowHistory)

        state.searchText = "cat"
        state.isLoading = true
        XCTAssertFalse(state.shouldShowHistory)

        state.isLoading = false
        state.photos = [.fixture(id: "p1")]
        XCTAssertFalse(state.shouldShowHistory)

        state.photos = []
        state.errorMessage = "Boom"
        XCTAssertFalse(state.shouldShowHistory)
    }
}
