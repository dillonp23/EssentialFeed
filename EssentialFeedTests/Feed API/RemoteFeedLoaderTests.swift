//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/10/22.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        // AsssertNil as url shouldn't be set until sut.load() called
        XCTAssert(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.connectivity), forAction: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let statusCodes = [199, 201, 300, 400, 404, 412, 500, 502]
        
        statusCodes.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.invalidData), forAction: {
                client.complete(with: code, data: Data(), at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.invalidData), forAction: {
            let invalidJSON = mockBadData(with: .invalidJSON)
            client.complete(with: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), forAction: {
            let emptyJSON = mockBadData(with: .emptyJSON)
            client.complete(with: 200, data: emptyJSON)
        })
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithValidJSON() {
        let (sut, client) = makeSUT()
        let (feedItems, jsonData) = mockFeedItemsAndResponsePayload()
        
        expect(sut, toCompleteWith: .success(feedItems), forAction: {
            client.complete(with: 200, data: jsonData)
        })
    }
    
    /// To prevent unexpected behavior, we must assert that the `RemoteFeedLoader`
    /// objects `load(completion: (Result) -> Void)` method does not send
    /// a result completion message, in the edge case where `RemoteFeedLoader`
    /// has already been deallocated, but the client still exists.
    func test_load_doesNotCompleteWithResultAfterSUTIsDeallocated() {
        let url = URL(string: "https://deallocationPreventsCompletion")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(client: client, url: url)
        
        var capturedResults = [RemoteFeedLoader.Result]()
        
        // 1. Send `load(completion:)` method invocations to SUT
        sut?.load { capturedResults.append($0) }
        // 2. deallocate SUT
        sut = nil
        
        // 3. call completion with 200 status code on client
        client.complete(with: 200, data: mockBadData(with: .emptyJSON))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
}

// MARK: - Spy HTTP Client
extension RemoteFeedLoaderTests {
    
    private class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        /// Mocks a get request completion failure using an error
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        /// Mocks a get request completion success with an `HTTPURLResponse`
        func complete(with statusCode: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil)!
            
            messages[index].completion(.success(data, response))
        }
    }
}

// MARK: - Helper Methods
extension RemoteFeedLoaderTests {
    
    // MARK: Mocking FeedItems & JSON Response from API
    typealias FeedItemJSON = [String: String]
    
    private enum DataError {
        case invalidJSON
        case emptyJSON
    }
    
    private func mockBadData(with error: DataError) -> Data {
        switch error {
            case .invalidJSON:
                return Data("invalidJSON".utf8)
            case .emptyJSON:
                // mocks a valid API response, but with an empty array
                let emptyJSON = ["items": [FeedItemJSON]()]
                let data = try! JSONSerialization.data(withJSONObject: emptyJSON)
                return data
        }
    }
    
    private func mockFeedItemsAndResponsePayload() -> ([FeedItem], Data) {
        var feedItems = [FeedItem]()
        var jsonPayload = [String: [FeedItemJSON]]()
        
        for _ in 0..<Int.random(in: 1...10) {
            let (feedItem, jsonItem) = createMockItemAndJSON()
            feedItems.append(feedItem)
            jsonPayload["items", default: []].append(jsonItem)
        }
        
        // convert to data representation to test API response
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonPayload)
        
        return (feedItems, jsonData)
    }
    
    private func createMockItemAndJSON() -> (FeedItem, FeedItemJSON) {
        let itemID = UUID()
        // Use first 8 characters of UUID string to append to key-value
        // pairs (if needed) to mock different values for each feed item
        let itemSuffixID = itemID.uuidString.prefix(8)
        
        let feedItem = FeedItem(id: itemID,
                                description: Bool.random() ? "Description+\(itemSuffixID)" : nil,
                                location: Bool.random() ? "Location+\(itemSuffixID)" : nil,
                                imageURL: URL(string: "https://an-image+\(itemSuffixID)")!)
        
        // Create json by removing nil values to mock an API response
        let jsonItem = ["id": feedItem.id.uuidString,
                        "image": feedItem.imageURL.absoluteString,
                        "description": feedItem.description,
                        "location": feedItem.location].compactMapValues{ $0 }
        
        return (feedItem, jsonItem)
    }
    
    // MARK: Configure System Under Test (SUT)
    private typealias SystemUnderTest = (sut: RemoteFeedLoader, client: HTTPClientSpy)
    
    /// Generates a "System Under Test" `RemoteFeedLoader` to be used by `XCTestCase`
    /// - Parameters:
    ///    - url: the URL to be used for the `MockHTTPClient` request
    /// - Returns:
    ///   A tuple containing (1) the `sut` initialized with a `MockHTTPClient` instance,
    ///   and (2) the `client` instance itself in order to perform `XCTest` assertions
    private func makeSUT(url: URL = URL(string: "https://a-url")!,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> SystemUnderTest {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        
        assertNoMemoryLeaks(client, objectName: "Client", file: file, line: line)
        assertNoMemoryLeaks(sut, objectName: "SUT", file: file, line: line)
        
        return (sut, client)
    }
    
    private func assertNoMemoryLeaks(_ instance: AnyObject,
                                              objectName: String,
                                              file: StaticString = #filePath,
                                              line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            let message = "\(objectName) instance should've been deallocated; potential memory leak."
            XCTAssertNil(instance, message, file: file, line: line)
        }
    }
    
    // MARK: SUT Test Case Assert Helper
    /// Generic method facillitates test case assertions for expected result type on sut,
    /// when an expected result and provided action are passed into method and performed
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWith expectedResult: RemoteFeedLoader.Result,
                        forAction action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        
        let exp = expectation(description: "Wait for load method completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
                case (.success(let receivedItems), .success(let expectedItems)):
                    XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
                    
                case (.failure(let receivedError as RemoteFeedLoader.Error),
                      .failure(let expectedError as RemoteFeedLoader.Error)):
                    XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                    
                default:
                    let message = "Expected result \(expectedResult), got \(receivedResult) instead"
                    XCTFail(message, file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
}
