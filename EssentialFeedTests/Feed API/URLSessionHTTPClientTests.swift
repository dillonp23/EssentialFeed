//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/13/22.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    struct UnexpectedRepresentationError: Error {}
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(UnexpectedRepresentationError()))
            }
        }.resume()
    }
}


class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    /// If we invoke the `get(from:)` method with a url, then we expect a request
    /// to be executed with the correct url and HTTPMethod.
    ///
    /// This test allows us to determine if there is an issue with the url itself, or if there
    /// is an issue somewhere else (such as with the request or SUT).
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(url, request.url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let requestError = anyNSError()
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)
        XCTAssertEqual(requestError, receivedError)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        let urlResponse = nonHTTPURLResponse()
        let httpURLResponse = anyHTTPURLResponse()
        let anyData = anyData()
        let anyNSError = anyNSError()
        
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: urlResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: urlResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: httpURLResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: urlResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: httpURLResponse, error: anyNSError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: urlResponse, error: nil))
    }
    
    func test_getFromURL_suceedsOnHTTPURLResponseWithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        URLProtocolStub.stub(data: data, response: response, error: nil)
        let exp = expectation(description: "wait for completion")
        
        makeSUT().get(from: anyURL()) { result in
            switch result {
                case .success(let receivedData, let receivedResponse):
                    XCTAssertEqual(data, receivedData)
                    XCTAssertEqual(response.url, receivedResponse.url)
                    XCTAssertEqual(response.statusCode, receivedResponse.statusCode)
                default:
                    XCTFail("Expected success, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    /// An HTTPResponse with nil data is a valid representation case (e.g. 204 status code) that can
    /// occur in production. When we receive an HTTPResponse with nil data, the compiler replaces the
    /// nil value with a new instance of `Data` having 0 bytes (i.e. empty data).
    ///
    /// We originally made the assumption that this was an invalid representation case and included it in
    /// the `test_getFromURL_failsOnAllInvalidRepresentationCases()` method. Since
    /// this is a valid scenario, it needs to be tested as a success case that completes with empty data.
    func test_getFromURL_suceedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let httpURLResponse = anyHTTPURLResponse()
        URLProtocolStub.stub(data: nil, response: httpURLResponse, error: nil)
        
        let exp = expectation(description: "wait for completion")
        
        makeSUT().get(from: anyURL()) { result in
            switch result {
                case .success(let receivedData, let receivedResponse):
                    let emptyData = Data()
                    XCTAssertEqual(emptyData, receivedData)
                    XCTAssertEqual(httpURLResponse.url, receivedResponse.url)
                    XCTAssertEqual(httpURLResponse.statusCode, receivedResponse.statusCode)
                default:
                    XCTFail("Expected success, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}


// MARK: - SUT & Test Helpers
extension URLSessionHTTPClientTests {
    // TODO: Change once we implement `HTTPClient` protocol
    // private func makeSUT() -> HTTPClient
    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        assertNoMemoryLeaks(sut, objectName: "SUT", file: file, line: line)
        return sut
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?,
                                file: StaticString = #filePath, line: UInt = #line) -> NSError? {
        
        URLProtocolStub.stub(data: data, response: response,  error: error)
        let sut = makeSUT(file: file, line: line)
        var receivedError: NSError?
        
        let exp = expectation(description: "Wait for completion")
        
        sut.get(from: anyURL()) { result in
            switch result {
                case .failure(let capturedError as NSError):
                    receivedError = capturedError
                default:
                    XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return receivedError?.omittingUserInfo
    }
}


// MARK: - URLProtocol Stubbing
extension URLSessionHTTPClientTests {
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        // MARK: Registering & Unregistering URLProtocol
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        // MARK: URLProtocol Pre-Initialization Setup
        override class func canInit(with request: URLRequest) -> Bool {
            // Invoke the observer each time we receive a request
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        // MARK: Start & Stop Loading URLProtocool
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}


// MARK: - Mocking URLs, Data, Responses, and Errors
extension URLSessionHTTPClientTests {
    
    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }
    
    private func anyData() -> Data? {
        return Data("any-data".utf8)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 1, userInfo: nil)
    }
}


// MARK: - Additional Helpers
/// This private extension allows us to format errors received back from a `URLSession` to
/// an `NSError` instance with properties matching the orignally passed in error, to enable
/// us to compare the two errors for equality in our test case assertions.
///
/// iOS 14+ replaces received errors via `URLSession` with a new error instance. This new
/// instance includes `userInfo` data, which causes our tests to fail when comparing sent &
/// received errors for equality. Use the `omittingUserInfo` computed property to return
/// an error with the original `domain` and `code` to enable `XCTAssertEqual` usage.
private extension NSError {
    var omittingUserInfo: NSError {
        /// Return an NSError copy using properties of self w/o userInfo
        return NSError(domain: self.domain, code: self.code, userInfo: nil)
    }
}
