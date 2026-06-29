import SwiftUI
import Combine

struct PhotoCell: View {
    let photo: Photo
    
    @Environment(\.viewModelFactory) var factory
    
    var body: some View {
        VStack(alignment: .leading) {
            Color(uiColor: .secondarySystemBackground)
                .aspectRatio(CGFloat(photo.width) / CGFloat(photo.height), contentMode: .fit)
                .overlay {
                    ImageView(
                        imageURL: photo.urls.small,
                        viewModel: factory.makeImageViewModel()
                    )
                }
                .clipped()
                .cornerRadius(12)

            Text(photo.user.name)
                .font(.caption)
        }
    }
}
