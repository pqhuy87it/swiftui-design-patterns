import SwiftUI

struct TopicsListView: View {
    @StateObject private var viewModel: TopicsViewModel

    init(viewModel: @autoclosure @escaping () -> TopicsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            content
                .background(Color.black.ignoresSafeArea())
                .ignoresSafeArea(.container, edges: .top)
                .navigationDestination(for: Photo.self) { photo in
                    PhotoDetailView(viewModel: PhotoDetailViewModel(photo: photo))
                }
        }
        .task {
            await viewModel.loadTopics()
        }
    }

    @ViewBuilder private var content: some View {
        if viewModel.isLoading && viewModel.topics.isEmpty {
            ProgressView().tint(.white)
        } else if let error = viewModel.errorMessage, viewModel.topics.isEmpty {
            ErrorView(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: error])) {
                Task { await viewModel.refresh() }
            }
        } else if let firstTopic = viewModel.topics.first {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    HeroHeaderView(topic: firstTopic)

                    VStack(spacing: 32) {
                        ForEach(viewModel.topics.dropFirst()) { topic in
                            TopicHorizontalRow(
                                viewModel: TopicRowViewModel(topic: topic, topicsService: TopicsService())
                            )
                        }
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 24)
                    .background(Color.black)
                }
            }
        }
    }
}
