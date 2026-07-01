import SwiftUI

struct TopicHorizontalRow: View {
    @StateObject private var viewModel: TopicRowViewModel

    init(viewModel: @autoclosure @escaping () -> TopicRowViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.topic.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity).frame(height: 260)
            } else if viewModel.hasError {
                Text("Failed to load photos")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.photos) { photo in
                            NavigationLink(value: photo) {
                                TopicCardView(photo: photo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .task {
            await viewModel.loadPhotos()
        }
    }
}
