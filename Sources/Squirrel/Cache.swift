import Foundation

// MARK: - Cache

/// An in-memory LRU cache using `NSCache` with purging of stale data.
///
/// When attempting to cache an entry, if the number of cached item has reached the specified
/// count limit, the cache will remove the least used item from the cache before inserting the
/// new entry.
/// When reading an entry, if it has become stale, the cache will discard it and return no data.
/// By default, an entry is considered stale if it was last accessed more than 12 hours ago, but
/// this value can be customized using the `entryLifetime` parameter.
/// It is also possible to purge the cache of all its stale data, or to purge it entirely.
final class Cache<Key: Hashable, Value> {
    
    // MARK: - Lifecycle
    
    /// Instantiates the cache.
    /// - Parameter entryLifetime: The lifetime of an entry calculated from its last accessed date.
    init(entryLifetime: TimeInterval = 12 * 60 * 60) {
        self.entryLifetime = entryLifetime
    }
    
    // MARK: - Internal
        
    /// Inserts the specified key - value pair in the cache.
    /// - Parameters:
    ///     - value: the value
    ///     - key: the key
    func insert(_ value: Value, for key: Key) {
        let entry = Entry(
            value: value,
            expirationDate: Date().addingTimeInterval(entryLifetime)
        )
        
        writeToCache(entry: entry, at: key)
    }
    
    /// Attempts to read the value at the specified key.
    /// - Parameter key: the key
    /// - Returns the value if there was one associated to this key in the cache and 
    /// it wasn't stale,`nil` otherwise.
    func value(for key: Key) -> Value? {
        guard let entry = readFromCache(at: key) else {
            return nil
        }
        
        /// The value at key was read. Its expiration date must be updated.
        updateExpirationDate(for: entry, at: key)
        
        return entry.value
    }
    
    /// Remove all stale entries from the cache, or empties the cache completely
    /// - Parameter staleOnly: Set to false to empty the cache completely. True by default.
    func reset(staleOnly: Bool = true) {
        if staleOnly {
            purgeStaleEntries()
        } else {
            removeAllEntries()
        }
    }
    
    // MARK: - Private
    
    // MARK: Properties
        
    /// The internal `NSCache` with a count limit of 100
    /// and a `totalCostLimit` of 50 MB.
    private let wrapped = {
        let cache = NSCache<WrappedKey, Entry>()
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        return cache
    }()
    
    /// A timer interval to specify the delay after which an entry is considered stale.
    /// Default is 12 hours.
    private let entryLifetime: TimeInterval
    /// An array to keep track of the keys so we can delete the oldest
    /// values from the cache when needed.
    private var storedKeys: [Key] = []
    
    // MARK: Methods
    
    private func readFromCache(at key: Key) -> Entry? {
        Cache.log(.attemptingReadingFromCache(key: key))
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else {
            Cache.log(.failureReadingFromCache(key: key))
            return nil
        }
        
        guard !entry.isExpired else {
            Cache.log(.readStaleDataFromCache(key: key))
            removeStaleValue(at: key)
            return nil
        }
        
        Cache.log(.successReadingFromCache(key: key))
        return entry
    }
    
    private func writeToCache(entry: Entry, at key: Key) {
        if storedKeys.count >= wrapped.countLimit { removeLeastRecentlyUsedValue() }
        
        wrapped.setObject(entry, forKey: WrappedKey(key))
        if let existingKeyIndex = storedKeys.firstIndex(of: key) {
            storedKeys.remove(at: existingKeyIndex)
        }
        storedKeys.append(key)
        Cache.log(.valueStoredInCache(key: key))
    }
    
    private func updateExpirationDate(for entry: Entry, at key: Key) {
        /// Simply inserting the value anew will remove the existing one
        /// and insert the new one with the updated expiration date.
        insert(entry.value, for: key)
        Cache.log(.updatedValueInCache(key: key))
    }
    
    private func removeLeastRecentlyUsedValue() {
        guard !storedKeys.isEmpty else { return }
        let leastRecentlyUsedValueKey = storedKeys.removeFirst()
        removeValue(for: leastRecentlyUsedValueKey)
        Cache.log(.removedLeastRecentlyUsedValue(key: leastRecentlyUsedValueKey))
    }
    
    private func removeStaleValue(at key: Key) {
        removeValue(for: key)
        Cache.log(.removedStaleValueFromCache(key: key))
    }
    
    private func removeValue(for key: Key) {
        wrapped.removeObject(forKey: WrappedKey(key))
        if let firstIndex = storedKeys.firstIndex(of: key) {
            storedKeys.remove(at: firstIndex)
        }
    }
    
    private func removeAllEntries() {
        wrapped.removeAllObjects()
        Cache.log(.removedAllEntriesFromCache)
    }
    
    private func purgeStaleEntries() {
        let keysToStaleEntries = storedKeys.compactMap { storedKey in
            if let entry = readFromCache(at: storedKey), entry.isExpired {
                storedKey
            } else {
               nil
            }
        }
        
        for keyToRemove in keysToStaleEntries {
            removeStaleValue(at: keyToRemove)
        }
        
        Cache.log(.removedAllEntriesFromCache)
    }
}

// MARK: - Cache + WrappedKey

private extension Cache {
    final class WrappedKey: NSObject {
        init(_ key: Key) {
            self.key = key
        }

        let key: Key
        
        override var hash: Int {
            key.hashValue
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let  value = object as? WrappedKey else {
                return false
            }
            return value.key == key
        }
    }
}

// MARK: - Cache + Entry

private extension Cache {
    final class Entry {
        init(value: Value, expirationDate: Date) {
            self.value = value
            self.expirationDate = expirationDate
        }
        
        let value: Value
        private let expirationDate: Date
        var isExpired: Bool {
            Date() > expirationDate
        }
    }
}

