//
//  XCTestCase+FailableInsertFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/27/22.
//

import Foundation
import XCTest
import EssentialFeed

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertInsertDeliversErrorOnFailedInsertion(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let insertionError = insert(mockNonExpiredLocalFeed(), to: sut)
        XCTAssertNotNil(insertionError, "Expected insertion using an invalidURL to fail with an error", file: file, line: line)
    }
    
    func assertInsertHasNoSideEffectsOnFailedInsertion(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(mockNonExpiredLocalFeed(), to: sut)
        expect(sut, toCompleteRetrievalWith: .empty, file: file, line: line)
    }
}
