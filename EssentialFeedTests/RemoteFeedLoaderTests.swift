//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/10/22.
//

import XCTest

class RemoteFeedLoader {
    let client: HTTPClient
    let url: URL
    
    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    func load() {
        client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        // AsssertNil as url shouldn't be set until sut.load() called
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load()
        
        XCTAssertEqual(client.requestedURL, url)
    }
}

// MARK: - Helpers
extension RemoteFeedLoaderTests {
    
    private class MockHTTPClient: HTTPClient {
        var requestedURL: URL?
        
        func get(from url: URL) {
            requestedURL = url
        }
    }
    
    /// Generates a "System Under Test" to be used by `XCTestCase`
    /// - Parameters:
    ///    - url: the URL to be used for the `MockHTTPClient` request
    /// - Returns:
    ///   A tuple containing (1) the `sut` initialized with a `MockHTTPClient` instance,
    ///   and (2) the `client` instance itself in order to perform `XCTest` assertions
    private func makeSUT(url: URL = URL(string: "https://a-url")!) -> (sut: RemoteFeedLoader, client: MockHTTPClient) {
        let client = MockHTTPClient()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
}
