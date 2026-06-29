import SwiftUI
import Combine

@MainActor
final class PhotoDetailViewModel: UDFViewModel {

    // MARK: - UDF State & Action
    
    struct State {
        let photo: Photo
    }

    enum Action {
        // TODO: need implement
    }

    @Published private(set) var state: State

    init(photo: Photo) {
        self.state = State(photo: photo)
    }

    // MARK: - Dispatch
    
    func send(_ action: Action) {
        // TODO: need implement
    }

    // MARK: - Derived display data
    
    var imageURL: URL { state.photo.urls.regular }
    var authorName: String { state.photo.user.name }
    var description: String? { state.photo.description ?? state.photo.altDescription }
    var sizeText: String { "Original size: \(state.photo.width) x \(state.photo.height)" }
}
