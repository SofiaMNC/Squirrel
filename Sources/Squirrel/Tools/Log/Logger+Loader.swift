import OSLog

// MARK: - Logger + Loader

extension Logger {
    static let loader = Logger(subsystem: squirrelPackage, category: "loader")
}

// MARK: - Logger + Loader + LoggableEvent

extension Loader {
    enum LoggableEvent {
        case attemptingFetchingFromRemote(url: URL)
        case failureFetchingFromRemote(url: URL, error: Loader.LoaderError)
        case invalidResponseFetchingFromRemote(url: URL, statusCode: Int)
        case successFetchingFromRemote(url: URL)
        
        var logger: Logger {
            Logger.loader
        }
    }
}

// MARK: - Logger + ImageHandler + log(_:)

extension Loader {
    static func log(_ event: Loader.LoggableEvent) {
        #if DEBUG
        switch event {
        case .attemptingFetchingFromRemote(let url):
            event.logger.info(
                "Attempting to fetch data with absolute url \(url.absoluteString) from the remote"
            )
        case .failureFetchingFromRemote(let url, let error):
            event.logger.fault(
                "Failed to fetch data with absolute url \(url.absoluteString) from the remote with error \(String(describing: error))"
            )
        case .invalidResponseFetchingFromRemote(let url, let statusCode):
            event.logger.error(
                "Received invalid response with status code = \(statusCode) from remote at \(url.absoluteString)"
            )
        case .successFetchingFromRemote(let url):
            event.logger.info(
                "Data with absolute url \(url.absoluteString) successfully fetched from the remote"
            )
        }
        #endif
    }
}
