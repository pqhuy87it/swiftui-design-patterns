import SwiftUI
import ComposableArchitecture

struct ImageView: View {
    let store: StoreOf<ImageFeature>
    
    var body: some View {
        Group {
            if store.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let image = store.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.gray.opacity(0.3)
                    Image(systemName: "photo.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            store.send(.loadImage)
        }
    }
}

// MARK: - Preview

#Preview {
    ImageView(
        store: Store(initialState: ImageFeature.State(
            url: URL(string: "https://images.unsplash.com/photo-1490750967868-88aa4486c946")!
        )) {
            ImageFeature()
        } withDependencies: {
            $0.imageClient.loadImage = { _ in UIImage(systemName: "star.fill")! }
        }
    )
    .frame(width: 200, height: 200)
    .cornerRadius(12)
}
