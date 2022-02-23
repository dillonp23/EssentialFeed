//
//  ValidateCachedFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/22/22.
//

import Foundation
import XCTest
import EssentialFeed

class ValidateCachedFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()

        sut.validateCache()
        store.completeRetrievalWithFailure(retrievalError)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_doesNotDeleteEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrievalSuccessfully(with: [])
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_doesNotDeleteNonExpiredCache() {
        let fixedCurrentDate = Date()
        let timestamp = fixedCurrentDate.feedCacheTimestamp(for: .notExpired)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        sut.validateCache()
        store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: timestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_deletesCacheAtExactTimeOfExpiration() {
        let fixedCurrentDate = Date()
        let timestamp = fixedCurrentDate.feedCacheTimestamp(for: .atTimeOfExpiration)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        sut.validateCache()
        store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: timestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_deletesExpiredCache() {
        let fixedCurrentDate = Date()
        let timestamp = fixedCurrentDate.feedCacheTimestamp(for: .expired)

        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()

        sut.validateCache()
        store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: timestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_doesNotDeleteInvalidCacheAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        sut?.validateCache()
        sut = nil
        store.completeRetrievalWithFailure(anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    
    // MARK: - Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        assertNoMemoryLeaks(store, objectName: "FeedStore_Cache", file: file, line: line)
        assertNoMemoryLeaks(sut, objectName: "LocalFeedLoader_Cache", file: file, line: line)
        
        return (sut, store)
    }
}
