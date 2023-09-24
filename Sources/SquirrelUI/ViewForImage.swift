import Squirrel
import SwiftUI

// MARK: - ViewForImage

struct ViewForImage<Content, PlaceholderContent>: View where Content: View, PlaceholderContent: View {
    var imageResult: Result<PlatformImage, AsyncImageCachingLoader.AsyncImageCachingLoaderError>?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> PlaceholderContent
    
    var body: some View {
        if case let .success(platformImage) = imageResult {
        content(makeImage(from: platformImage))
        } else {
            placeholder()
        }
    }
}

struct ViewForImage_Previews: PreviewProvider {
    static var previews: some View {
        #if canImport(UIKit)
        ViewForImage(
            imageResult: .success(UIImage()),
            content: { image in
                image
            },
            placeholder: {
                ProgressView()
            }
        )
        #endif
    }
}
