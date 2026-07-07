import SwiftUI
import Foundation
import ComposableArchitecture

// MARK: - PhotoCell (Component displaying 1 photo in Grid)

struct PhotoCell: View {
    let photo: Photo
    let store: StoreOf<ImageFeature>

    init(photo: Photo, store: StoreOf<ImageFeature>? = nil) {
        self.photo = photo
        self.store = store ?? Store(initialState: ImageFeature.State(url: photo.urls.small)) {
            ImageFeature()
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Color(uiColor: .secondarySystemBackground)
                .aspectRatio(CGFloat(photo.width) / CGFloat(photo.height), contentMode: .fit)
                .overlay{
                    ImageView(store: store)
                }
                .clipped()
                .cornerRadius(12)
            
            Text(photo.user.name ?? photo.user.username)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }
}

#Preview {
    PhotoCell(
        photo: Photo.mock,
        store: Store(initialState: ImageFeature.State(url: Photo.mock.urls.small)) {
            ImageFeature()
        } withDependencies: {
            $0.imageClient.loadImage = { _ in UIImage(named: "samplePhoto")! }
        }
    )
    .frame(width: 180)
    .padding()
}
