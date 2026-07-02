import SwiftUI

struct CleanArchitectureMainView: View {
    var body: some View {
        TabView {
            PhotosListView()
                .tabItem { Label("Home", systemImage: "house") }

            TopicsListView()
                .tabItem { Label("Topics", systemImage: "square.grid.2x2") }

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
        }
    }
}

#Preview {
    CleanArchitectureMainView()
}
