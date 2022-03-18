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
    func assertInsertDeliversErrorOnFailedInsertion(usingStore sut: FeedStore,
                                                    file: StaticString = #filePath, line: UInt = #line) {
        let insertionError = insert(mockNonExpiredLocalFeed(), to: sut)
        XCTAssertNotNil(insertionError, "Expected insertion to fail with an error", file: file, line: line)
    }
    
    func assertInsertHasNoSideEffectsOnFailedInsertion(usingStore sut: FeedStore,
                                                       file: StaticString = #filePath, line: UInt = #line) {
        insert(mockNonExpiredLocalFeed(), to: sut)
        expect(sut, toCompleteRetrievalWith: .success(.none), file: file, line: line)
    }
}
