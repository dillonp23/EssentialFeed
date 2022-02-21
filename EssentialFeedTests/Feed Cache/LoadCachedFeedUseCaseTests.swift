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
        
        XCTAssertEqual(store.receivedOperations.count, 0)
    }
}

// MARK: FeedStoreSpy Test Case Class
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
    
    private class FeedStoreSpy: FeedStore {
        typealias OperationCompletion = (Error?) -> Void
        
        enum Message: Equatable {
            case deleteCachedFeed
            case insert([LocalFeedImage], Date)
        }
        
        private(set) var receivedOperations = [(operation: Message, completion: OperationCompletion)]()
        
        func deleteCachedFeed(completion: @escaping OperationCompletion) {
            receivedOperations.append((.deleteCachedFeed, completion))
        }
        
        func completeDeletion(error: Error? = nil, at index: Int = 0) {
            guard receivedOperations[index].operation == .deleteCachedFeed else { return }
            receivedOperations[index].completion(error)
        }
        
        func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping OperationCompletion) {
            receivedOperations.append((.insert(feed, timestamp), completion))
        }
        
        func completeInsertion(error: Error? = nil, at index: Int = 1) {
            guard receivedOperations[index].operation != .deleteCachedFeed else { return }
            receivedOperations[index].completion(error)
        }
    }
}
