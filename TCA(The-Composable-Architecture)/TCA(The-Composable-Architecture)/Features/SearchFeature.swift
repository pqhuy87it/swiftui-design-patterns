import ComposableArchitecture
import Foundation

@Reducer
struct SearchFeature {
    @ObservableState
    struct State: Equatable {
        var searchText: String = ""
        var searchHistory: [String] = []
        var photos: [Photo] = []
        var isLoading: Bool = false
        var errorMessage: String? = nil
        var selectedPhoto: Photo? = nil
        var shouldShowHistory: Bool {
            searchText.isEmpty || (!isLoading && photos.isEmpty && errorMessage == nil)
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case loadHistory
        case historyResponse(Result<[String], AppError>)
        case performSearch(String)
        case search(String)
        case searchResponse(Result<SearchResult, AppError>)
        case clearResults
        case photoTapped(Photo)
    }

    @Dependency(\.searchClient) var searchClient
    @Dependency(\.mainQueue) var mainQueue

    private nonisolated enum CancelID { case debounce, search }

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.searchText):
                if state.searchText.isEmpty {
                    return .merge(
                        .cancel(id: CancelID.search),
                        .send(.clearResults)
                    )
                }
                
                return .run { [query = state.searchText] send in
                    await send(.search(query))
                }
                .debounce(id: CancelID.debounce, for: 0.5, scheduler: mainQueue)

            case .binding:
                return .none

            case .onAppear, .loadHistory:
                return .run { send in
                    await send(.historyResponse(
                        Result { try await searchClient.getHistory() }
                            .mapError(AppError.init)
                    ))
                }

            case let .historyResponse(.success(history)):
                state.searchHistory = history
                return .none

            case .historyResponse(.failure):
                return .none

            case let .performSearch(keyword):
                let trimmed = keyword.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return .none }

                state.searchText = trimmed

                return .run { send in
                    try? await searchClient.saveKeyword(trimmed)
                    
                    await send(.loadHistory)
                    await send(.search(trimmed))
                }
            case let .search(keyword):
                let trimmed = keyword.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return .none }

                state.isLoading = true
                state.errorMessage = nil

                return .run { send in
                    await send(.searchResponse(
                        Result { try await searchClient.searchPhotos(trimmed, 1, 30) }
                            .mapError(AppError.init)
                    ))
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)

            case let .searchResponse(.success(result)):
                state.isLoading = false
                state.photos = result.results
                return .none

            case let .searchResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.errorDescription
                return .none

            case .clearResults:
                state.photos = []
                state.isLoading = false
                state.errorMessage = nil
                return .send(.loadHistory)

            case let .photoTapped(photo):
                state.selectedPhoto = photo
                return .none
            }
        }
    }
}
