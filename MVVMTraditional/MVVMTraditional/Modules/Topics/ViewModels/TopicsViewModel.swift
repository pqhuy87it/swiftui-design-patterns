import Foundation
import Combine

@MainActor
final class TopicsViewModel: ObservableObject {
    @Published private(set) var topics: [Topic] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let topicsService: TopicsServiceProtocol

    init(topicsService: TopicsServiceProtocol) {
        self.topicsService = topicsService
    }

    func loadTopics() async {
        guard topics.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        await fetchTopics()
    }

    func refresh() async {
        await fetchTopics()
    }

    private func fetchTopics() async {
        errorMessage = nil
        do {
            topics = try await topicsService.fetchTopics(page: 1, perPage: 10)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
