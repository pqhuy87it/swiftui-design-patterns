import SwiftUI
import ComposableArchitecture

struct TopicHorizontalRow: View {
    let store: StoreOf<TopicRowFeature>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.topic.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            if store.isLoading {
                ProgressView().frame(maxWidth: .infinity, minHeight: 260)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(store.photos) { photo in
                            Button {
                                store.send(.photoTapped(photo))
                            } label: {
                                TopicCardView(photo: photo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}
