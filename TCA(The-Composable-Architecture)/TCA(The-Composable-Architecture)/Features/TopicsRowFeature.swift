import ComposableArchitecture
import Foundation

@Reducer
struct TopicRowFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        var id: String { topic.id }
        let topic: Topic
        var photos: [Photo] = []
        var isLoading: Bool = false
    }

    enum Action: Equatable {
        case onAppear
        case fetchPhotosResponse(Result<[Photo], AppError>)
        case photoTapped(Photo)
        case delegate(Delegate)
        enum Delegate: Equatable {
            case photoTapped(Photo)
        }
    }

    @Dependency(\.topicsClient) var topicsClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.photos.isEmpty else { return .none }

                state.isLoading = true
                return .run { [slug = state.topic.slug] send in
                    await send(.fetchPhotosResponse(
                        Result { try await topicsClient.fetchTopicPhotos(slug, 1, 10) }
                            .mapError(AppError.init)
                    ))
                }

            case let .fetchPhotosResponse(.success(photos)):
                state.isLoading = false
                state.photos = photos
                return .none

            case .fetchPhotosResponse(.failure):
                state.isLoading = false
                return .none

            case let .photoTapped(photo):
                return .send(.delegate(.photoTapped(photo)))

            case .delegate:
                return .none
            }
        }
    }
}
