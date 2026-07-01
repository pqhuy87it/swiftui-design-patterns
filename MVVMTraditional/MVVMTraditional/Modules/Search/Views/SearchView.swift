import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel

    private let columnCount = 2
    private let spacing: CGFloat = 16

    init(viewModel: @autoclosure @escaping () -> SearchViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Search Photos")
                .searchable(text: $viewModel.searchText, prompt: "Enter keyword (e.g.: Nature, Cats...)")
                .onChange(of: viewModel.searchText) { _, newValue in
                    if newValue.isEmpty { viewModel.clearSearch() }
                }
                .onSubmit(of: .search) {
                    Task { await viewModel.performSearch(viewModel.searchText) }
                }
                .task {
                    await viewModel.loadHistory()
                }
                .navigationDestination(for: Photo.self) { photo in
                    PhotoDetailView(viewModel: PhotoDetailViewModel(photo: photo))
                }
        }
    }

    @ViewBuilder private var content: some View {
        if !viewModel.hasSearched {
            historyView()
        } else if viewModel.isLoading {
            ProgressView("Searching...")
                .progressViewStyle(CircularProgressViewStyle())
        } else if let error = viewModel.errorMessage {
            ErrorView(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: error])) {
                Task { await viewModel.performSearch(viewModel.searchText) }
            }
        } else if viewModel.photos.isEmpty {
            placeholderView(message: "No results found", icon: "exclamationmark.triangle")
        } else {
            resultsGridView(viewModel.photos)
        }
    }
}

// MARK: - Subviews

private extension SearchView {
    @ViewBuilder
    func historyView() -> some View {
        if viewModel.searchHistory.isEmpty {
            placeholderView(message: "Search for something!", icon: "magnifyingglass")
        } else {
            List {
                Section(header: Text("Search History")) {
                    ForEach(viewModel.searchHistory, id: \.self) { keyword in
                        Button(action: {
                            Task { await viewModel.performSearch(keyword) }
                        }) {
                            HStack {
                                Image(systemName: "clock").foregroundColor(.gray)
                                Text(keyword).foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "magnifyingglass").foregroundColor(.blue).font(.caption)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }

    func resultsGridView(_ photos: [Photo]) -> some View {
        ScrollView {
            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columnCount, id: \.self) { col in
                    LazyVStack(spacing: spacing) {
                        ForEach(masonryColumns(for: photos)[col]) { photo in
                            NavigationLink(value: photo) {
                                PhotoCell(photo: photo)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                // When the last cell appears -> load the next page
                                if photo.id == photos.last?.id {
                                    Task { await viewModel.loadMore() }
                                }
                            }
                        }
                    }
                }
            }
            .padding()

            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.vertical, 16)
            }
        }
    }

    /// Divide the image into columns using the Masonry algorithm (the lowest column receives the next image).
    func masonryColumns(for photos: [Photo]) -> [[Photo]] {
        var columns = Array(repeating: [Photo](), count: columnCount)
        var heights = Array(repeating: CGFloat(0), count: columnCount)

        for photo in photos {
            let shortest = heights.indices.min(by: { heights[$0] < heights[$1] })!
            columns[shortest].append(photo)
            heights[shortest] += CGFloat(photo.height) / CGFloat(photo.width)
        }

        return columns
    }

    func placeholderView(message: String, icon: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon).font(.system(size: 50)).foregroundColor(.gray)
            Text(message).font(.headline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
