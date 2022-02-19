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
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] error in
            guard error == nil else { return }
            
            self.store.insert(items, self.currentDate())
        }
    }
}

class FeedStore {
    typealias OperationCompletion = (NSError?) -> Void
    
    enum OperationMessage: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }
    
    private(set) var receivedOperations = [(message: OperationMessage, completion: OperationCompletion)]()
    
    func deleteCachedFeed(completion: @escaping OperationCompletion) {
        receivedOperations.append((.deleteCachedFeed, completion))
    }
    
    func completeDeletion(error: NSError? = nil, at index: Int = 0) {
        receivedOperations[index].completion(error)
    }
    
    func insert(_ items: [FeedItem], _ timestamp: Date, completion: @escaping OperationCompletion = { _ in }) {
        receivedOperations.append((.insert(items, timestamp), completion))
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
        
        sut.save(items)
        
        XCTAssertEqual(store.receivedOperations.count, 1)
        XCTAssertEqual(store.receivedOperations[0].message, .deleteCachedFeed)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = mockUniqueFeedItems()
        let deletionError = anyNSError()

        sut.save(items)
        store.completeDeletion(error: deletionError)

        XCTAssertEqual(store.receivedOperations.count, 1)
        XCTAssertEqual(store.receivedOperations[0].message, .deleteCachedFeed)
    }

    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = mockUniqueFeedItems()
        let (sut, store) = makeSUT(currentDate: { timestamp })

        sut.save(items)
        store.completeDeletion()
        
        XCTAssertEqual(store.receivedOperations.count, 2)
        XCTAssertEqual(store.receivedOperations[0].message, .deleteCachedFeed)
        XCTAssertEqual(store.receivedOperations[1].message, .insert(items, timestamp))
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
