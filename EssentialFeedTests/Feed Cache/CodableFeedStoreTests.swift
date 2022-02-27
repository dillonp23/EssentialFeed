//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/24/22.
//

import Foundation
import EssentialFeed
import XCTest

class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    
    override func setUp() {
        super.setUp()
        clearTestCacheArtifacts()
    }
    
    override func tearDown() {
        super.tearDown()
        clearTestCacheArtifacts()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        assertRetrieveDeliversEmptyOnEmptyCache(usingStore: makeSUT())
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        assertRetrieveHasNoSideEffectsOnEmptyCache(usingStore: makeSUT())
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        assertRetrieveDeliversFoundValuesOnNonEmptyCache(usingStore: makeSUT())
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        assertRetrieveHasNoSideEffectsOnNonEmptyCache(usingStore: makeSUT())
    }
    
    func test_retrieve_deliversFailureOnFailedRetrieval() {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        assertRetrieveDeliversFailureOnFailedRetrieval(usingStore: sut, storeURL: storeURL)
    }
    
    func test_retrieve_hasNoSideEffectsOnFailedRetrieval() {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        assertRetrieveHasNoSideEffectsOnFailedRetrieval(usingStore: sut, storeURL: storeURL)
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        assertInsertDeliversNoErrorOnEmptyCache(usingStore: makeSUT())
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
        assertInsertDeliversNoErrorOnNonEmptyCache(usingStore: makeSUT())
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        assertInsertOverridesPreviouslyInsertedCacheValues(usingStore: makeSUT())
    }
    
    func test_insert_deliversErrorOnFailedInsertion() {
        let invalidURL = URL(string: "invalid://store-url")
        let sut = makeSUT(storeURL: invalidURL)
        
        assertInsertDeliversErrorOnFailedInsertion(usingStore: sut)
    }
    
    func test_insert_hasNoSideEffectsOnFailedInsertion() {
        let invalidURL = URL(string: "invalid://store-url")
        let sut = makeSUT(storeURL: invalidURL)
        
        assertInsertHasNoSideEffectsOnFailedInsertion(usingStore: sut)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        assertDeleteDeliversNoErrorOnEmptyCache(usingStore: makeSUT())
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        assertDeleteHasNoSideEffectsOnEmptyCache(usingStore: makeSUT())
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        assertDeleteDeliversNoErrorOnNonEmptyCache(usingStore: makeSUT())
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        assertDeleteEmptiesPreviouslyInsertedCache(usingStore: makeSUT())
    }
    
    func test_delete_deliversErrorOnFailedDeletion() {
        let noDeletePermissionsURL = cachesDirectory
        let sut = makeSUT(storeURL: noDeletePermissionsURL)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNotNil(deletionError, "Expected deletion using an invalidURL to fail with an error")
    }
    
    func test_delete_hasNoSideEffectsOnFailedDeletion() {
        let noDeletePermissionsURL = cachesDirectory
        let sut = makeSUT(storeURL: noDeletePermissionsURL)
        
        deleteCache(from: sut)
        
        expect(sut, toCompleteRetrievalWith: .empty)
    }
    
    func test_feedStoreOperations_sideEffectsRunSerially() {
        assertFeedStoreOperationSideEffectsRunSerially(usingStore: makeSUT())
    }
}


extension CodableFeedStoreTests {
    // MARK: Test Case Setup & Teardown Helper
    private func clearTestCacheArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
    
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL)
        assertNoMemoryLeaks(sut, objectName: "`CodableFeedStore`", file: file, line: line)
        return sut
    }
    
    private var testSpecificStoreURL: URL {
        cachesDirectory.appendingPathComponent("\(type(of: self)).store")
    }
    
    private var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
