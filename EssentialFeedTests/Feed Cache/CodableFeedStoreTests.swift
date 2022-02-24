//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/24/22.
//

import Foundation
import EssentialFeed
import XCTest

class CodableFeedStore {
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        completion(.empty)
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "Wait for retrieval completion")
        
        sut.retrieve { result in
            switch result {
                case .empty:
                    break
                default:
                    XCTFail("Expected empty result, got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "Wait for retrieval completion")
        
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                    case (.empty, .empty):
                        break
                    default:
                        XCTFail("""
                                Expected the same result (.empty, .empty) when retrieving from \
                                empty cache twice, got (\(firstResult), \(secondResult)) instead.
                                """)
                }
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
