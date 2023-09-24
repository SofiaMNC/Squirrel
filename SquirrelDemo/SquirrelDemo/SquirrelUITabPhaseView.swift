import SquirrelUI
import SwiftUI

struct SquirrelUITabPhaseView: View {
    let imageURLs: [String] = Model.imageURLs
    
    var body: some View {
        VStack {
            Text("Squirrel UI - Phase")
                .font(.title)
                .bold()
                .foregroundColor(.teal)
            ScrollView {
                ForEach(imageURLs, id: \.self) { imageURL in
                    AsyncCachedImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            Text("No image value")
                        case .success(let image):
                            image
                                .clipShape(Capsule())
                        case .failure(let error):
                            Text("Failed to get image - \(String(describing: error))")
                        @unknown default:
                            Text("No image value")
                        }
                    }
                }
                .padding(.top, 10)
            }
            .background(.teal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    SquirrelUITabPhaseView()
}
