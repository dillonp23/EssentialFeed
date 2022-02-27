//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/24/22.
//

import Foundation
import EssentialFeed
import XCTest

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
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")
        
        let newCache = mockNonExpiredLocalFeed()
        
        let secondInsertionError = insert(newCache, to: sut)
        XCTAssertNil(secondInsertionError, "Expected to override cache successfully")
        
        expect(sut, toCompleteRetrievalWith: .found(feed: newCache.feed, timestamp: newCache.timestamp))
    }
    
    func test_insert_deliversErrorOnFailedInsertion() {
        let invalidURL = URL(string: "invalid://store-url")
        let sut = makeSUT(storeURL: invalidURL)
        
        let insertionError = insert(mockNonExpiredLocalFeed(), to: sut)
        XCTAssertNotNil(insertionError, "Expected insertion using an invalidURL to fail with an error")
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toCompleteDeletionWith: nil, assertMessage: "Expected empty cache deletion to succeed")
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        
        let insertionError = insert(mockNonExpiredLocalFeed(), to: sut)
        XCTAssertNil(insertionError, "Expected to insert cache successfully")
       
        expect(sut, toCompleteDeletionWith: nil, assertMessage: "Expected non-empty cache deletion to succeed")
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionsURL = cachesDirectory
        let sut = makeSUT(storeURL: noDeletePermissionsURL)
        let failMessage = "Expected deletion to fail for lack of permission at `Library/Caches` directory"
        
        expect(sut, toCompleteDeletionWith: anyNSError(), assertMessage: failMessage)
    }
    
    func test_feedStoreOperations_sideEffectsRunSerially() {
        let sut = makeSUT()
        var orderedOpCompletions = [XCTestExpectation]()
        
        let op1 = expectation(description: "Side Effect Operation 1 - Insert")
        sut.insert(mockNonExpiredLocalFeed().feed, Date()) { _ in
            orderedOpCompletions.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Side Effect Operation 2 - Delete")
        sut.deleteCachedFeed { _ in
            orderedOpCompletions.append(op2)
            op2.fulfill()
        }
        
        let op3 = expectation(description: "Side Effect Operation 3 - Insert")
        sut.insert(mockNonExpiredLocalFeed().feed, Date()) { _ in
            orderedOpCompletions.append(op3)
            op3.fulfill()
        }
        
        wait(for: [op1, op2, op3], timeout: 5.0)
        
        XCTAssertEqual(orderedOpCompletions, [op1, op2, op3], "Expected operations with side effects to complete in order")
    }
}


extension CodableFeedStoreTests {
    // MARK: Setup & Teardown
    private func clearTestCacheArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
    
    // MARK: Helpers
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL)
        assertNoMemoryLeaks(sut, objectName: "`CodableFeedStore`", file: file, line: line)
        return sut
    }
    
    private var testSpecificStoreURL: URL {
        cachesDirectory.appendingPathComponent("\(type(of: self)).store")
    }
    
    private var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func expect(_ sut: FeedStore,
                        toCompleteRetrievalWith expectedResult: RetrievedCachedFeedResult,
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
                    XCTFail("Expected retrieval with \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func expect(_ sut: FeedStore,
                        toCompleteRetrievalTwiceWith expectedResult: RetrievedCachedFeedResult,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        expect(sut, toCompleteRetrievalWith: expectedResult, file: file, line: line)
        expect(sut, toCompleteRetrievalWith: expectedResult, file: file, line: line)
    }
    
    private func expect(_ sut: FeedStore,
                        toCompleteDeletionWith expectedError: NSError?,
                        assertMessage: String,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        let deletionError = deleteCache(from: sut)
        
        if expectedError == nil {
            XCTAssertNil(deletionError, "\(assertMessage), but got an error", file: file, line: line)
        } else {
            XCTAssertNotNil(deletionError, assertMessage, file: file, line: line)
        }
        
        expect(sut, toCompleteRetrievalWith: .empty, file: file, line: line)
    }
    
    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for retrieval completion")
        var insertionError: Error?
        sut.insert(cache.feed, cache.timestamp) { error in
            insertionError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    private func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for deletion completion")
        var deletionError: Error?
        sut.deleteCachedFeed { error in
            deletionError = error
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 4.0)
        return deletionError
    }
    
    private func mockNonExpiredLocalFeed() -> (feed: [LocalFeedImage], timestamp: Date) {
        let localFeed = mockUniqueFeedWithLocalRep().localRepresentation
        let validTimestamp = Date().feedCacheTimestamp(for: .notExpired)
        return (localFeed, validTimestamp)
    }
}
