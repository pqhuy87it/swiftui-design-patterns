import Foundation
import Combine

@MainActor final class AppViewModelFactory: ViewModelFactory, ObservableObject {
    private let interactors: DIContainer.Interactors
    private let appState: Store<AppState>

    init(interactors: DIContainer.Interactors, appState: Store<AppState>) {
        self.interactors = interactors
        self.appState = appState
    }

    func makePhotosViewModel() -> PhotosViewModel {
        return PhotosViewModel(photosInteractor: interactors.photos)
    }

    func makePhotoDetailViewModel(photo: Photo) -> PhotoDetailViewModel {
        return PhotoDetailViewModel(photo: photo)
    }

    func makeImageViewModel(url: URL) -> ImageViewModel {
        return ImageViewModel(imageURL: url, interactor: interactors.images)
    }

    func makeTopicsViewModel() -> TopicsViewModel {
        return TopicsViewModel(photosInteractor: interactors.photos)
    }

    func makeTopicRowViewModel(topic: Topic) -> TopicRowViewModel {
        return TopicRowViewModel(topic: topic, photosInteractor: interactors.photos)
    }

    func makeSearchViewModel() -> SearchViewModel {
        return SearchViewModel(photosInteractor: interactors.photos, appState: appState)
    }
}
