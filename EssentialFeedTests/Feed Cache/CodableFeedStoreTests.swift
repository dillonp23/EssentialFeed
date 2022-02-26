//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/24/22.
//

import Foundation
import EssentialFeed
import XCTest

class CodableFeedStore {
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    typealias RetrievalCompletion = FeedStore.RetrievalCompletion
    typealias RetrievalResult = RetrievedCachedFeedResult
    typealias OperationCompletion = FeedStore.OperationCompletion
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        do {
            let cache = try JSONDecoder().decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeedRepresentation, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
    
    func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping OperationCompletion) {
        let codableFeed = Cache.makeCodable(feed)
        let encodedCache = try! JSONEncoder().encode(Cache(feed: codableFeed, timestamp: timestamp))
        try! encodedCache.write(to: storeURL)
        completion(nil)
    }
}

private struct Cache: Codable {
    let feed: [CodableFeedImage]
    let timestamp: Date
    
    struct CodableFeedImage: Codable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL
    }
    
    var localFeedRepresentation: [LocalFeedImage] {
        feed.map {
            LocalFeedImage(id: $0.id,
                           description: $0.description,
                           location: $0.location,
                           url: $0.url)
        }
    }
    
    static func makeCodable(_ localFeed: [LocalFeedImage]) -> [CodableFeedImage] {
        localFeed.map {
            CodableFeedImage(id: $0.id,
                             description: $0.description,
                             location: $0.location,
                             url: $0.url)
        }
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        clearTestCacheArtifacts()
    }
    
    override func tearDown() {
        super.tearDown()
        clearTestCacheArtifacts()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toCompleteRetrievalWith: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut =  makeSUT()
        
        expect(sut, toCompleteRetrievalTwiceWith: .empty)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut =  makeSUT()
        let mockCache = mockNonExpiredLocalFeed()
        
        insert(mockCache, to: sut)
        expect(sut, toCompleteRetrievalWith: .found(feed: mockCache.feed, timestamp: mockCache.timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut =  makeSUT()
        let mockCache = mockNonExpiredLocalFeed()
        
        insert(mockCache, to: sut)
        expect(sut, toCompleteRetrievalTwiceWith: .found(feed: mockCache.feed, timestamp: mockCache.timestamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toCompleteRetrievalWith: .failure(anyNSError()))
    }
    
    func test_retrieve_hasNoSideEffectsOnRetrievalError() {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toCompleteRetrievalTwiceWith: .failure(anyNSError()))
    }
}


extension CodableFeedStoreTests {
    // MARK: Setup & Teardown
    private func clearTestCacheArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
    
    // MARK: Helpers
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL)
        assertNoMemoryLeaks(sut, objectName: "`CodableFeedStore`", file: file, line: line)
        return sut
    }
    
    private var testSpecificStoreURL: URL {
        FileManager.default.urls(for: .cachesDirectory,
                                    in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    private func expect(_ sut: CodableFeedStore,
                        toCompleteRetrievalWith expectedResult: CodableFeedStore.RetrievalResult,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        
        let exp = expectation(description: "Wait for retrieval completion")
        sut.retrieve { receivedResult in
            switch (expectedResult, receivedResult) {
                case (.empty, .empty), (.failure, .failure):
                    break
                case let (.found(expectedFeed, expectedTimestamp), .found(receivedFeed, receivedTimestamp)):
                    XCTAssertEqual(expectedFeed, receivedFeed, file: file, line: line)
                    XCTAssertEqual(expectedTimestamp, receivedTimestamp, file: file, line: line)
                default:
                    XCTFail("Expected to retrieve \(expectedResult), got \(receivedResult) instead.", file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func expect(_ sut: CodableFeedStore,
                        toCompleteRetrievalTwiceWith expectedResult: CodableFeedStore.RetrievalResult,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        expect(sut, toCompleteRetrievalWith: expectedResult, file: file, line: line)
        expect(sut, toCompleteRetrievalWith: expectedResult, file: file, line: line)
    }
    
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore)  {
        let exp = expectation(description: "Wait for retrieval completion")
        sut.insert(cache.feed, cache.timestamp) { insertionError in
            XCTAssertNil(insertionError)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func mockNonExpiredLocalFeed() -> (feed: [LocalFeedImage], timestamp: Date) {
        let localFeed = mockUniqueFeedWithLocalRep().localRepresentation
        let validTimestamp = Date().feedCacheTimestamp(for: .notExpired)
        return (localFeed, validTimestamp)
    }
}
