import XCTest
@testable import Squirrel

final class AsyncCachingLoaderTests: XCTestCase {

    // MARK: - Lifecycle
    
    override func setUpWithError() throws {
        sut = AsyncCachingLoader(
            cache: AsyncCachingLoaderTests.cacheSpy,
            load: AsyncCachingLoaderTests.loadMockSpy
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        CacheSpy.resetCache()
        LoadSpy.resetLoad()
    }

    // MARK: - Internal
    
    // MARK: Types
    
    enum TestURLString {
        static let validURL = "https://via.placeholder.com/400x150"
        static let invalidURL = "test"
        static let badDataURL = "https://via.placeholder.com/400*150"
        static let forbiddenURL = validURL + "/forbidden"
    }
    
    // MARK: Properties
    
    var sut: AsyncCachingLoader!
    
    static let cacheSpy: (read: (URL) -> Data?, write: (Data, URL) -> Void) = {
        return (read: CacheSpy.read(url:), write: CacheSpy.write(data:at:))
    }()
    
    static let loadMockSpy: (URL) async throws -> Data = { url in
        LoadSpy.numberOfRemoteReadings += 1
        return try await Loader(load: loadMock).loadData(at: url)

    }
    
    static let loadMock: (URL) async throws -> (Data, URLResponse) = { url in
        switch url.absoluteString {
        case TestURLString.invalidURL: throw URLError(.badURL)
        case TestURLString.badDataURL: throw URLError(.cannotParseResponse)
        case TestURLString.forbiddenURL:
            return (
                Data(1...4),
                HTTPURLResponse(
                    url: url,
                    statusCode: 403,
                    httpVersion: nil,
                    headerFields: nil
                )! as URLResponse
            
            )
        default:
            return (
                Data(1...4),
                HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )! as URLResponse
            )
        }
    }
    
    // MARK: Methods
    
    func test_load_validURL_cachesAndReturnsDataFromRemote() async throws {
        // Given
        let url = URL(string: TestURLString.validURL)
        
        // When
        let result = await sut.load(from: url!)
        
        // Then
        let expectedNumberOfCacheReadings = 1
        XCTAssertEqual(
            CacheSpy.numberOfCacheReadings,
            expectedNumberOfCacheReadings,
            """
            Expected the cache to be read from once in an attempt to find data associated to the
            requested URL, but got \(CacheSpy.numberOfCacheReadings) cache readings instead.
            """
        )
        
        let expectedNumberOfCacheWritings = 1
        XCTAssertEqual(
            CacheSpy.numberOfCacheWritings,
            expectedNumberOfCacheWritings,
            """
            Expected the data fetched from the remote to be cached once, but number of cache
            writings = \(CacheSpy.numberOfCacheReadings) instead.
            """
        )
        
        switch result {
        case .success(let data):
            XCTAssertEqual(
                data,
                Data(1...4),
                "Expected to receive \(Data(1...4)) from the valid URL but got \(data) instead."
            )
        case .failure(let error):
            XCTFail(
                """
                Expected to receive data from a valid URL but got \(String(describing: error))
                instead
                """
            )
        case nil:
            XCTFail("Expected to receive a result from a valid URL but got none.")
        }
    }
    
    func test_load_validURLASecondTime_returnsDataFromCache() async throws {
        // Given
        let url = URL(string: TestURLString.validURL)
        
        // When
        _ = await sut.load(from: url!)
        let result = await sut.load(from: url!)
        
        // Then
        let expectedNumberOfCacheReadings = 2
        XCTAssertEqual(
            CacheSpy.numberOfCacheReadings,
            expectedNumberOfCacheReadings,
            """
            Expected the cache to be read from twice in an attempt to find data associated
            to the URL at each request, but got \(CacheSpy.numberOfCacheReadings) cache readings
            instead.
            """
        )
        
        let expectedNumberOfCacheWritings = 1
        XCTAssertEqual(
            CacheSpy.numberOfCacheWritings,
            expectedNumberOfCacheWritings,
            """
            Expected the data fetched from the remote to be cached once, but number of cache
            writings = \(CacheSpy.numberOfCacheReadings) instead.
            """
        )
        
        switch result {
        case .success(let data):
            XCTAssertEqual(
                data,
                Data(1...4),
                """
                Expected to receive \(Data(1...4)) from the cache for a valid URL
                but got \(data) instead.
                """
            )
        case .failure(let error):
            XCTFail(
                """
                Expected to receive data from the cache for a valid URL
                but got \(String(describing: error)) instead.
                """
            )
        case nil:
            XCTFail("Expected to receive a result from the cache for a valid URL but got none.")
        }
    }
    
