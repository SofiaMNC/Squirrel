import Foundation

// MARK: - Loader

/// The `Loader` provides an interface to load data from a remote URL.
/// By default, it uses the shared `URLSession` instance to load data from the specified URL.
/// This loading mechanism can be fully customized by injecting a loading closure.
struct Loader {
    
    // MARK: - Lifecycle
    
    init(
        load: @escaping ((URL) async throws -> (Data, URLResponse)) = URLSession.shared.data(from:)
    ) {
        self.load = load
    }
      
    // MARK: - Internal
    
    /// Loads the data at the specified url.
    /// - Parameter url: the url to load
    /// - Returns the data if any valid data received, throws an error otherwise
    func loadData(at url: URL) async throws -> Data {
        let (data, response) = try await loadData(at: url, with: load)
        
        guard response.isValid else {
            let httpStatusCode = response.httpStatusCode
            let loaderError: LoaderError = .invalidResponse(httpStatusCode: httpStatusCode)
            Loader.log(.invalidResponseFetchingFromRemote(url: url, statusCode: httpStatusCode))
            throw loaderError
        }
        
        return data
    }
    
    // MARK: - Private
    
    private let load: (URL) async throws -> (Data, URLResponse)

    private func loadData(
        at url: URL,
        with load: (URL) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse) {
        do {
            Loader.log(.attemptingFetchingFromRemote(url: url))
            let (data, response) = try await load(url)
            Loader.log(.successFetchingFromRemote(url: url))
            return (data, response)
        } catch {
            let loaderError: LoaderError = .loadError(error: error)
            Loader.log(.failureFetchingFromRemote(url: url, error: loaderError))
            throw loaderError
        }
    }
}

// MARK: - Loader.LoaderError

extension Loader {
    enum LoaderError: Error {
        case loadError(error: Error)
        case invalidResponse(httpStatusCode: Int)
    }
}
          
// MARK: - Loader.LoaderError + CustomDebugStringConvertible

extension Loader.LoaderError: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .loadError(let error):
            return "Internal Error - \(String(describing: error))"
        case .invalidResponse(let httpStatusCode):
            return "Invalid response - HTTP code = \(httpStatusCode)"
        }
    }
}

// MARK: - Loader.LoaderError + Equatable

extension Loader.LoaderError: Equatable {
    static func == (lhs: Loader.LoaderError, rhs: Loader.LoaderError) -> Bool {
        switch (lhs, rhs) {
        case (.loadError(_), .loadError(_)):
            return lhs.debugDescription == rhs.debugDescription
        case (.invalidResponse(_), .invalidResponse(_)):
            return  lhs.debugDescription == rhs.debugDescription
        default: return false
        }
    }
}

// MARK: - URLResponse + httpStatusCode + isValid

private extension URLResponse {
    var httpStatusCode: Int {
        (self as? HTTPURLResponse)?.statusCode ?? -1
    }
    
    var isValid: Bool {
        200...299 ~= httpStatusCode
    }
}
