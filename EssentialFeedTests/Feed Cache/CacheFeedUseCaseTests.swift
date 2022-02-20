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
        
        XCTAssertEqual(store.receivedOperations.count, 0)
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        
        sut.save(mockUniqueFeedItems()) { _ in }
        
        XCTAssertEqual(store.receivedOperations[0].operation, .deleteCachedFeed)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(mockUniqueFeedItems()) { _ in }
        store.completeDeletion(error: deletionError)
        
        XCTAssertEqual(store.receivedOperations.count, 1)
        XCTAssertEqual(store.receivedOperations[0].operation, .deleteCachedFeed)
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let feed = mockUniqueFeed()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(feed.items) { _ in }
        store.completeDeletion()
        
        XCTAssertEqual(store.receivedOperations.count, 2)
        XCTAssertEqual(store.receivedOperations[0].operation, .deleteCachedFeed)
        XCTAssertEqual(store.receivedOperations[1].operation, .insert(feed.localRepresentation, timestamp))
    }
    
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        expect(sut, toCompleteWith: deletionError, forAction: {
            store.completeDeletion(error: deletionError)
            XCTAssertEqual(store.receivedOperations.count, 1)
        })
    }
    
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        
        expect(sut, toCompleteWith: insertionError, forAction: {
            store.completeDeletion()
            store.completeInsertion(error: insertionError)
            XCTAssertEqual(store.receivedOperations.count, 2)
        })
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: nil, forAction: {
            store.completeDeletion()
            store.completeInsertion()
            XCTAssertEqual(store.receivedOperations.count, 2)
        })
    }
    
    func test_save_doesNotDeliverDeletionErrorAfterSUTIsDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var capturedErrors = [LocalFeedLoader.SaveResult]()
        sut?.save(mockUniqueFeedItems()) { error in
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
        sut?.save(mockUniqueFeedItems()) { error in
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
        sut.save(mockUniqueFeedItems()) { error in
            capturedError = error as NSError?
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(expectedError, capturedError, file: file, line: line)
    }
    
    // MARK: Mocking Data & Errors
    private func mockUniqueFeedItems() -> [FeedItem] {
        var items = [FeedItem]()
        
        for i in 1...3 {
            items.append(FeedItem(id: UUID(),
                                  description: "a description \(i)",
                                  location: "a location \(i)",
                                  imageURL: URL(string: "http://an-imageURL.com?id=\(i)")!))
        }
        
        return items
    }
    
    private func mockUniqueFeed() -> (items: [FeedItem], localRepresentation: [LocalFeedItem]) {
        let items = mockUniqueFeedItems()
        let localItems = items.map {
            LocalFeedItem(id: $0.id,
                          description: $0.description,
                          location: $0.location,
                          imageURL: $0.imageURL)
        }
        
        return (items, localItems)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 1, userInfo: nil)
    }
}


// MARK: FeedStoreSpy Test Case Class
extension CacheFeedUseCaseTests {
    
    private class FeedStoreSpy: FeedStore {
        typealias OperationCompletion = (Error?) -> Void
        
        enum Message: Equatable {
            case deleteCachedFeed
            case insert([LocalFeedItem], Date)
        }
        
        private(set) var receivedOperations = [(operation: Message, completion: OperationCompletion)]()
        
        func deleteCachedFeed(completion: @escaping OperationCompletion) {
            receivedOperations.append((.deleteCachedFeed, completion))
        }
        
        func completeDeletion(error: Error? = nil, at index: Int = 0) {
            guard receivedOperations[index].operation == .deleteCachedFeed else { return }
            receivedOperations[index].completion(error)
        }
        
        func insert(_ items: [LocalFeedItem], _ timestamp: Date, completion: @escaping OperationCompletion) {
            receivedOperations.append((.insert(items, timestamp), completion))
        }
        
        func completeInsertion(error: Error? = nil, at index: Int = 1) {
            guard receivedOperations[index].operation != .deleteCachedFeed else { return }
            receivedOperations[index].completion(error)
        }
    }
}
