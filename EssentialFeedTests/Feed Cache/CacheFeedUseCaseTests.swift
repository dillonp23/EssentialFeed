//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/18/22.
//

import Foundation
import XCTest
import EssentialFeed

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public typealias SaveResult = Error?
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deletionError in
            guard let self = self else { return }
            
            guard deletionError == nil else {
                return completion(deletionError)
            }
            
            self.insertToCache(items, completion: completion)
        }
    }
    
    private func insertToCache(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.insert(items, currentDate()) { [weak self] insertionError in
            guard self != nil else { return }
            completion(insertionError)
        }
    }
}

public protocol FeedStore {
    typealias OperationCompletion = (Error?) -> Void
    
    func insert(_ items: [FeedItem], _ timestamp: Date, completion: @escaping OperationCompletion)
    func deleteCachedFeed(completion: @escaping OperationCompletion)
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedOperations.count, 0)
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = mockUniqueFeedItems()
        
        sut.save(items) { _ in }
        
        XCTAssertEqual(store.receivedOperations[0].operation, .deleteCachedFeed)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = mockUniqueFeedItems()
        let deletionError = anyNSError()
        
        sut.save(items) { _ in }
        store.completeDeletion(error: deletionError)
        
        XCTAssertEqual(store.receivedOperations.count, 1)
        XCTAssertEqual(store.receivedOperations[0].operation, .deleteCachedFeed)
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = mockUniqueFeedItems()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items) { _ in }
        store.completeDeletion()
        
        XCTAssertEqual(store.receivedOperations.count, 2)
        XCTAssertEqual(store.receivedOperations[0].operation, .deleteCachedFeed)
        XCTAssertEqual(store.receivedOperations[1].operation, .insert(items, timestamp))
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
    
    // Mocking Data & Errors
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
            case insert([FeedItem], Date)
        }
        
        private(set) var receivedOperations = [(operation: Message, completion: OperationCompletion)]()
        
        func deleteCachedFeed(completion: @escaping OperationCompletion) {
            receivedOperations.append((.deleteCachedFeed, completion))
        }
        
        func completeDeletion(error: Error? = nil, at index: Int = 0) {
            guard receivedOperations[index].operation == .deleteCachedFeed else { return }
            receivedOperations[index].completion(error)
        }
        
        func insert(_ items: [FeedItem], _ timestamp: Date, completion: @escaping OperationCompletion) {
            receivedOperations.append((.insert(items, timestamp), completion))
        }
        
        func completeInsertion(error: Error? = nil, at index: Int = 1) {
            guard receivedOperations[index].operation != .deleteCachedFeed else { return }
            receivedOperations[index].completion(error)
        }
    }
}
