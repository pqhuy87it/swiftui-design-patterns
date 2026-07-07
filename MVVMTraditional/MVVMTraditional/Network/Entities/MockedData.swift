import Foundation
import UIKit

// MARK: - Mock data

#if DEBUG
extension User {
    static let mock = User(
        id: "user-1",
        username: "johndoe",
        name: "John Doe",
        firstName: "John",
        lastName: "Doe",
        instagramUsername: "johndoe",
        twitterUsername: "johndoe",
        portfolioUrl: URL(string: "https://example.com"),
        totalCollections: 3,
        profileImage: .init(
            small: URL(string: "https://picsum.photos/id/64/64")!,
            medium: URL(string: "https://picsum.photos/id/64/128")!,
            large: URL(string: "https://picsum.photos/id/64/256")!
        )
    )
}

extension Photo {
    static let mock = Photo(
        id: "photo-1",
        width: 4000,
        height: 3000,
        color: "#60544D",
        description: "A beautiful landscape",
        altDescription: "Mountains at sunrise",
        urls: .init(
            raw: URL(string: "https://picsum.photos/id/10/4000/3000")!,
            full: URL(string: "https://picsum.photos/id/10/2000/1500")!,
            regular: URL(string: "https://picsum.photos/id/10/1080/810")!,
            small: URL(string: "https://picsum.photos/id/10/400/300")!,
            thumb: URL(string: "https://picsum.photos/id/10/200/150")!
        ),
        user: .mock
    )

    static func mock(id: String) -> Photo {
        Photo(
            id: id,
            width: mock.width,
            height: mock.height,
            color: mock.color,
            description: mock.description,
            altDescription: mock.altDescription,
            urls: mock.urls,
            user: mock.user
        )
    }

    static let mocks: [Photo] = (1...6).map { mock(id: "photo-\($0)") }
}

extension Topic {
    static let mock = Topic(
        id: "topic-1",
        slug: "nature",
        title: "Nature",
        description: "The great outdoors, captured beautifully.",
        coverPhoto: .mock
    )

    static func mock(id: String, title: String) -> Topic {
        Topic(
            id: id,
            slug: title.lowercased().replacingOccurrences(of: " ", with: "-"),
            title: title,
            description: mock.description,
            coverPhoto: mock.coverPhoto
        )
    }

    static let mocks: [Topic] = [
        mock(id: "topic-1", title: "Nature"),
        mock(id: "topic-2", title: "Wallpapers"),
        mock(id: "topic-3", title: "Architecture"),
        mock(id: "topic-4", title: "Travel")
    ]
}

// MARK: - Preview services (return mock data, no network)

struct PreviewImagesService: ImagesServiceProtocol {
    func loadImage(url: URL) async throws -> UIImage {
        UIImage(named: "samplePhoto") ?? UIImage(systemName: "photo") ?? UIImage()
    }
}

struct PreviewPhotosService: PhotosServiceProtocol {
    func fetchPhotos(page: Int, perPage: Int) async throws -> [Photo] {
        Photo.mocks
    }
}

struct PreviewTopicsService: TopicsServiceProtocol {
    func fetchTopics(page: Int, perPage: Int) async throws -> [Topic] {
        Topic.mocks
    }

    func fetchTopicPhotos(slug: String, page: Int, perPage: Int) async throws -> [Photo] {
        Photo.mocks
    }
}

struct PreviewSearchService: SearchServiceProtocol {
    func searchPhotos(query: String, page: Int, perPage: Int) async throws -> SearchResult {
        SearchResult(total: Photo.mocks.count, totalPages: 1, results: Photo.mocks)
    }

    @MainActor func fetchSearchHistory() async throws -> [DBModel.SearchHistory] {
        ["Nature", "Cats", "Mountains"].map { DBModel.SearchHistory(keyword: $0) }
    }

    func saveSearchKeyword(_ keyword: String) async throws {}
}
#endif
