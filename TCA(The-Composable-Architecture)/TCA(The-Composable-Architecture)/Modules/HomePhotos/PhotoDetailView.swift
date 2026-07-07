import SwiftUI
import ComposableArchitecture

struct PhotoDetailView: View {

    let photo: Photo
    let store: StoreOf<ImageFeature>

    init(photo: Photo, store: StoreOf<ImageFeature>? = nil) {
        self.photo = photo
        self.store = store ?? Store(initialState: ImageFeature.State(url: photo.urls.small)) {
            ImageFeature()
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ImageView(store: store)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(16)
                .shadow(radius: 5)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Display author
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                        Text(photo.user.name ?? "")
                            .font(.headline)
                    }
                    
                    // Display photo description (if any)
                    if let description = photo.description ?? photo.altDescription {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Original photo size
                    Text("Original size: \(photo.width) x \(photo.height)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Photo Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PhotoDetailView(
            photo: Photo.mock,
            store: Store(initialState: ImageFeature.State(url: Photo.mock.urls.small)) {
                ImageFeature()
            } withDependencies: {
                $0.imageClient.loadImage = { _ in UIImage(named: "samplePhoto")! }
            }
        )
    }
}
