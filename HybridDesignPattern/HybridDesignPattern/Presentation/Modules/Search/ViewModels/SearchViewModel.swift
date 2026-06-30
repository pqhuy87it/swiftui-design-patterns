import Combine
import Foundation

@MainActor
final class SearchViewModel: UDFViewModel {
    
    // MARK: - State

    struct State {
        var searchText: String = ""
        var searchHistory: [String] = []
        var searchResult: Loadable<[Photo]> = .notRequested
        /// Phản ánh AppState.system.isActive — dùng để UI biết app đang ở foreground hay background
        var isAppActive: Bool = true
    }

    // MARK: - Action

    enum Action {
        case loadHistory
        case updateSearchText(String)
        case performSearch(String)
        case clearSearch
    }

    @Published private(set) var state: State = .init()
    private let searchInteractor: SearchInteractorProtocol
    private let appState: Store<AppState>
    private var cancellables = Set<AnyCancellable>()

    init(searchInteractor: SearchInteractorProtocol, appState: Store<AppState>) {
        self.searchInteractor = searchInteractor
        self.appState = appState

        appState
            .updates(for: \.system.isActive)
            .receive(on: RunLoop.main)
            .sink { [weak self] isActive in
                guard let self else { return }
                self.state.isAppActive = isActive
                if isActive {
                    Task { await self.fetchHistory() }
                } else {
                    self.state.searchResult = .notRequested
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Dispatch Action

    func send(_ action: Action) {
        switch action {
        case .loadHistory:
            Task { await fetchHistory() }

        case .updateSearchText(let text):
            state.searchText = text
            if text.isEmpty {
                send(.clearSearch)
            }

        case .performSearch(let query):
            let trimmed = query.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }

            Task {
                await saveKeyword(trimmed)
                await fetchHistory()
                await searchPhotos(query: trimmed)
            }

        case .clearSearch:
            state.searchResult = .notRequested
            Task { await fetchHistory() }
        }
    }

    // MARK: - Async Logic

    private func fetchHistory() async {
        do {
            let history = try await searchInteractor.getSearchHistory()
            state.searchHistory = history
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    private func saveKeyword(_ keyword: String) async {
        try? await searchInteractor.saveSearchKeyword(keyword)
    }

    private func searchPhotos(query: String) async {
        state.searchResult = .isLoading(last: state.searchResult.value,
                                        cancelBag: CancelBag())
        do {
            let result = try await searchInteractor.searchPhotos(query: query,
                                                                 page: 1,
                                                                 perPage: 30)
            state.searchResult = .loaded(result.results)
        } catch {
            state.searchResult = .failed(error)
        }
    }
}
