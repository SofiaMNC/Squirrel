import XCTest
@testable import Squirrel

final class LoaderTests: XCTestCase {

    // MARK: - Lifecycle
    
    override func setUpWithError() throws {
        sut = Loader(load: LoaderTests.loadMock)
    }
    
    override func tearDownWithError() throws {
        sut = nil
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
    
    var sut: Loader!
    
    static var loadMock: (URL) async throws -> (Data, URLResponse) = { url in
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
    
    func test_load_validURL_returnsData() async throws {
        // Given
        let url = URL(string: TestURLString.validURL)
        
        // When
        let result = try await sut.loadData(at: url!)
        
        // Then
        XCTAssertEqual(
            result,
            Data(1...4),
            "Expected to receive valid data from a valid URL but got \(result) instead."
        )
    }
    
    func test_load_invalidURL_throwsLoadError() async throws {
        // Given
        let url = URL(string: TestURLString.invalidURL)
        
        // When / Then
        do {
            _ = try await sut.loadData(at: url!)
            XCTFail(
                """
                Expected attempt to load data from invalid URL to throw an error, 
                but none was thrown.
                """
            )
        } catch {
            let thrownError = error as? Loader.LoaderError
            XCTAssertNotNil(
                thrownError,
                """
                Expected error thrown when attempting to load data from invalid URL to be of type
                `LoaderError`, but got \(error) instead).
                """
            )
            if case .loadError = thrownError {
                XCTAssertTrue(true)
            } else {
                XCTFail(
                    """
                    Expected error thrown when attempting to load data from invalid URL to be
                    `.loadError`, but got \(String(describing: thrownError)) instead).
                    """
                )
            }
        }
    }
    
    func test_load_badDataURL_throwsLoadError() async throws {
        // Given
        let url = URL(string: TestURLString.badDataURL)
        
        // When / Then
        do {
            _ = try await sut.loadData(at: url!)
            XCTFail(
                """
                Expected attempt to load data from a URL with bad data to throw an error,
                but none was thrown.
                """
            )
        } catch {
            let thrownError = error as? Loader.LoaderError
            XCTAssertNotNil(
                thrownError,
                """
                Expected error thrown when attempting to load data from a URL with bad data to be 
                of type `LoaderError`, but got \(String(describing: error)) instead).
                """
            )
            if case .loadError = thrownError {
                XCTAssertTrue(true)
            } else {
                XCTFail(
                    """
                    Expected error thrown when attmepting to load data from a URL with bad data to
                    be of type `.loadError`, but got \(String(describing: thrownError)) instead).
                    """
                )
            }
        }
    }
    
    func test_load_forbiddenURL_throwsInvalidResponse() async throws {
        // Given
        let url = URL(string: TestURLString.forbiddenURL)
        
        // When / Then
        do {
            _ = try await sut.loadData(at: url!)
            XCTFail(
                """
                Expected attempt to load forbidden data from a URL to throw an error,
                but none was thrown.
                """
            )
        } catch {
            let thrownError = error as? Loader.LoaderError
            XCTAssertNotNil(
                thrownError,
                """
                Expected error thrown when attempting to load forbidden data from a URL to be of
                type `LoaderError`, but got \(error) instead).
                """
            )
            if case .invalidResponse(let httpStatusCode) = thrownError {
                XCTAssertEqual(
                    httpStatusCode, 
                    403,
                    """
                    Expected `LoaderError.invalidResponse` error thrown when attempting to load
                    forbidden data from a URL to contain status code = 403,
                    but got \(httpStatusCode) instead.
                    """
                )
            } else {
                XCTFail(
                    """
                    Expected error thrown when attempting to load forbidden data from a URL to
                    be `.invalidResponse`, but got \(String(describing: thrownError)) instead).
                    """
                )
            }
        }
    }
}
