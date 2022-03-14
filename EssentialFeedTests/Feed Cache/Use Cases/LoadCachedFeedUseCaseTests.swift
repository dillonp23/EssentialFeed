//
//  LoadCachedFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/21/22.
//

import Foundation
import XCTest
import EssentialFeed

class LoadCachedFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeliverLoadMessageUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnCacheRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()
        
        expect(sut, toCompleteWith: .failure(retrievalError), forAction: {
            store.completeRetrievalWithFailure(retrievalError)
        })
    }
    
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), forAction: {
            store.completeRetrievalSuccessfully(with: [])
        })
    }
    
    func test_load_deliversImagesOnRetrievalSuccessForNonExpiredCache() {
        let fixedCurrentDate = Date()
        let timestamp = fixedCurrentDate.feedCacheTimestamp(for: .notExpired)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        expect(sut, toCompleteWith: .success(feed.images), forAction: {
            store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: timestamp)
        })
    }
    
    func test_load_deliversEmptyFeedOnRetrievalSuccessForCacheAtExactTimeOfExpiration() {
        let fixedCurrentDate = Date()
        let timestamp = fixedCurrentDate.feedCacheTimestamp(for: .atTimeOfExpiration)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        expect(sut, toCompleteWith: .success([]), forAction: {
            store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: timestamp)
        })
    }
    
    func test_load_deliversEmptyFeedOnRetrievalSuccessForExpiredCache() {
        let fixedCurrentDate = Date()
        let timestamp = fixedCurrentDate.feedCacheTimestamp(for: .expired)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        expect(sut, toCompleteWith: .success([]), forAction: {
            store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: timestamp)
        })
    }
    
    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()
        
        sut.load { _ in }
        store.completeRetrievalWithFailure(retrievalError)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrievalSuccessfully(with: [])
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnNonExpiredCache() {
        let fixedCurrentDate = Date()
        let timestamp = fixedCurrentDate.feedCacheTimestamp(for: .notExpired)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        sut.load { _ in }
        store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: timestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnCacheAtExactTimeOfExpiration() {
        let fixedCurrentDate = Date()
        let timestamp = fixedCurrentDate.feedCacheTimestamp(for: .atTimeOfExpiration)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        sut.load { _ in }
        store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: timestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnExpiredCache() {
        let fixedCurrentDate = Date()
        let timestamp = fixedCurrentDate.feedCacheTimestamp(for: .expired)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        sut.load { _ in }
        store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: timestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var capturedResults = [FeedLoader.Result]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        store.completeRetrievalSuccessfully(with: [])
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
}

extension LoadCachedFeedUseCaseTests {
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        assertNoMemoryLeaks(store, objectName: "FeedStore_Cache", file: file, line: line)
        assertNoMemoryLeaks(sut, objectName: "LocalFeedLoader_Cache", file: file, line: line)
        
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader,
                        toCompleteWith expectedResult: FeedLoader.Result,
                        forAction action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { receivedResult in
            switch (expectedResult, receivedResult) {
                case let (.success(expectedImages), .success(receivedImages)):
                    XCTAssertEqual(expectedImages, receivedImages, file: file, line: line)
                case let (.failure(expectedError as NSError), .failure(receivedError as NSError)):
                    XCTAssertEqual(expectedError, receivedError, file: file, line: line)
                default:
                    let (expRes, recRes) = (expectedResult, receivedResult)
                    XCTFail("Expected \(expRes), got \(recRes) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
}