    func test_load_invalidURL_doesNotCacheAndReturnsExpectedError() async throws {
        // Given
        let url = URL(string: TestURLString.invalidURL)
        
        // When
        let result = await sut.load(from: url!)
        
        // Then
        let expectedNumberOfCacheReadings = 1
        XCTAssertEqual(
            CacheSpy.numberOfCacheReadings,
            expectedNumberOfCacheReadings,
            """
            Expected the cache to be read from once in an attempt to find data associated
            to the requested URL, but got \(CacheSpy.numberOfCacheReadings) cache readings
            instead.
            """
        )
        
        let expectedNumberOfCacheWritings = 0
        XCTAssertEqual(
            CacheSpy.numberOfCacheWritings,
            expectedNumberOfCacheWritings,
            """
            Expected the invalid data fetched from the remote to not be cached, but number of cache
            writings = \(CacheSpy.numberOfCacheReadings) instead.
            """
        )
        
        switch result {
        case .success(let data):
            XCTFail(
                """
                Expected attempting to load data from an invalid URL to return no data,
                but got \(data) instead.
                """
            )
        case .failure(let error):
            if case .loadingFailed = error {
                XCTAssertTrue(true)
            } else {
                XCTFail(
                    """
                    Expected error thrown when attempting to load data from invalid URL to be
                    `.loadingFailed`, but got \(String(describing: error)) instead).
                    """
                )
            }
        case nil:
            XCTFail(
                """
                Expected to receive an `AsyncCachingLoaderError` when attempting to load data from
                and invalid URL, but got `nil` instead.
                """
            )
        }
    }
    
    func test_load_forbiddenURL_doesNotCachesAndReturnsExpectedError() async throws {
        // Given
        let url = URL(string: TestURLString.forbiddenURL)
        
        // When
        let result = await sut.load(from: url!)
        
        // Then
        let expectedNumberOfCacheReadings = 1
        XCTAssertEqual(
            CacheSpy.numberOfCacheReadings,
            expectedNumberOfCacheReadings,
            """
            Expected the cache to be read from once in an attempt to find data associated
            to the requested URL, but got \(CacheSpy.numberOfCacheReadings) cache readings
            instead.
            """
        )
        
        let expectedNumberOfCacheWritings = 0
        XCTAssertEqual(
            CacheSpy.numberOfCacheWritings,
            expectedNumberOfCacheWritings,
            """
            Expected the invalid data fetched from the remote to not be cached, but number of cache
            writings = \(CacheSpy.numberOfCacheReadings) instead.
            """
        )
        
        switch result {
        case .success(let data):
            XCTFail(
                """
                Expected attempting to load forbidden data from a URL to return no data,
                but got \(data) instead.
                """
            )
        case .failure(let error):
            if case .loadingFailed = error {
                XCTAssertTrue(true)
            } else {
                XCTFail(
                    """
                    Expected error thrown when attempting to load forbidden data from a URL to be
                    `.loadingFailed`, but got \(String(describing: error)) instead).
                    """
                )
            }
        case nil:
            XCTFail(
                """
                Expected to receive an `AsyncCachingLoaderError` when attempting to load forbidden
                data from a URL, but got `nil` instead.
                """
            )
        }
    }
}

private enum LoadSpy {
    static var numberOfRemoteReadings = 0
    
    static func resetLoad() {
        numberOfRemoteReadings = 0
    }
}

private enum CacheSpy {
    static var numberOfCacheReadings = 0
    static var numberOfCacheWritings = 0
    static var simpleCache: [URL: Data] = [:]

    static func read(url: URL) -> Data? {
        numberOfCacheReadings += 1
        return simpleCache[url]
    }
    
    static func write(data: Data, at url: URL) -> Void {
        simpleCache[url] = data
        numberOfCacheWritings += 1
    }
    
    static func resetCache() {
        numberOfCacheReadings = 0
        numberOfCacheWritings = 0
        simpleCache = [:]
    }
}
