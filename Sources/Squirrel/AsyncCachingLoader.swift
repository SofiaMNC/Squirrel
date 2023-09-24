import SwiftUI

// MARK: - AsyncCachingLoader

/// An asynchronous data loader with cache.
///
/// The loader attempts to fetch the requested data from its in-memory cache.
/// If no data is cached for that URL, the loader uses the shared `URLSession`
/// instance to load data from the specified URL.
/// If it receives any data, it stores it in its in-memory cache.
final class AsyncCachingLoader {
    
    // MARK: - Lifecycle
            
    init(
        cache: (read: (URL) -> Data?, write: (Data, URL) -> Void)? = nil,
        load: ((URL) async throws -> Data)? = nil
    ) {
        if let cache {
            self.cache = cache
        } else {
            let cache = Cache<URL, Data>()
            self.cache = (read: cache.value(for:), write: cache.insert(_:for:))
        }
        self.load = load ?? Loader().loadData(at:)
    }
    
    // MARK: - Internal
        
    @MainActor
    func load(from url: URL) async -> Result<Data, AsyncCachingLoaderError>? {
        guard let objectData = fetchFromCache(for: url) else {
            return await fetchRemotely(at: url)
        }
        
        return .success(objectData)
    }
    
    // MARK: - Private
        
    private var cache: (read: (URL) -> Data?, write: (Data, URL) -> Void)
    private let load: (URL) async throws -> Data
    
    private func fetchFromCache(for url: URL) -> Data? {
        cache.read(url)
    }
    
    private func storeInCache(_ data: Data, for url: URL) {
        cache.write(data, url)
    }
    
    private func fetchRemotely(at url: URL) async -> Result<Data, AsyncCachingLoaderError>? {
        do {
            let data = try await load(url)
            storeInCache(data, for: url)
            return .success(data)
        } catch {
            return .failure(.loadingFailed(description: error.localizedDescription))
        }
    }
}

// MARK: - AsyncCachingLoader.AsyncCachingLoaderError

extension AsyncCachingLoader {
    enum AsyncCachingLoaderError: Error {
        case loadingFailed(description: String)
    }
}

// MARK: - AsyncCachingLoader.AsyncCachingLoaderError + Equatable

extension AsyncCachingLoader.AsyncCachingLoaderError: Equatable {
    static func == (
        lhs: AsyncCachingLoader.AsyncCachingLoaderError,
        rhs: AsyncCachingLoader.AsyncCachingLoaderError
    ) -> Bool {
        switch (lhs, rhs) {
        case (.loadingFailed(let description1), .loadingFailed(let description2)):
            return description1 == description2
        }
    }
}


