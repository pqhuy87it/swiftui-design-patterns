import SwiftUI
import ComposableArchitecture

struct SearchView: View {
    @Bindable var store: StoreOf<SearchFeature>
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Search Photos")
                .searchable(text: $store.searchText, prompt: "Enter keyword (e.g.: Nature, Cats...)")
                .onSubmit(of: .search) {
                    store.send(.performSearch(store.searchText))
                }
                .onAppear {
                    store.send(.onAppear)
                }
                .navigationDestination(item: $store.selectedPhoto) { photo in
                    PhotoDetailView(photo: photo)
                }
        }
    }
    
    @ViewBuilder private var content: some View {
        if store.shouldShowHistory {
            historyView()
        } else if store.isLoading {
            ProgressView("Searching...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = store.errorMessage {
            ErrorView(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: error])) {
                store.send(.performSearch(store.searchText))
            }
        } else if store.photos.isEmpty {
            placeholderView(message: "No results found", icon: "exclamationmark.triangle")
        } else {
            resultsGridView(store.photos)
        }
    }
}

// MARK: - Subviews

private extension SearchView {
    @ViewBuilder
    func historyView() -> some View {
        if store.searchHistory.isEmpty {
            placeholderView(message: "Search for something!", icon: "magnifyingglass")
        } else {
            List {
                Section(header: Text("Search History")) {
                    ForEach(store.searchHistory, id: \.self) { keyword in
                        Button(action: {
                            store.send(.performSearch(keyword))
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
            .listStyle(.insetGrouped)
        }
    }
    
    func resultsGridView(_ photos: [Photo]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(photos) { photo in
                    Button {
                        store.send(.photoTapped(photo))
                    } label: {
                        PhotoCell(photo: photo)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
    
    func placeholderView(message: String, icon: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon).font(.system(size: 50)).foregroundColor(.gray)
            Text(message).font(.headline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SearchView(
        store: Store(initialState: SearchFeature.State()) {
            SearchFeature()
        }
    )
}
