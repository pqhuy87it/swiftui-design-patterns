import Foundation
import ComposableArchitecture

@DependencyClient
struct TopicsClient {
    var fetchTopics: (_ page: Int, _ perPage: Int) async throws -> [Topic]
    var fetchTopicPhotos: (_ slug: String, _ page: Int, _ perPage: Int) async throws -> [Photo]
}

extension TopicsClient: DependencyKey {
    static let liveValue: TopicsClient = {
        let topicsRepository = TopicsRepository(session: .shared)

        return Self(
            fetchTopics: { page, perPage in
                let dtos = try await topicsRepository.fetchTopics(page: page, perPage: perPage)
                return dtos.map { $0.toDomain() }
            },
            fetchTopicPhotos: { slug, page, perPage in
                let dtos = try await topicsRepository.fetchTopicPhotos(slug: slug, page: page, perPage: perPage)
                return dtos.map { $0.toDomain() }
            }
        )
    }()
    
    static let previewValue = Self(
        fetchTopics: { _, _ in [.mock] },
        fetchTopicPhotos: { _, _, _ in [.mock] }
    )
}

extension DependencyValues {
    var topicsClient: TopicsClient {
        get { self[TopicsClient.self] }
        set { self[TopicsClient.self] = newValue }
    }
}
