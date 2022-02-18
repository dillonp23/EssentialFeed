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
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

class FeedStore {
    private(set) var deleteCachedFeedCallCount = 0
    
    func deleteCachedFeed() {
        deleteCachedFeedCallCount += 1
    }
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        
        let items = mockUniqueFeedItems()
        sut.save(items)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }
    
    
    // MARK: - Helpers
    private func makeSUT() -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
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
}