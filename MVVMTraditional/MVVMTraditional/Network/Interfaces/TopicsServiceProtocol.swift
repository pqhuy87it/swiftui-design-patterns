import Foundation

protocol TopicsServiceProtocol {
    func fetchTopics(page: Int, perPage: Int) async throws -> [Topic]
    func fetchTopicPhotos(slug: String, page: Int, perPage: Int) async throws -> [Photo]
}
