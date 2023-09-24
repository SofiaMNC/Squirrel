import Squirrel
import SwiftUI

struct SquirrelTab: View {
    let imageURLs: [String] = Model.imageURLs
    
    @State var urlAndImages: [(stringURl: String, image: PlatformImage)] = []
    
    var body: some View {
        VStack {
            Text("Squirrel")
                .font(.title)
                .bold()
                .foregroundColor(.teal)
            ScrollView {
                ForEach(urlAndImages, id: \.stringURl) { (url, image) in
                    makeImage(from: image)
                        .clipShape(Capsule())
                }
                .padding(.top, 10)
            }
            .background(.teal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            guard !Task.isCancelled else { return }
            
            urlAndImages = await withTaskGroup(
                of: Result<PlatformImage, AsyncImageCachingLoader.AsyncImageCachingLoaderError>?.self,
                returning: [(String, PlatformImage)].self
            ) { taskGroup in
                for imageURL in imageURLs {
                    taskGroup.addTask {
                        await asyncImageCachingLoader.load(from: URL(string: imageURL))
                    }
                }
                
                var images: [PlatformImage] = []
                for await result in taskGroup {
                    if case let .success(platformImage) = result {
                        images.append(platformImage)
                    }
                }
                
                return Array(zip(imageURLs, images))
            }
        }
    }
    
    @StateObject private var asyncImageCachingLoader = AsyncImageCachingLoader()
}

#Preview {
    SquirrelTab()
}
