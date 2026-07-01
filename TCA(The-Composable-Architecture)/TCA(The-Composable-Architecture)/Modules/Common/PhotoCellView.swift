import SwiftUI
import Foundation
import ComposableArchitecture

// MARK: - PhotoCell (Component displaying 1 photo in Grid)

struct PhotoCell: View {
    let photo: Photo
    
    var body: some View {
        VStack(alignment: .leading) {
            Color(uiColor: .secondarySystemBackground)
                .aspectRatio(CGFloat(photo.width) / CGFloat(photo.height), contentMode: .fit)
                .overlay{
                    ImageView(
                        store: Store(initialState: ImageFeature.State(url: photo.urls.small)) {
                            ImageFeature()
                        }
                    )
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
    PhotoCell(photo: Photo.mock)
        .frame(width: 180) // Limit width for preview
        .padding()
}
