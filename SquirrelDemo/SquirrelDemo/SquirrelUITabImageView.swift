import SquirrelUI
import SwiftUI

struct SquirrelUITabImageView: View {
    let imageURLs: [String] = Model.imageURLs
    
    var body: some View {
        VStack {
            Text("Squirrel UI - Placeholder")
                .font(.title)
                .bold()
                .foregroundColor(.teal)
            ScrollView {
                ForEach(imageURLs, id: \.self) { imageURL in
                    AsyncCachedImage(
                        url: URL(string: imageURL),
                        content: { image in
                            image
                                .clipShape(Capsule())
                        },
                        placeholder: {
                            ProgressView()
                        }
                    )
                }
                .padding(.top, 10)
            }
            .background(.teal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    SquirrelUITabImageView()
}
