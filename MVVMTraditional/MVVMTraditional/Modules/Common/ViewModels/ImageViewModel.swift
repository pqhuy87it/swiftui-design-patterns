import SwiftUI
import Combine

@MainActor
final class ImageViewModel: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false
    @Published private(set) var hasError = false

    private let imageURL: URL
    private let imagesService: ImagesServiceProtocol

    init(imageURL: URL, imagesService: ImagesServiceProtocol) {
        self.imageURL = imageURL
        self.imagesService = imagesService
    }

    func loadImage() async {
        // Chỉ tải một lần
        guard image == nil, !isLoading else { return }

        isLoading = true
        hasError = false
        defer { isLoading = false }

        do {
            image = try await imagesService.loadImage(url: imageURL)
        } catch {
            hasError = true
        }
    }
}
