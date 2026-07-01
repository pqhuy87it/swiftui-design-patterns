import SwiftUI
import ComposableArchitecture

@main
struct TCA_The_Composable_Architecture_App: App {
    @MainActor static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            TCA_The_Composable_Architecture_MainView(store: Self.store)
        }
    }
}
