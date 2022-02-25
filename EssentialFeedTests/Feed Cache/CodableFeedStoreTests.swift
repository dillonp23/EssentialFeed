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
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let cache = try! JSONDecoder().decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeedRepresentation, timestamp: cache.timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping FeedStore.OperationCompletion) {
        let codableFeed = Cache.makeCodable(feed)
        let encodedCache = try! JSONEncoder().encode(Cache(feed: codableFeed, timestamp: timestamp))
        try! encodedCache.write(to: storeURL)
        completion(nil)
    }
}

private struct Cache: Codable {
    let feed: [CodableFeedImage]
    let timestamp: Date
    
    struct CodableFeedImage: Codable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL
    }
    
    var localFeedRepresentation: [LocalFeedImage] {
        feed.map {
            LocalFeedImage(id: $0.id,
                           description: $0.description,
                           location: $0.location,
                           url: $0.url)
        }
    }
    
    static func makeCodable(_ localFeed: [LocalFeedImage]) -> [CodableFeedImage] {
        localFeed.map {
            CodableFeedImage(id: $0.id,
                             description: $0.description,
                             location: $0.location,
                             url: $0.url)
        }
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        clearTestCacheArtifacts()
    }
    
    override func tearDown() {
        super.tearDown()
        clearTestCacheArtifacts()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
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
        let sut =  makeSUT()
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
        let sut =  makeSUT()
        
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
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let localFeed = mockUniqueFeedWithLocalRep().localRepresentation
        let validTimestamp = Date().feedCacheTimestamp(for: .notExpired)
        let sut =  makeSUT()
        
        let exp = expectation(description: "Wait for retrieval completion")
        
        sut.insert(localFeed, validTimestamp) { insertionError in
            XCTAssertNil(insertionError)
            
            sut.retrieve { firstResult in
                sut.retrieve { secondResult in
                    switch (firstResult, secondResult) {
                        case let (.found(firstFeed, firstTimestamp), .found(secondFeed, secondTimestamp)):
                            XCTAssertEqual(firstFeed, localFeed)
                            XCTAssertEqual(firstTimestamp, validTimestamp)
                            
                            XCTAssertEqual(firstFeed, secondFeed)
                            XCTAssertEqual(firstTimestamp, secondTimestamp)
                        default:
                            XCTFail("Expected both results to match `insert()` params, got (\(firstResult), \(secondResult)) instead.")
                    }
                    exp.fulfill()
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}


// MARK: Helpers
extension CodableFeedStoreTests {
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL)
        assertNoMemoryLeaks(sut, objectName: "`CodableFeedStore`", file: file, line: line)
        return sut
    }
    
    private var testSpecificStoreURL: URL {
        FileManager.default.urls(for: .cachesDirectory,
                                    in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    private func clearTestCacheArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
}
