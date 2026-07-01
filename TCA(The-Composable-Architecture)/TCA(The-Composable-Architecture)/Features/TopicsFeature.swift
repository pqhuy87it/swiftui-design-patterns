import ComposableArchitecture
import Foundation

@Reducer
struct TopicsFeature {
    @ObservableState
    struct State: Equatable {
        var isLoading: Bool = false
        var errorMessage: String? = nil
        var heroTopic: Topic? = nil
        var rows: IdentifiedArrayOf<TopicRowFeature.State> = []
        var selectedPhoto: Photo? = nil
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case fetchTopicsResponse(Result<[Topic], AppError>)
        case row(IdentifiedActionOf<TopicRowFeature>)
    }

    @Dependency(\.topicsClient) var topicsClient

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                guard state.heroTopic == nil && state.rows.isEmpty else { return .none }
                
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    await send(.fetchTopicsResponse(
                        Result { try await topicsClient.fetchTopics(1, 10) }
                            .mapError(AppError.init)
                    ))
                }
                
            case let .fetchTopicsResponse(.success(topics)):
                state.isLoading = false
                
                if let firstTopic = topics.first {
                    state.heroTopic = firstTopic
                    
                    let remainingTopics = topics.dropFirst()
                    
                    state.rows = IdentifiedArray(
                        uniqueElements: remainingTopics.map { TopicRowFeature.State(topic: $0) }
                    )
                }
                return .none
                
            case let .fetchTopicsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.errorDescription
                return .none
                
            case let .row(.element(id: _, action: .delegate(.photoTapped(photo)))):
                state.selectedPhoto = photo
                return .none

            case .row:
                return .none
            }
        }
        .forEach(\.rows, action: \.row) {
            TopicRowFeature()
        }
    }
}
