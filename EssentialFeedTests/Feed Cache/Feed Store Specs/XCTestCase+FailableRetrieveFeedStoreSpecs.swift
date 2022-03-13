//
//  XCTestCase+FailableRetrieveFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/27/22.
//

import Foundation
import XCTest
import EssentialFeed

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
    func assertRetrieveDeliversFailureOnFailedRetrieval(usingStore sut: FeedStore, storeURL: URL? = nil,
                                                        file: StaticString = #filePath, line: UInt = #line) {
        writeInvalidDataForRetrieval(to: storeURL)
        expect(sut, toCompleteRetrievalWith: .failure(anyNSError()), file: file, line: line)
    }
    
    func assertRetrieveHasNoSideEffectsOnFailedRetrieval(usingStore sut: FeedStore, storeURL: URL? = nil,
                                                         file: StaticString = #filePath, line: UInt = #line) {
        writeInvalidDataForRetrieval(to: storeURL)
        expect(sut, toCompleteRetrievalTwiceWith: .failure(anyNSError()), file: file, line: line)
    }
    
    /// `CodableFeedStore` requires non-empty invalid data to cause failure (ignored for CoreData store)
    private func writeInvalidDataForRetrieval(to storeURL: URL?) {
        guard let storeURL = storeURL else { return }
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
    }
}
