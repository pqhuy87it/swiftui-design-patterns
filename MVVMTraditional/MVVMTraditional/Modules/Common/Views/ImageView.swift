import SwiftUI

struct ImageView: View {
    @StateObject private var viewModel: ImageViewModel

    init(viewModel: @autoclosure @escaping () -> ImageViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    init(url: URL) {
        self.init(viewModel: ImageViewModel(imageURL: url,
                                            imagesService: ImagesService()))
    }

    var body: some View {
        content
            .task {
                await viewModel.loadImage()
            }
    }

    @ViewBuilder private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        } else if let image = viewModel.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if viewModel.hasError {
            Text("Unable to load image")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        } else {
            Color.clear
        }
    }
}
