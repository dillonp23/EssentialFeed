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
    func assertRetrieveDeliversFailureOnFailedRetrieval(usingStore sut: FeedStore, storeURL: URL) {
        writeInvalidDataForRetrieval(to: storeURL)
        expect(sut, toCompleteRetrievalWith: .failure(anyNSError()))
    }
    
    func assertRetrieveHasNoSideEffectsOnFailedRetrieval(usingStore sut: FeedStore, storeURL: URL) {
        writeInvalidDataForRetrieval(to: storeURL)
        expect(sut, toCompleteRetrievalTwiceWith: .failure(anyNSError()))
    }
    
    private func writeInvalidDataForRetrieval(to storeURL: URL) {
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
    }
}
