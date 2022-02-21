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
}
