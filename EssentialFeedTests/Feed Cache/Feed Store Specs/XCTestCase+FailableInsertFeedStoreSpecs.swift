//
//  XCTestCase+FailableInsertFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/27/22.
//

import Foundation
import XCTest
import EssentialFeed

extension FailableInsertFeedStoreSpecs where Self: CodableFeedStoreTests {
    func assertInsertDeliversErrorOnFailedInsertion(usingStore sut: FeedStore,
                                                    file: StaticString = #filePath, line: UInt = #line) {
        let insertionError = insert(mockNonExpiredLocalFeed(), to: sut)
        XCTAssertNotNil(insertionError, "Expected insertion using an invalidURL to fail with an error", file: file, line: line)
    }
    
    func assertInsertHasNoSideEffectsOnFailedInsertion(usingStore sut: FeedStore,
                                                       file: StaticString = #filePath, line: UInt = #line) {
        insert(mockNonExpiredLocalFeed(), to: sut)
        expect(sut, toCompleteRetrievalWith: .empty, file: file, line: line)
    }
}

extension FailableInsertFeedStoreSpecs where Self: CoreDataFeedStoreTests {
    func assertInsertDeliversErrorOnFailedInsertion(usingStore sut: FeedStore,
                                                    file: StaticString = #filePath, line: UInt = #line) {
        let insertionError = failToInsert(to: sut)
        
        XCTAssertEqual(insertionError, anyNSError(), "Expected insertion on invalid store to fail", file: file, line: line)
    }
    
    private func failToInsert(to sut: FeedStore,
                              file: StaticString = #filePath, line: UInt = #line) -> NSError? {
        let localCache = mockNonExpiredLocalFeed()
        let exp = expectation(description: "Wait for insertion completion")
        
        var insertionError: NSError?
        sut.insert(localCache.feed, localCache.timestamp) { error in
            insertionError = error as NSError?
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        return insertionError
    }
}
