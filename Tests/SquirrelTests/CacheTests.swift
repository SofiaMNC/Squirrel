import XCTest
@testable import Squirrel

final class SquirrelTests: XCTestCase {
    
    // MARK: - Lifecycle
    
    override func setUpWithError() throws {
        sut = Cache(entryLifetime: SquirrelTests.entryLifetime)
    }
    
    override func tearDownWithError() throws {
        sut = nil
    }
    
    // MARK: - Internal
    
    // MARK: Properties
    
    static let entryLifetime: TimeInterval = 1
    var sut: Cache<Int, String>!
    
    // MARK: Methods
    
    func test_insert_valueForKey_valueIsInsertedAtKey() throws {
        // Given
        let key = 1
        let value = "Value1"

        // When
        sut.insert(value, for: key)
        
        // Then
        let readValue = try XCTUnwrap(
            sut.value(for: key),
            "Expected value for \(key) to be stored in the cache, but it wasn't."
        )
        
        XCTAssertEqual(
            readValue,
            value,
            "Expected value read at \(key) to be \(value), but got \(readValue) instead."
        )
    }
    
    func test_insert_newValueForExistingKey_valueIsUpdated() throws {
        // Given
        let key = 1
        let value1 = "Value1"
        let value2 = "Value2"
        
        // When
        sut.insert(value1, for: key)
        sut.insert(value2, for: key)
        
        // Then
        let cachedValue = sut.value(for: key)
        XCTAssertEqual(
            cachedValue,
            value2,
            """
            Expected value for \(key) to be \(value2), but got
            \(String(describing: cachedValue)) instead.
            """
        )
    }
    
    func test_valueForKey_noValueAtKey_noValueIsRead() throws {
        // Given
        let invalidKey = 1
        
        // When
        let value = sut.value(for: invalidKey)
        
        // Then
        XCTAssertNil(
            value,
            """
            Expected no value to be read for key \(invalidKey) as no value was cached for this key,
            but got \(value!) instead.
            """
        )
    }
    
    func test_valueForKey_valueIsStale_noValueIsRead() throws {
        // Given
        let key = 1
        let value = "Value1"
        
        // When
        sut.insert(value, for: key)
        
        // Then
        let expectation = XCTestExpectation(description: "Cached data is stale")
        DispatchQueue.main.asyncAfter(deadline: .now() + SquirrelTests.entryLifetime) {
            // Data is now stale
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        
        XCTAssertNil(
            sut.value(for: key),
            """
            Expected no value to be read for \(key) as the value cached for this key is now stale,
            but stale data was returned instead.
            """
        )
    }
    
    func test_insert_cacheIsFull_removesLeastRecentlyUsedDataAndInsertNewData() throws {
        // Given
        for i in 0...99 {
            sut.insert("\(i)", for: i)
        }
        
        // When
        let key = 100
        let value = "\(key)"
        sut.insert(value, for: key)
        
        // Then
        XCTAssertNil(
            sut.value(for: 0),
            """
            Expected least recently used data to have been cleared from cache to make room for the
            new entry, but it wasn't.
            """
        )
        
        let readValue = try XCTUnwrap(
            sut.value(for: key),
            """
            Expected value \(value) for \(key) to be stored in the cache, but got nil instead.
            """
        )
        XCTAssertEqual(
            readValue,
            value,
            "Expected the value read at \(key) to be \(value), but got \(readValue) instead."
        )
    }
    
    func test_purgeAllStaleEntries() throws {
        // Given
        for i in 0...5 {
            sut.insert("\(i)", for: i)
        }
        
        let expectation = XCTestExpectation(description: "All cached data is stale")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // All cached data is now stale
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        
        // When
        sut.reset()

        let key = 6
        let value = "Value6"
        sut.insert(value, for: key)
        
        // Then
        for i in 0...5 {
            XCTAssertNil(
                sut.value(for: i),
                "Expected the cache to be empty of stale date, but read a value for key \(i) instead."
            )
        }
        
        XCTAssertEqual(sut.value(for: key), value)
    }
    
    func test_reset_cacheIsEmpty() throws {
        // Given
        for i in 0...5 {
            sut.insert("\(i)", for: i)
        }
        
        // When
        sut.reset(staleOnly: false)
        
        // Then
        for i in 0...5 {
            XCTAssertNil(
                sut.value(for: i),
                "Expected the cache to be empty, but read a value for key \(i) instead."
            )
        }
    }
}
