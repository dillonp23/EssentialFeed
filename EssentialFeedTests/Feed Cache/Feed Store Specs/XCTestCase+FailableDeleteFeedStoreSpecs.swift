//
//  XCTestCase+FailableDeleteFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/27/22.
//

import Foundation
import XCTest
import EssentialFeed

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assertDeleteDeliversErrorOnFailedDeletion(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let deletionError = deleteCache(from: sut)
        XCTAssertNotNil(deletionError, "Expected deletion using an invalidURL to fail with an error", file: file, line: line)
    }
    
    func assertDeleteHasNoSideEffectsOnFailedDeletion(usingStore sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        deleteCache(from: sut)
        expect(sut, toCompleteRetrievalWith: .empty, file: file, line: line)
    }
}
