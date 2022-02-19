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
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping (NSError?) -> Void) {
        store.deleteCachedFeed { [unowned self] deletionError in
            if let error = deletionError {
                completion(error)
            } else {
                self.store.insert(items, self.currentDate()) { insertionError in
                    completion(insertionError)
                }
            }
        }
    }
}

class FeedStore {
    typealias OperationCompletion = (NSError?) -> Void
    
    enum Message: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }
    
    private(set) var receivedOperations = [(operation: Message, completion: OperationCompletion)]()
    
    func deleteCachedFeed(completion: @escaping OperationCompletion) {
        receivedOperations.append((.deleteCachedFeed, completion))
    }
    
    func completeDeletion(error: NSError? = nil, at index: Int = 0) {
        guard receivedOperations[index].operation == .deleteCachedFeed else { return }
        receivedOperations[index].completion(error)
    }
    
    func insert(_ items: [FeedItem], _ timestamp: Date, completion: @escaping OperationCompletion) {
        receivedOperations.append((.insert(items, timestamp), completion))
    }
    
    func completeInsertion(error: NSError? = nil, at index: Int = 1) {
        guard receivedOperations[index].operation != .deleteCachedFeed else { return }
        receivedOperations[index].completion(error)
    }
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
        
        XCTAssertEqual(store.receivedOperations.count, 1)
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
        let items = mockUniqueFeedItems()
        let deletionError = anyNSError()
        let (sut, store) = makeSUT()
        
        let exp = expectation(description: "Wait for save completion")
        var capturedError: NSError?
        sut.save(items) { error in
            capturedError = error
            exp.fulfill()
        }
        store.completeDeletion(error: deletionError)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(store.receivedOperations.count, 1)
        XCTAssertEqual(store.receivedOperations[0].operation, .deleteCachedFeed)
        XCTAssertEqual(deletionError, capturedError)
    }
    
    func test_save_failsOnInsertionError() {
        let timestamp = Date()
        let items = mockUniqueFeedItems()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let insertionError = anyNSError()
        
        let exp = expectation(description: "Wait for save completion")
        var capturedError: NSError?
        sut.save(items) { error in
            capturedError = error
            exp.fulfill()
        }
        store.completeDeletion()
        store.completeInsertion(error: insertionError)
        
        wait(for: [exp], timeout: 1.0)
        
        let orderedOperations = store.receivedOperations.map { $0.operation }
        
        XCTAssertEqual(store.receivedOperations.count, 2)
        XCTAssertEqual(orderedOperations, [.deleteCachedFeed, .insert(items, timestamp)])
        XCTAssertEqual(insertionError, capturedError)
    }
    
    
    // MARK: - Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        assertNoMemoryLeaks(store, objectName: "FeedStore_Cache", file: file, line: line)
        assertNoMemoryLeaks(sut, objectName: "LocalFeedLoader_Cache", file: file, line: line)
        
        return (sut, store)
    }
    
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
