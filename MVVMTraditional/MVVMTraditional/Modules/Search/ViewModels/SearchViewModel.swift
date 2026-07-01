import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    
    // MARK: - Published state
    
    @Published var searchText: String = ""
    @Published private(set) var searchHistory: [String] = []
    @Published private(set) var photos: [Photo] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasSearched = false

    // MARK: - Dependencies
    
    private let searchService: SearchServiceProtocol
    private let perPage = 30
    private var page = 1
    private var currentQuery = ""
    private var canLoadMore = false

    init(searchService: SearchServiceProtocol) {
        self.searchService = searchService
    }

    // MARK: - Intents

    func loadHistory() async {
        do {
            let history = try await searchService.fetchSearchHistory()
            searchHistory = history.map { $0.keyword }
        } catch {
            // Lỗi đọc DB thì bỏ qua, không cần chặn UI
        }
    }

    /// Active search (submit/click history): save keyword + reload history + search.
    func performSearch(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        searchText = trimmed
        try? await searchService.saveSearchKeyword(trimmed)
        await loadHistory()
        await search(query: trimmed)
    }

    /// Scroll to the last image -> load the next page for the current keyword.
    func loadMore() async {
        guard !isLoadingMore, canLoadMore, !currentQuery.isEmpty else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let result = try await searchService.searchPhotos(query: currentQuery, page: page, perPage: perPage)
            photos += result.results
            canLoadMore = page < result.totalPages
            page += 1
        } catch {
            canLoadMore = false
        }
    }

    /// Clear the search box -> return to the history screen.
    func clearSearch() {
        hasSearched = false
        photos = []
        errorMessage = nil
        canLoadMore = false
        currentQuery = ""
        Task { await loadHistory() }
    }

    // MARK: - Private

    private func search(query: String) async {
        currentQuery = query
        page = 1
        canLoadMore = false
        hasSearched = true
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await searchService.searchPhotos(query: query, page: page, perPage: perPage)
            photos = result.results
            canLoadMore = page < result.totalPages
            page = 2
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
