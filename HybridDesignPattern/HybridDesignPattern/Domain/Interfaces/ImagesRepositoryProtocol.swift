import UIKit

// Domain abstraction — KHÔNG kế thừa APIRepositoryProtocol để tầng Domain
// không phụ thuộc vào transport (URLSession/HTTP/baseURL).
protocol ImagesRepositoryProtocol {
    func loadImage(url: URL) async throws -> UIImage
}
