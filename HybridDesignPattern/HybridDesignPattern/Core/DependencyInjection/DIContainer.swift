import SwiftUI
import SwiftData
import Combine

struct DIContainer {
    let appState: Store<AppState>
    let interactors: Interactors

    init(appState: Store<AppState> = .init(AppState()), interactors: Interactors) {
        self.appState = appState
        self.interactors = interactors
    }

    init(appState: AppState, interactors: Interactors) {
        self.init(appState: Store<AppState>(appState),
                  interactors: interactors)
    }
}

extension DIContainer {
    struct Repositories {
        let images: ImagesRepositoryProtocol
        let unsplash: UnsplashRepositoryProtocol
    }
    
    struct DBRepositories {
        let searchDB: SearchDBRepositoryProtocol
    }
    
    struct Interactors {
        let images: ImagesInteractorProtocol
        let photos: PhotosInteractorProtocol

        static var stub: Self {
            .init(images: StubImagesInteractor(),
                  photos: StubPhotosInteractor())
        }
    }
}

extension EnvironmentValues {
    @Entry var injected: DIContainer = DIContainer(appState: AppState(),
                                                   interactors: .stub)
}

extension View {
    func inject(_ container: DIContainer) -> some View {
        return self
            .environment(\.injected, container)
    }
}
