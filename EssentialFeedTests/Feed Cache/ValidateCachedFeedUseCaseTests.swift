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
    
    func test_validateCache_doesNotDeleteLessThanSevenDayOldCache() {
        let fixedCurrentDate = Date()
        let cacheExpiration = fixedCurrentDate.adding(days: -7)
        let maxValidCacheAge = cacheExpiration.adding(seconds: 1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        sut.validateCache()
        store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: maxValidCacheAge)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_deletesExactlySevenDayOldCache() {
        let fixedCurrentDate = Date()
        let cacheExpiration = fixedCurrentDate.adding(days: -7)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        sut.validateCache()
        store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: cacheExpiration)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_deletesMoreThanSevenDayOldCache() {
        let fixedCurrentDate = Date()
        let cacheExpiration = fixedCurrentDate.adding(days: -7)
        let moreThanSevenDays = cacheExpiration.adding(seconds: -1)

        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()

        sut.validateCache()
        store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: moreThanSevenDays)

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
