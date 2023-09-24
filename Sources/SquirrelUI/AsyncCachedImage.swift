import Squirrel
import SwiftUI

// MARK: - AsyncCachedImage

/// A view that asynchronously loads and displays an image.
///
/// It is possible to specify a custom placeholder for the view to display while the image is
/// loading, using ``init(url:animation:transition:content:placeholder:)``.
/// With this initializer, you can also use the `content` parameter to manipulate the loaded image.
/// For example, you can add a modifier to make the loaded image resizable:
///
///     AsyncCachedImage(url: URL(string: "https://example.com/icon.png")) { image in
///         image
///             .resizable()
///     } placeholder: {
///         ProgressView()
///     }
///     .frame(width: 50, height: 50)
///
/// For this example, ``AsyncCachedImage`` shows a `ProgressView` first, and then the
/// image scaled to fit in the specified frame.
///
/// > Important: It isn't possible to apply image-specific modifiers, like
/// `Image/resizable(capInsets:resizingMode:)`, directly to an ``AsyncCachedImage``.
/// Instead, they must be applied to the `Image` instance that the `content`
/// closure gets when defining the view's appearance.
///
/// To gain more control over the loading process, the
/// ``init(url:animation:transition:content:)`` initializer can be used. It takes a
/// `content` closure that receives an `AsyncImagePhase` to indicate
/// the state of the loading operation. Return a view that's appropriate
/// for the current phase:
///
///     AsyncImage(url: URL(string: "https://example.com/icon.png")) { phase in
///         if let image = phase.image {
///             image // Displays the loaded image.
///         } else if phase.error != nil {
///             Color.red // Indicates an error.
///         } else {
///             Color.blue // Acts as a placeholder.
///         }
///     }
public struct AsyncCachedImage<ImageContent, PlaceholderContent>: View
    where ImageContent: View, PlaceholderContent: View
{
    // MARK: - Lifecycle
    
    // MARK: Public
    
    /// Loads and displays an image from the specified URL in phases.
    ///
    /// If you set the asynchronous image's URL to `nil`, or after you set the
    /// URL to a value but before the load operation completes, the phase is
    /// `AsyncImagePhase/empty`. After the operation completes, the phase
    /// becomes either `AsyncImagePhase/failure(_:)` or
    /// `AsyncImagePhase/success(_:)`. In the first case, the phase's
    /// `AsyncImagePhase/error` value indicates the reason for failure.
    /// In the second case, the phase's `AsyncImagePhase/image` property
    /// contains the loaded image. Use the phase to drive the output of the
    /// `content` closure, which defines the view's appearance:
    ///
    ///     AsyncImage(url: URL(string: "https://example.com/icon.png")) { phase in
    ///         if let image = phase.image {
    ///             image // Displays the loaded image.
    ///         } else if phase.error != nil {
    ///             Color.red // Indicates an error.
    ///         } else {
    ///             Color.blue // Acts as a placeholder.
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - url: The URL of the image to display.
    ///   - animation: The animation to use when the phase changes.
    ///   - transition: The transition to use when the phase changes.
    ///   - content: A closure that takes the load phase as an input, and
    ///     returns the view to display for the specified phase.
    public init(
        url: URL?,
        animation: Animation? = nil,
        transition: AnyTransition = .identity,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> ImageContent
    ) where PlaceholderContent == EmptyView {
        self.url = url
        self.animation = animation
        self.transition = transition
        self.contentForPhase = content
        
        self.contentForImage = nil
        self.placeholder = { EmptyView() }
    }
    
    /// Loads and displays an image from the specified URL using
    /// a custom placeholder until the image loads.
    ///
    /// Until the image loads, SwiftUI displays the specified placeholder view
    /// When the load operation completes successfully, SwiftUI
    /// updates the view to show the specified, created using the loaded image.
    ///
    /// If the load operation fails, SwiftUI continues to display the
    /// placeholder. To be able to display a different view on a load error,
    /// use the ``init(url:animation:transition:content:)`` initializer instead.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to display.
    ///   - animation: The animation to apply to the content.
    ///   - transition: The transition to apply when the content appears.
    ///   - content: A closure that takes the loaded image as an input, and
    ///     returns the view to show. You can return the image directly, or
    ///     modify it as needed before returning it.
    ///   - placeholder: A closure that returns the view to show until the
    ///     load operation completes successfully.
    public init(
        url: URL?,
        animation: Animation? = nil,
        transition: AnyTransition = .identity,
        @ViewBuilder content: @escaping (Image) -> ImageContent,
        @ViewBuilder placeholder: @escaping () -> PlaceholderContent
    ) {
        self.url = url
        self.animation = animation
        self.transition = transition
        self.contentForImage = content
        self.placeholder = placeholder
        
        self.contentForPhase = nil
    }
    
    // MARK: - Properties
    
    // MARK: Public
    
    @MainActor
    public var body: some View {
        ZStack {
            if let contentForPhase {
                ViewForPhase(
                    imageResult: asyncImageCachingLoader.imageLoadResult,
                    contentForPhase: contentForPhase
                )
                .transition(transition)
            } else if let contentForImage, let placeholder {
                ViewForImage(
                    imageResult: asyncImageCachingLoader.imageLoadResult,
                    content: contentForImage,
                    placeholder: placeholder
                )
                .transition(transition)
            }
        }
        .animation(animation, value: asyncImageCachingLoader.imageLoadResult)
        .task {
            guard !Task.isCancelled else { return }
            await asyncImageCachingLoader.load(from: url)
        }
    }
    
    // MARK: Private
    
    @StateObject private var asyncImageCachingLoader = AsyncImageCachingLoader()
    private let url: URL?
    private let animation: Animation?
    private let transition: AnyTransition
    private let contentForPhase: ((AsyncImagePhase) -> ImageContent)?
    private let contentForImage: ((Image) -> ImageContent)?
    private let placeholder: (() -> PlaceholderContent)?
}

struct AsyncCachedImage_Previews: PreviewProvider {
    static var previews: some View {
        AsyncCachedImage(url: URL(string: "https://via.placeholder.com/200x150")) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
            case .failure(let error):
                Text("Error \(String(describing: error))")
            @unknown default:
                EmptyView()
            }
        }
    }
}
