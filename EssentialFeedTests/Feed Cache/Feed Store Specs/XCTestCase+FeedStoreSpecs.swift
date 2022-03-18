//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/27/22.
//

import Foundation
import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    
    func assertRetrieveDeliversEmptyOnEmptyCache(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toCompleteRetrievalWith: .success(.none), file: file, line: line)
    }
    
    func assertRetrieveHasNoSideEffectsOnEmptyCache(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toCompleteRetrievalTwiceWith: .success(.none), file: file, line: line)
    }
    
    func assertRetrieveDeliversFoundValuesOnNonEmptyCache(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let cache = mockNonExpiredLocalFeed()
        insert(cache, to: sut)
        expect(sut, toCompleteRetrievalWith: .success((feed: cache.feed, timestamp: cache.timestamp)), file: file, line: line)
    }
    
    func assertRetrieveHasNoSideEffectsOnNonEmptyCache(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let cache = mockNonExpiredLocalFeed()
        insert(cache, to: sut)
        expect(sut, toCompleteRetrievalTwiceWith: .success((feed: cache.feed, timestamp: cache.timestamp)), file: file, line: line)
    }
    
    func assertInsertDeliversNoErrorOnEmptyCache(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let insertionError = insert(mockNonExpiredLocalFeed(), to: sut)
        XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
    }
    
    func assertInsertDeliversNoErrorOnNonEmptyCache(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(mockNonExpiredLocalFeed(), to: sut)
        let insertionError = insert(mockNonExpiredLocalFeed(), to: sut)
        XCTAssertNil(insertionError, "Expected to override cache successfully", file: file, line: line)
    }
    
    func assertInsertOverridesPreviouslyInsertedCacheValues(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let oldCache = mockNonExpiredLocalFeed()
        insert(oldCache, to: sut)
        
        let newCache = mockNonExpiredLocalFeed()
        insert(newCache, to: sut)
        
        expect(sut, toCompleteRetrievalWith: .success((feed: newCache.feed, timestamp: newCache.timestamp)), file: file, line: line)
        XCTAssertNotEqual(oldCache.feed, newCache.feed, "Expected mock helper to create unique feeds", file: file, line: line)
        XCTAssertNotEqual(oldCache.timestamp, newCache.timestamp, "Expected cache timestamps to differ", file: file, line: line)
    }
    
    func assertDeleteDeliversNoErrorOnEmptyCache(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let deletionError = deleteCache(from: sut)
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed", file: file, line: line)
    }
    
    func assertDeleteHasNoSideEffectsOnEmptyCache(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        deleteCache(from: sut)
        expect(sut, toCompleteRetrievalWith: .success(.none), file: file, line: line)
    }
    
    func assertDeleteDeliversNoErrorOnNonEmptyCache(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(mockNonExpiredLocalFeed(), to: sut)
        let deletionError = deleteCache(from: sut)
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed", file: file, line: line)
    }
    
    func assertDeleteEmptiesPreviouslyInsertedCache(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(mockNonExpiredLocalFeed(), to: sut)
        deleteCache(from: sut)
        expect(sut, toCompleteRetrievalWith: .success(.none), file: file, line: line)
    }
    
    func assertFeedStoreOperationSideEffectsRunSerially(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
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
        
        XCTAssertEqual(orderedOpCompletions, [op1, op2, op3], "Expected operations with side effects to complete in order", file: file, line: line)
    }
    
}


// MARK: - Shared Feed Mocking helper
extension FeedStoreSpecs where Self: XCTestCase {
    func mockNonExpiredLocalFeed() -> (feed: [LocalFeedImage], timestamp: Date) {
        let localFeed = mockUniqueFeedWithLocalRep().localRepresentation
        let validTimestamp = Date().feedCacheTimestamp(for: .notExpired)
        return (localFeed, validTimestamp)
    }
}


// MARK: - Shared `FeedStore` Expectations & Operation Helpers
extension FeedStoreSpecs where Self: XCTestCase {
    func expect(_ sut: FeedStore,
                toCompleteRetrievalWith expectedResult: FeedStore.RetrievalResult,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        
        let exp = expectation(description: "Wait for retrieval completion")
        sut.retrieve { receivedResult in
            switch (expectedResult, receivedResult) {
                case (.failure, .failure):
                    break
                case let (.success(expectedCache), .success(receivedCache)):
                    XCTAssertEqual(expectedCache?.feed, receivedCache?.feed, file: file, line: line)
                    XCTAssertEqual(expectedCache?.timestamp, receivedCache?.timestamp, file: file, line: line)
                default:
                    XCTFail("Expected retrieval with \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func expect(_ sut: FeedStore,
                        toCompleteRetrievalTwiceWith expectedResult: FeedStore.RetrievalResult,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        expect(sut, toCompleteRetrievalWith: expectedResult, file: file, line: line)
        expect(sut, toCompleteRetrievalWith: expectedResult, file: file, line: line)
    }
    
    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for insertion completion")
        var insertionError: Error?
        sut.insert(cache.feed, cache.timestamp) { result in
            if case let .failure(error) = result { insertionError = error }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for deletion completion")
        var deletionError: Error?
        sut.deleteCachedFeed { result in
            if case let .failure(error) = result { deletionError = error }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }
}
