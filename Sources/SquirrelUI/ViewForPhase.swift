import Squirrel
import SwiftUI

// MARK: - ViewForPhase

struct ViewForPhase<Content: View>: View {
    var imageResult: Result<PlatformImage, AsyncImageCachingLoader.AsyncImageCachingLoaderError>?
    @ViewBuilder let contentForPhase: (AsyncImagePhase) -> Content

    var body: some View {
        switch imageResult {
        case .success(let platformImage):
            contentForPhase(.success(makeImage(from: platformImage)))
        case .failure(let error):
            contentForPhase(.failure(error))
        case .none:
            contentForPhase(.empty)
        }
    }
}

struct ViewForPhase_Previews: PreviewProvider {
    static var previews: some View {
        #if canImport(UIKit)
        ViewForPhase(imageResult: .success(UIImage())) { phase in
            if case let .success(image) = phase {
                image
            } else {
                ProgressView()
            }
        }
        #endif
    }
}
