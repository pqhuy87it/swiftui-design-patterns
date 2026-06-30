import SwiftUI
import Combine

@MainActor
final class PhotosViewModel: UDFViewModel {
    
    // MARK: - State
    
    struct State {
        var photos: Loadable<[Photo]> = .notRequested
    }
    
    // MARK: - Action
    
    enum Action {
        case loadPhotos
        case refreshPhotos
    }
    
    @Published private(set) var state: State
    
    // Dependencies
    private let photosInteractor: PhotosInteractorProtocol
    
    init(photosInteractor: PhotosInteractorProtocol) {
        self.photosInteractor = photosInteractor
        self.state = State()
    }
    
    // MARK: - Dispatch Action
    
    func send(_ action: Action) {
        switch action {
        case .loadPhotos:
            guard state.photos == .notRequested else { return }
            Task { await fetchPhotos() }
            
        case .refreshPhotos:
            Task { await fetchPhotos() }
        }
    }
    
    // MARK: - Async/Await Logic
    
    private func fetchPhotos() async {
        state.photos = .isLoading(last: state.photos.value, cancelBag: CancelBag())
        
        do {
            let fetchedPhotos = try await photosInteractor.fetchPhotos(page: 1, perPage: 30)
            state.photos = .loaded(fetchedPhotos)
        } catch {
            state.photos = .failed(error)
        }
    }
}
