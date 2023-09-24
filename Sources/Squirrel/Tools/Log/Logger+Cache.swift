import OSLog

// MARK: - Logger + Cache

extension Logger {
    static let cache = Logger(subsystem: squirrelPackage, category: "cache")
}

// MARK: - Logger + Cache + LoggableEvent

extension Cache where Key: Hashable {
    enum LoggableEvent {
        case attemptingReadingFromCache(key: Key)
        case failureReadingFromCache(key: Key)
        case readStaleDataFromCache(key: Key)
        case removedLeastRecentlyUsedValue(key: Key)
        case removedStaleValueFromCache(key: Key)
        case removedAllEntriesFromCache
        case removedAllStaleEntriesFromCache
        case successReadingFromCache(key: Key)
        case updatedValueInCache(key: Key)
        case valueStoredInCache(key: Key)
        
        var logger: Logger {
            Logger.cache
        }
    }
}

// MARK: - Logger + Cache + log(_:)

extension Cache where Key: Hashable {
    static func log(_ event: Cache.LoggableEvent) {
        #if DEBUG
        switch event {
        case .attemptingReadingFromCache(let key):
            event.logger.info(
                "Attempting to read value with key \(String(describing: key)) from cache"
            )
        case .failureReadingFromCache(let key):
            event.logger.warning(
                "Cache contained no value for key \(String(describing: key))"
            )
        case .readStaleDataFromCache(let key):
            event.logger.warning(
                "Cache contained stale data for key \(String(describing: key))"
            )
        case .removedLeastRecentlyUsedValue(let key):
            event.logger.info(
                "Removed least recently used value for \(String(describing: key))"
            )
        case .removedStaleValueFromCache(let key):
            event.logger.info(
                "Removed stale value from cache for key \(String(describing: key))"
            )
        case .removedAllEntriesFromCache:
            event.logger.info(
                "Removed all entries from cache"
            )
        case .removedAllStaleEntriesFromCache:
            event.logger.info(
                "Removed all stale entries from cache"
            )
        case .successReadingFromCache(let key):
            event.logger.info(
                "Data with key \(String(describing: key)) successfully fetched from cache"
            )
        case .updatedValueInCache(let key):
            event.logger.info(
                "Updated value in cache for key \(String(describing: key))"
            )
        case .valueStoredInCache(let key):
            event.logger.info(
                "Data with key \(String(describing: key)) stored in cache"
            )
        }
        #endif
    }
}
