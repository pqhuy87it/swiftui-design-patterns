import Foundation
import UIKit
@testable import MVVMTraditional

// MARK: - Test error

struct TestError: Error, Equatable {}

// MARK: - Entity fixtures (@MainActor vì entity bị cô lập main-actor; decode thẳng từ JSON)

@MainActor
enum EntityFixtures {
    static func photos(ids: [String]) -> [Photo] {
        try! JSONDecoder().decode([Photo].self, from: JSONFixtures.photosArray(ids: ids))
    }

    static func photo(id: String) -> Photo {
        photos(ids: [id])[0]
    }

    static func topics(_ topics: [(id: String, slug: String)]) -> [Topic] {
        try! JSONDecoder().decode([Topic].self, from: JSONFixtures.topicsArray(topics))
    }

    static func searchResult(total: Int, totalPages: Int, photoIDs: [String]) -> SearchResult {
        try! JSONDecoder().decode(
            SearchResult.self,
            from: JSONFixtures.searchResult(total: total, totalPages: totalPages, photoIDs: photoIDs)
        )
    }
}

// MARK: - Mock services

@MainActor
final class MockPhotosService: PhotosServiceProtocol {
    var handler: (Int, Int) async throws -> [Photo] = { _, _ in [] }
    private(set) var callCount = 0
    private(set) var requestedPages: [Int] = []

    func fetchPhotos(page: Int, perPage: Int) async throws -> [Photo] {
        callCount += 1
        requestedPages.append(page)
        return try await handler(page, perPage)
    }
}

@MainActor
final class MockTopicsService: TopicsServiceProtocol {
    var topicsHandler: (Int, Int) async throws -> [Topic] = { _, _ in [] }
    var topicPhotosHandler: (String, Int, Int) async throws -> [Photo] = { _, _, _ in [] }
    private(set) var topicsCallCount = 0
    private(set) var lastSlug: String?

    func fetchTopics(page: Int, perPage: Int) async throws -> [Topic] {
        topicsCallCount += 1
        return try await topicsHandler(page, perPage)
    }

    func fetchTopicPhotos(slug: String, page: Int, perPage: Int) async throws -> [Photo] {
        lastSlug = slug
        return try await topicPhotosHandler(slug, page, perPage)
    }
}

@MainActor
final class MockSearchService: SearchServiceProtocol {
    var searchHandler: (String, Int, Int) async throws -> SearchResult = { _, _, _ in throw TestError() }
    var historyResult: Result<[DBModel.SearchHistory], Error> = .success([])
    var saveError: Error?
    private(set) var searchCallCount = 0
    private(set) var lastQuery: String?
    private(set) var savedKeywords: [String] = []

    func searchPhotos(query: String, page: Int, perPage: Int) async throws -> SearchResult {
        searchCallCount += 1
        lastQuery = query
        return try await searchHandler(query, page, perPage)
    }

    func fetchSearchHistory() async throws -> [DBModel.SearchHistory] {
        try historyResult.get()
    }

    func saveSearchKeyword(_ keyword: String) async throws {
        if let saveError { throw saveError }
        savedKeywords.append(keyword)
    }
}

@MainActor
final class MockImagesService: ImagesServiceProtocol {
    var result: Result<UIImage, Error> = .success(UIImage())
    private(set) var lastURL: URL?

    func loadImage(url: URL) async throws -> UIImage {
        lastURL = url
        return try result.get()
    }
}
