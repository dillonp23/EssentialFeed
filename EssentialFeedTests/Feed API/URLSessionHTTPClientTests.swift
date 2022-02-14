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
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}


class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    /// If we invoke the `get(from:)` method with a url, then we expect a request
    /// to be executed with the correct url and HTTPMethod.
    ///
    /// This test allows us to determine if there is an issue with the url itself, or if there
    /// is an issue somewhere else (such as with the request or SUT).
    func test_getFromURL_performsGETRequestWithURL() {
        let url = URL(string: "https://any-url.com")!
        let exp = expectation(description: "Wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(url, request.url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        URLSessionHTTPClient().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsWhenURLDoesntMatchObservedRequestURL() {
        let url = URL(string: "https://a-url.com")!
        let exp = expectation(description: "Wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertNotEqual(url, request.url)
            exp.fulfill()
        }
        
        let badURL = URL(string: "https://a-different-url.com")!
        URLSessionHTTPClient().get(from: badURL) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://any-url.com")!
        let error = NSError(domain: "any error", code: 1, userInfo: nil)
        URLProtocolStub.stub(data: nil, response: nil,  error: error)
        
        let sut = URLSessionHTTPClient()
        let exp = expectation(description: "Wait for completion")
        
        sut.get(from: url) { result in
            switch result {
                case .failure(let receivedError as NSError):
                    XCTAssertEqual(error, receivedError.omittingUserInfo)
                default:
                    XCTFail("Expected failure with error \(error), got \(result) instead.")
            }
            
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
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


// MARK: - Helpers
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
