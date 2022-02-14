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
    
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "https://any-url")!
        let error = NSError(domain: "any error", code: 1, userInfo: nil)
        URLProtocolStub.stub(url: url, data: nil, response: nil,  error: error)
        
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
        URLProtocolStub.stopInterceptingRequests()
    }
}


// MARK: - URLProtocol Stubbing
extension URLSessionHTTPClientTests {
    
    private class URLProtocolStub: URLProtocol {
        private static var stubs = [URL: Stub]()
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(url: URL, data: Data?, response: URLResponse?, error: Error?) {
            stubs[url] = Stub(data: data, response: response, error: error)
        }
        
        // MARK: Registering & Unregistering URLProtocol
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stubs = [:]
        }
        
        // MARK: URLProtocol Pre-Initialization Setup
        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            
            return URLProtocolStub.stubs[url] != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        // MARK: Start & Stop Loading URLProtocool
        override func startLoading() {
            guard let url = request.url,
                  let stub = URLProtocolStub.stubs[url] else { return }
            
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = stub.error {
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
