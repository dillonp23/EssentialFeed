//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/18/22.
//

import Foundation
import XCTest
import EssentialFeed

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        
        sut.save(mockUniqueImageFeed()) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(mockUniqueImageFeed()) { _ in }
        store.completeDeletion(error: deletionError)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let feed = mockUniqueFeedWithLocalRep()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(feed.images) { _ in }
        store.completeDeletion()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(feed.localRepresentation, timestamp)])
    }
    
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        expect(sut, toCompleteWith: deletionError, forAction: {
            store.completeDeletion(error: deletionError)
        })
    }
    
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        
        expect(sut, toCompleteWith: insertionError, forAction: {
            store.completeDeletion()
            store.completeInsertion(error: insertionError)
        })
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: nil, forAction: {
            store.completeDeletion()
            store.completeInsertion()
        })
    }
    
    func test_save_doesNotDeliverDeletionErrorAfterSUTIsDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var capturedErrors = [LocalFeedLoader.SaveResult]()
        sut?.save(mockUniqueImageFeed()) { error in
            capturedErrors.append(error)
        }
        
        sut = nil
        store.completeDeletion(error: anyNSError())
        
        XCTAssertTrue(capturedErrors.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterSUTIsDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var capturedErrors = [LocalFeedLoader.SaveResult]()
        sut?.save(mockUniqueImageFeed()) { error in
            capturedErrors.append(error)
        }
        
        store.completeDeletion()
        sut = nil
        store.completeInsertion(error: anyNSError())
        
        XCTAssertTrue(capturedErrors.isEmpty)
    }
}


// MARK: - Helpers
extension CacheFeedUseCaseTests {

    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        assertNoMemoryLeaks(store, objectName: "FeedStore_Cache", file: file, line: line)
        assertNoMemoryLeaks(sut, objectName: "LocalFeedLoader_Cache", file: file, line: line)
        
        return (sut, store)
    }
    
    // MARK: Test Assertions
    private func expect(_ sut: LocalFeedLoader,
                        toCompleteWith expectedError: NSError?,
                        forAction action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        
        let exp = expectation(description: "Wait for save completion")
        
        var capturedError: NSError?
        sut.save(mockUniqueImageFeed()) { error in
            capturedError = error as NSError?
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(expectedError, capturedError, file: file, line: line)
    }
}
