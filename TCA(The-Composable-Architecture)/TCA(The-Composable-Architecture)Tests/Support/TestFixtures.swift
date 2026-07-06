import Foundation
@testable import TCA_The_Composable_Architecture_

// MARK: - Domain entity fixtures cho Feature test

extension Photo {
    static func fixture(id: String) -> Photo {
        let url = URL(string: "https://example.com/\(id).jpg")!
        return Photo(
            id: id,
            width: 100,
            height: 100,
            color: nil,
            description: nil,
            altDescription: nil,
            urls: Photo.Urls(raw: url, full: url, regular: url, small: url, thumb: url),
            user: .fixture(id: "user-\(id)")
        )
    }

    static func fixtures(count: Int) -> [Photo] {
        (1...count).map { .fixture(id: "photo-\($0)") }
    }
}

extension User {
    static func fixture(id: String) -> User {
        let url = URL(string: "https://example.com/\(id).jpg")!
        return User(
            id: id,
            username: "user-\(id)",
            name: nil,
            firstName: nil,
            lastName: nil,
            instagramUsername: nil,
            twitterUsername: nil,
            portfolioUrl: nil,
            totalCollections: 0,
            profileImage: User.ProfileImage(small: url, medium: url, large: url)
        )
    }
}

extension Topic {
    static func fixture(id: String, slug: String) -> Topic {
        Topic(
            id: id,
            slug: slug,
            title: "Title \(id)",
            description: nil,
            coverPhoto: nil
        )
    }
}

// MARK: - Thread-safe recorder

final class KeywordRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    var values: [String] {
        lock.withLock { storage }
    }

    func append(_ value: String) {
        lock.withLock { storage.append(value) }
    }
}
