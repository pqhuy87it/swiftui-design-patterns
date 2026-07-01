import SwiftUI
import Combine

@MainActor
final class PhotosViewModel: ObservableObject {
    // MARK: - Published state
    @Published private(set) var photos: [Photo] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies
    private let photosService: PhotosServiceProtocol
    private let perPage = 30
    private var page = 1
    private var canLoadMore = true

    init(photosService: PhotosServiceProtocol) {
        self.photosService = photosService
    }

    // MARK: - Intents

    /// First time displayed: only load if there is no data.
    func loadPhotos() async {
        guard photos.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        await fetchFirstPage()
    }

    /// Pull-to-refresh: Reload the first page (do not enable full-screen loader).
    func refresh() async {
        await fetchFirstPage()
    }

    /// Scroll to the last image -> load the next page and add it to the list.
    func loadMore() async {
        guard !isLoadingMore, canLoadMore, !photos.isEmpty else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let next = try await photosService.fetchPhotos(page: page, perPage: perPage)
            photos += next
            canLoadMore = next.count == perPage
            page += 1
        } catch {
            // Keep the existing list if the next page crashes.
            canLoadMore = false
        }
    }

    // MARK: - Private

    private func fetchFirstPage() async {
        page = 1
        canLoadMore = true
        errorMessage = nil

        do {
            let fetched = try await photosService.fetchPhotos(page: page, perPage: perPage)
            photos = fetched
            canLoadMore = fetched.count == perPage
            page = 2
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
