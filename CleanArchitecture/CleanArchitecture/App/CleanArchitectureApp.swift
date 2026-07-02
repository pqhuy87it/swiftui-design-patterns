import SwiftUI
import SwiftData

@main
struct CleanArchitectureApp: App {
    private let environment = AppEnvironment.bootstrap()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            CleanArchitectureMainView()
                .modelContainer(environment.modelContainer)
                .inject(environment.diContainer)
        }
        .onChange(of: scenePhase) { _, newPhase in
            environment.diContainer.appState[\.system.isActive] = (newPhase == .active)
        }
    }
}
