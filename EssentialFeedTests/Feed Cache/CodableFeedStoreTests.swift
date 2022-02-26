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
        do {
            let codableFeed = Cache.makeCodable(feed)
            let encodedCache = try JSONEncoder().encode(Cache(feed: codableFeed, timestamp: timestamp))
            try encodedCache.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    func deleteCachedFeed(completion: @escaping OperationCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return completion(nil)
        }
        
        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
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
        let cache = mockNonExpiredLocalFeed()
        
        insert(cache, to: sut)
        expect(sut, toCompleteRetrievalWith: .found(feed: cache.feed, timestamp: cache.timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut =  makeSUT()
        let cache = mockNonExpiredLocalFeed()
        
        insert(cache, to: sut)
        expect(sut, toCompleteRetrievalTwiceWith: .found(feed: cache.feed, timestamp: cache.timestamp))
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
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        let oldCache = mockNonExpiredLocalFeed()
        
        let firstInsertionError = insert(oldCache, to: sut)
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully but got \(firstInsertionError!)")
        
        let newCache = mockNonExpiredLocalFeed()
        
        let secondInsertionError = insert(newCache, to: sut)
        XCTAssertNil(secondInsertionError, "Expected to override cache successfully but got \(secondInsertionError!)")
        
        expect(sut, toCompleteRetrievalWith: .found(feed: newCache.feed, timestamp: newCache.timestamp))
    }
    
    func test_insert_deliversErrorOnFailedInsertion() {
        let invalidURL = URL(string: "invalid://store-url")
        let sut = makeSUT(storeURL: invalidURL)
        
        let insertionError = insert(mockNonExpiredLocalFeed(), to: sut)
        XCTAssertNotNil(insertionError, "Expected insertion using an invalidURL to fail with error")
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        let deletionError = deleteCache(from: sut)
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed but got \(deletionError!)")
        
        expect(sut, toCompleteRetrievalWith: .empty)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        
        let insertionError = insert(mockNonExpiredLocalFeed(), to: sut)
        XCTAssertNil(insertionError, "Expected to insert cache successfully but got \(insertionError!)")
        
        let deletionError = deleteCache(from: sut)
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed but got \(deletionError!)")
        
        expect(sut, toCompleteRetrievalWith: .empty)
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
    
    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) -> Error? {
        let exp = expectation(description: "Wait for retrieval completion")
        var insertionError: Error?
        sut.insert(cache.feed, cache.timestamp) { error in
            insertionError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    private func deleteCache(from sut: CodableFeedStore) -> Error? {
        let exp = expectation(description: "Wait for deletion completion")
        var deletionError: Error?
        sut.deleteCachedFeed { error in
            deletionError = error
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }
    
    private func mockNonExpiredLocalFeed() -> (feed: [LocalFeedImage], timestamp: Date) {
        let localFeed = mockUniqueFeedWithLocalRep().localRepresentation
        let validTimestamp = Date().feedCacheTimestamp(for: .notExpired)
        return (localFeed, validTimestamp)
    }
}
