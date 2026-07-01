import SwiftUI
import ComposableArchitecture

struct TCA_The_Composable_Architecture_MainView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        TabView {
            // Tab 1
            Tab("Home", systemImage: "house") {
                PhotosListView(store: store.scope(state: \.photos, action: \.photos))
            }

            // Tab 2
            Tab("Topic", systemImage: "scribble") {
                TopicsListView(store: store.scope(state: \.topics, action: \.topics))
            }

            // Tab 3
            Tab(role: .search) {
                SearchView(store: store.scope(state: \.search, action: \.search))
            }
        }
    }
}

#Preview {
    TCA_The_Composable_Architecture_MainView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
