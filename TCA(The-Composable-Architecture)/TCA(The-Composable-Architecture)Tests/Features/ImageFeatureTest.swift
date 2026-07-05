import XCTest
import UIKit
import ComposableArchitecture
@testable import TCA_The_Composable_Architecture_

@MainActor
final class ImageFeatureTest: XCTestCase {
    private let url = URL(string: "https://images.unsplash.com/photo-1.jpg")!

    func test_loadImage_success_setsImage() async {
        let image = UIImage(systemName: "photo")!
        let store = TestStore(initialState: ImageFeature.State(url: url)) {
            ImageFeature()
        } withDependencies: {
            $0.imageClient.loadImage = { @Sendable _ in image }
        }

        await store.send(.loadImage) {
            $0.isLoading = true
        }
        // Action không Equatable (chứa UIImage) nên nhận qua case key path
        await store.receive(\.imageResponse.success) {
            $0.isLoading = false
            $0.image = image
        }
    }

    func test_loadImage_whenImageAlreadyLoaded_doesNothing() async {
        let store = TestStore(
            initialState: ImageFeature.State(url: url, image: UIImage())
        ) {
            ImageFeature()
        }

        await store.send(.loadImage)
    }

    func test_loadImage_failure_setsErrorMessage() async {
        let store = TestStore(initialState: ImageFeature.State(url: url)) {
            ImageFeature()
        } withDependencies: {
            $0.imageClient.loadImage = { @Sendable _ in throw AppError.network("Boom") }
        }

        await store.send(.loadImage) {
            $0.isLoading = true
        }
        await store.receive(\.imageResponse.failure) {
            $0.isLoading = false
            $0.errorMessage = "Boom"
        }
    }
}
