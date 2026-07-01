import Foundation

// MARK: - Mock data

#if DEBUG
extension User {
    static let mock = User(
        id: "user-1",
        username: "johndoe",
        name: "John Doe",
        firstName: "John",
        lastName: "Doe",
        instagramUsername: "johndoe",
        twitterUsername: "johndoe",
        portfolioUrl: URL(string: "https://example.com"),
        totalCollections: 3,
        profileImage: .init(
            small: URL(string: "https://picsum.photos/id/64/64")!,
            medium: URL(string: "https://picsum.photos/id/64/128")!,
            large: URL(string: "https://picsum.photos/id/64/256")!
        )
    )
}

extension Photo {
    static let mock = Photo(
        id: "photo-1",
        width: 4000,
        height: 3000,
        color: "#60544D",
        description: "A beautiful landscape",
        altDescription: "Mountains at sunrise",
        urls: .init(
            raw: URL(string: "https://picsum.photos/id/10/4000/3000")!,
            full: URL(string: "https://picsum.photos/id/10/2000/1500")!,
            regular: URL(string: "https://picsum.photos/id/10/1080/810")!,
            small: URL(string: "https://picsum.photos/id/10/400/300")!,
            thumb: URL(string: "https://picsum.photos/id/10/200/150")!
        ),
        user: .mock
    )
}

extension Topic {
    static let mock = Topic(
        id: "topic-1",
        slug: "nature",
        title: "Nature",
        description: "The great outdoors, captured beautifully.",
        coverPhoto: .mock
    )
}
#endif
