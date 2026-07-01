import SwiftUI
import Combine

@MainActor
final class PhotoDetailViewModel: ObservableObject {
    let photo: Photo

    init(photo: Photo) {
        self.photo = photo
    }

    // MARK: - Derived display data

    var imageURL: URL { photo.urls.regular }
    var authorName: String { photo.user.name ?? photo.user.username }
    var description: String? { photo.description ?? photo.altDescription }
    var sizeText: String { "Original size: \(photo.width) x \(photo.height)" }
}
