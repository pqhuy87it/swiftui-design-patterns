import SwiftUI
import SwiftData

struct MVVMTraditionalMainView: View {
    private static let modelContainer: ModelContainer = {
        do {
            return try ModelContainer.appModelContainer()
        } catch {
            fatalError("Unable to create ModelContainer: \(error)")
        }
    }()

    var body: some View {
        TabView {
            PhotosListView(
                viewModel: PhotosViewModel(photosService: PhotosService())
            )
            .tabItem { Label("Home", systemImage: "house") }

            TopicsListView(
                viewModel: TopicsViewModel(topicsService: TopicsService())
            )
            .tabItem { Label("Topics", systemImage: "square.grid.2x2") }

            SearchView(
                viewModel: SearchViewModel(searchService: Self.makeSearchService())
            )
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
        }
    }

    private static func makeSearchService() -> SearchService {
        SearchService(dbRepository: MainDBRepository(modelContainer: modelContainer))
    }
}

#Preview {
    MVVMTraditionalMainView()
}
