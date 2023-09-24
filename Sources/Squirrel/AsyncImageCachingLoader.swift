import SwiftUI

// MARK: - AsyncImageCachingLoader

/// An asynchronous image loader with cache.
///
/// ``AsyncImageCachingLoader`` starts by attempting to fetch the requested data from its cache.
/// By default, it uses an in-memory LRU cache but it is possible to specify a different caching
/// mechanism.
///
/// If no data is cached for that specified URL, the loader will attempt to fetch it from the
/// remote.
/// By default, ``AsyncImageCachingLoader`` uses the shared `URLSession` instance to load data from
/// the specified URL, but it is possible to specify a different data loading mechanism.
///
/// If any data is received, it is stored it the cache for later retrieval.
/// It is then used to create a ``PlatformImage``.
///
/// The image loader publishes an ``imageLoadResult`` result property, containing either:
/// - the platform image created from the retrieved data
/// - an error if no data could be retrieved for the specified URL, or if no ``PlatformImage``
/// could be created from the retrieved data.
public class AsyncImageCachingLoader: ObservableObject {
    
    @Published public var imageLoadResult: Result<PlatformImage, AsyncImageCachingLoaderError>?

    // MARK: - Lifecycle
    
    /// Create an ``AsyncImageCachingLoader`` with the specified caching and loading mechanisms.
    /// - Parameters:
    ///     - cache: The caching mechanism to use. If none is provided, a default in-memory
    ///     cache is used.
    ///     - load: The data loading mechanism to use. If none is provided, a default mechanim
    ///     using the shared `URLSession` instance is used.
    public init(
        cache: (read: (URL) -> Data?, write: (Data, URL) -> Void)? = nil,
        load: ((URL) async throws -> Data)? = nil
    ) {
        self.asyncCachingLoader = AsyncCachingLoader(
            cache: cache,
            load: load
        )
    }
    
    // MARK: - Public
    
    /// Attempts to load image data from a `URL` and create a ``PlatformImage`` from it.
    /// - Parameter url: the URL of the image to load.
    /// - Returns a ``PlatformImage`` created using the data retrieved for the specified url, or an error.
    @discardableResult @MainActor
    public func load(from url: URL?) async -> Result<PlatformImage, AsyncImageCachingLoaderError>? {
        guard let url else {
            imageLoadResult = .failure(.emptyURL)
            return imageLoadResult
        }
        
        switch await asyncCachingLoader.load(from: url) {
        case .success(let data):
            imageLoadResult = makeImage(from: data)
        case .failure(let error):
            imageLoadResult = .failure(.loadingFailed(description: error.localizedDescription))
        case .none:
            imageLoadResult = .failure(.emptyURL)
        }
        
        return imageLoadResult
    }
    
    // MARK: - Private
    
    private let asyncCachingLoader: AsyncCachingLoader
    
    private func makeImage(from data: Data) -> Result<PlatformImage, AsyncImageCachingLoaderError> {
        guard let platformImage = makePlatformImage(data: data) else {
            return .failure(.invalidData(data: data))
        }
        return .success(platformImage)
    }
}

// MARK: - AsyncImageCachingLoader.AsyncImageCachingLoaderError

extension AsyncImageCachingLoader {
    public enum AsyncImageCachingLoaderError: Error {
        /// The specified `URL` was `nil`.
        case emptyURL
        /// The fetched data was invalid. No `PlatformImage` could be created from it.
        case invalidData(data: Data)
        /// The loading request failed.
        case loadingFailed(description: String)
    }
}

// MARK: - AsyncImageCachingLoader.AsyncImageCachingLoaderError + Equatable

extension AsyncImageCachingLoader.AsyncImageCachingLoaderError: Equatable {
    public static func == (lhs: AsyncImageCachingLoader.AsyncImageCachingLoaderError, rhs: AsyncImageCachingLoader.AsyncImageCachingLoaderError) -> Bool {
        switch (lhs, rhs) {
        case (.emptyURL, .emptyURL): return true
        case (.invalidData(let data1), .invalidData(let data2)): return data1 == data2
        case (.loadingFailed(let description1), .loadingFailed(let description2)): return description1 == description2
        default: return false
        }
    }
}
