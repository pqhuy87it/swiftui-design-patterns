import UIKit

protocol ImagesServiceProtocol {
    func loadImage(url: URL) async throws -> UIImage
}
