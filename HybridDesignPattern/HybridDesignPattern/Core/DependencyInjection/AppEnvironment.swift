import Combine
import SwiftData
import UIKit

@MainActor struct AppEnvironment {
    let isRunningTests: Bool
    let diContainer: DIContainer
    let modelContainer: ModelContainer
}

extension AppEnvironment {
    static func bootstrap() -> AppEnvironment {
        let appState = Store<AppState>(AppState())
        let session = configuredURLSession()
        let modelContainer = configuredModelContainer()

        // 1. Configure Repositories
        let apiRepositories = configuredAPIRepositories(session: session)
        let dbRepositories = configuredDBRepositories(modelContainer: modelContainer)

        // 2. Configure Interactors (pass APIRepositories in)
        let interactors = configuredInteractors(appState: appState,
                                                repositories: apiRepositories,
                                                dbRepositories: dbRepositories)

        let diContainer = DIContainer(appState: appState,
                                      interactors: interactors)

        return AppEnvironment(isRunningTests: ProcessInfo.processInfo.isRunningTests,
                              diContainer: diContainer,
                              modelContainer: modelContainer)
    }

    private static func configuredURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        configuration.waitsForConnectivity = true
        configuration.httpMaximumConnectionsPerHost = 5
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = .shared
        return URLSession(configuration: configuration)
    }

    private static func configuredAPIRepositories(session: URLSession) -> DIContainer.Repositories {
        let photosRepository = PhotosRepository(session: session)
        let imagesRepository = ImagesRepository(session: session)
        let topicsRepository = TopicsRepository(session: session)
        return .init(images: imagesRepository, photos: photosRepository, topics: topicsRepository)
    }

    private static func configuredDBRepositories(modelContainer: ModelContainer) -> DIContainer.DBRepositories {
        let mainDBRepository = MainDBRepository(modelContainer: modelContainer)
        return .init(searchDB: mainDBRepository)
    }

    private static func configuredModelContainer() -> ModelContainer {
        do {
            return try ModelContainer.appModelContainer()
        } catch {
            return try! ModelContainer.appModelContainer(inMemoryOnly: true)
        }
    }

    private static func configuredInteractors(appState _: Store<AppState>,
                                              repositories: DIContainer.Repositories,
                                              dbRepositories: DIContainer.DBRepositories) -> DIContainer.Interactors
    {
        let photos = PhotosInteractor(photosRepository: repositories.photos,
                                      dbRepository: dbRepositories.searchDB)
        let images = ImagesInteractor(repository: repositories.images)
        let topics = TopicsInteractor(topicsRepository: repositories.topics)

        return .init(images: images,
                     photos: photos,
                     topics: topics)
    }
}

@MainActor extension AppEnvironment {
    func makeViewModelFactory() -> AppViewModelFactory {
        return AppViewModelFactory(interactors: diContainer.interactors,
                                   appState: diContainer.appState)
    }
}
