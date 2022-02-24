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
    private struct Cache: Codable {
        let feed: [LocalFeedImage]
        let timestamp: Date
    }
    
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let decodedCache = try! JSONDecoder().decode(Cache.self, from: data)
        completion(.found(feed: decodedCache.feed, timestamp: decodedCache.timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping FeedStore.OperationCompletion) {
        let encodedCache = try! JSONEncoder().encode(Cache(feed: feed, timestamp: timestamp))
        try! encodedCache.write(to: storeURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()

        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    override func tearDown() {
        super.tearDown()
        
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
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
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let localFeed = mockUniqueFeedWithLocalRep().localRepresentation
        let validTimestamp = Date().feedCacheTimestamp(for: .notExpired)
        let sut = CodableFeedStore()
        
        let exp = expectation(description: "Wait for retrieval completion")
        
        sut.insert(localFeed, validTimestamp) { insertionError in
            XCTAssertNil(insertionError)
            
            sut.retrieve { result in
                switch result {
                    case let .found(retrievedFeed, retrievedTimestamp):
                        XCTAssertEqual(localFeed, retrievedFeed)
                        XCTAssertEqual(validTimestamp, retrievedTimestamp)
                    default:
                        XCTFail("Expected .found(\(localFeed), \(validTimestamp), got \(result) instead.")
                }
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
