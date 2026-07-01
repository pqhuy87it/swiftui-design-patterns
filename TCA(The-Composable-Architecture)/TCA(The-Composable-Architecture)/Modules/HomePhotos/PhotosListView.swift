import SwiftUI
import ComposableArchitecture

struct PhotosListView: View {
    @Bindable var store: StoreOf<PhotosFeature>
    
    private let columnCount = 2
    private let spacing: CGFloat = 12

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView("Loading photos...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let error = store.errorMessage {
                    ErrorView(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: error])) {
                        store.send(.onAppear)
                    }
                } else {
                    ScrollView {
                        HStack(alignment: .top, spacing: spacing) {
                            ForEach(0..<columnCount, id: \.self) { col in
                                LazyVStack(spacing: spacing) {
                                    ForEach(masonryColumns(for: store.photos)[col]) { photo in
                                        Button {
                                            store.send(.photoTapped(photo))
                                        } label: {
                                            PhotoCell(photo: photo)
                                        }
                                        .buttonStyle(.plain)
                                        .onAppear {
                                            if photo.id == store.photos.last?.id {
                                                store.send(.loadMorePhotos)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()

                        if store.isLoadingMore {
                            ProgressView()
                                .padding(.vertical, 16)
                        }
                    }
                    .refreshable {
                        store.send(.onAppear)
                    }
                }
            }
            .navigationTitle("Unsplash Photos")
            .navigationDestination(item: $store.selectedPhoto) { photo in
                PhotoDetailView(photo: photo)
            }
            .onAppear {
                if store.photos.isEmpty {
                    store.send(.onAppear)
                }
            }
        }
    }
    
    private func masonryColumns(for photos: [Photo]) -> [[Photo]] {
        var columns = Array(repeating: [Photo](), count: columnCount)
        var heights = Array(repeating: CGFloat(0), count: columnCount)

        for photo in photos {
            let shortest = heights.indices.min(by: { heights[$0] < heights[$1] })!
            columns[shortest].append(photo)
            heights[shortest] += CGFloat(photo.height) / CGFloat(photo.width)
        }

        return columns
    }
}

#Preview {
    PhotosListView(
        store: Store(initialState: PhotosFeature.State(photos: [.mock])) {
            PhotosFeature()
        }
    )
}
