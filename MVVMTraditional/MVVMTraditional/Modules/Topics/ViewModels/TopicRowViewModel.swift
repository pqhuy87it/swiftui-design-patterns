import Foundation
import Combine

@MainActor
final class TopicRowViewModel: ObservableObject {
    @Published private(set) var photos: [Photo] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasError = false

    let topic: Topic
    private let topicsService: TopicsServiceProtocol

    init(topic: Topic, topicsService: TopicsServiceProtocol) {
        self.topic = topic
        self.topicsService = topicsService
    }

    func loadPhotos() async {
        guard photos.isEmpty, !isLoading else {
            return
        }
        
        isLoading = true
        hasError = false
        
        defer { isLoading = false }

        do {
            photos = try await topicsService.fetchTopicPhotos(slug: topic.slug, page: 1, perPage: 10)
        } catch {
            hasError = true
        }
    }
}
