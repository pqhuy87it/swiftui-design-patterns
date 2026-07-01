import ComposableArchitecture
import Foundation

@Reducer
struct PhotosFeature {
    @ObservableState
    struct State: Equatable {
        var photos: [Photo] = []
        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var canLoadMore: Bool = true
        var currentPage: Int = 1
        var errorMessage: String? = nil
        var selectedPhoto: Photo? = nil
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case loadMorePhotos
        case fetchPhotosResponse(Result<[Photo], AppError>)
        case loadMorePhotosResponse(Result<[Photo], AppError>)
        case photoTapped(Photo)
    }

    @Dependency(\.photosClient) var photosClient

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                state.currentPage = 1
                state.canLoadMore = true

                return .run { send in
                    await send(.fetchPhotosResponse(
                        Result { try await photosClient.fetchPhotos(1, 30) }
                            .mapError(AppError.init)
                    ))
                }

            case .loadMorePhotos:
                guard !state.isLoadingMore, state.canLoadMore else { return .none }
                state.isLoadingMore = true
                let nextPage = state.currentPage + 1

                return .run { send in
                    await send(.loadMorePhotosResponse(
                        Result { try await photosClient.fetchPhotos(nextPage, 30) }
                            .mapError(AppError.init)
                    ))
                }

            case let .fetchPhotosResponse(.success(photos)):
                state.isLoading = false
                state.photos = photos
                state.currentPage = 1
                state.canLoadMore = photos.count == 30
                return .none

            case let .fetchPhotosResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.errorDescription
                return .none

            case let .loadMorePhotosResponse(.success(photos)):
                state.isLoadingMore = false
                state.photos += photos
                state.currentPage += 1
                state.canLoadMore = photos.count == 30
                return .none

            case let .loadMorePhotosResponse(.failure(error)):
                state.isLoadingMore = false
                state.errorMessage = error.errorDescription
                return .none

            case let .photoTapped(photo):
                state.selectedPhoto = photo
                return .none
            }
        }
    }
}
