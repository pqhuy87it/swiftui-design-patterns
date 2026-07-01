import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var photos = PhotosFeature.State()
        var topics = TopicsFeature.State()
        var search = SearchFeature.State()
    }

    enum Action {
        case photos(PhotosFeature.Action)
        case topics(TopicsFeature.Action)
        case search(SearchFeature.Action)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.photos, action: \.photos) {
            PhotosFeature()
        }
        
        Scope(state: \.topics, action: \.topics) {
            TopicsFeature()
        }
        
        Scope(state: \.search, action: \.search) {
            SearchFeature()
        }
    }
}
