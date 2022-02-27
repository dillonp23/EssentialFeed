//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/24/22.
//

import Foundation
import EssentialFeed
import XCTest

class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    
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
    
    func test_retrieve_deliversFailureOnFailedRetrieval() {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toCompleteRetrievalWith: .failure(anyNSError()))
    }
    
    func test_retrieve_hasNoSideEffectsOnFailedRetrieval() {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toCompleteRetrievalTwiceWith: .failure(anyNSError()))
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        let insertionError = insert(mockNonExpiredLocalFeed(), to: sut)
        
        XCTAssertNil(insertionError, "Expected to insert cache successfully")
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        insert(mockNonExpiredLocalFeed(), to: sut)
        
        let insertionError = insert(mockNonExpiredLocalFeed(), to: sut)
        
        XCTAssertNil(insertionError, "Expected to override cache successfully")
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        let oldCache = mockNonExpiredLocalFeed()
        insert(oldCache, to: sut)
        
        let newCache = mockNonExpiredLocalFeed()
        insert(newCache, to: sut)
        
        expect(sut, toCompleteRetrievalWith: .found(feed: newCache.feed, timestamp: newCache.timestamp))
        XCTAssertNotEqual(oldCache.feed, newCache.feed, "Expected mock helper to create unique feeds")
        XCTAssertNotEqual(oldCache.timestamp, newCache.timestamp, "Expected cache timestamps to differ")
    }
    
    func test_insert_deliversErrorOnFailedInsertion() {
        let invalidURL = URL(string: "invalid://store-url")
        let sut = makeSUT(storeURL: invalidURL)
        
        let insertionError = insert(mockNonExpiredLocalFeed(), to: sut)
        
        XCTAssertNotNil(insertionError, "Expected insertion using an invalidURL to fail with an error")
    }
    
    func test_insert_hasNoSideEffectsOnFailedInsertion() {
        let invalidURL = URL(string: "invalid://store-url")
        let sut = makeSUT(storeURL: invalidURL)
        
        insert(mockNonExpiredLocalFeed(), to: sut)
        
        expect(sut, toCompleteRetrievalWith: .empty)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        deleteCache(from: sut)
        
        expect(sut, toCompleteRetrievalWith: .empty)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        insert(mockNonExpiredLocalFeed(), to: sut)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        insert(mockNonExpiredLocalFeed(), to: sut)
       
        deleteCache(from: sut)
        
        expect(sut, toCompleteRetrievalWith: .empty)
    }
    
    func test_delete_deliversErrorOnFailedDeletion() {
        let noDeletePermissionsURL = cachesDirectory
        let sut = makeSUT(storeURL: noDeletePermissionsURL)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNotNil(deletionError, "Expected deletion using an invalidURL to fail with an error")
    }
    
    func test_delete_hasNoSideEffectsOnFailedDeletion() {
        let noDeletePermissionsURL = cachesDirectory
        let sut = makeSUT(storeURL: noDeletePermissionsURL)
        
        deleteCache(from: sut)
        
        expect(sut, toCompleteRetrievalWith: .empty)
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
    
    // MARK: SUT & Data Mocking Helpers
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
    
    private func mockNonExpiredLocalFeed() -> (feed: [LocalFeedImage], timestamp: Date) {
        let localFeed = mockUniqueFeedWithLocalRep().localRepresentation
        let validTimestamp = Date().feedCacheTimestamp(for: .notExpired)
        return (localFeed, validTimestamp)
    }
}
