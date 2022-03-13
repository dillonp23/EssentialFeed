//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/28/22.
//

import Foundation
import XCTest
import EssentialFeed

class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        assertRetrieveDeliversEmptyOnEmptyCache(usingStore: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        assertRetrieveHasNoSideEffectsOnEmptyCache(usingStore: sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertRetrieveDeliversFoundValuesOnNonEmptyCache(usingStore: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertRetrieveHasNoSideEffectsOnNonEmptyCache(usingStore: sut)
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        assertInsertDeliversNoErrorOnEmptyCache(usingStore: sut)
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertInsertDeliversNoErrorOnNonEmptyCache(usingStore: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        assertInsertOverridesPreviouslyInsertedCacheValues(usingStore: sut)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        assertDeleteDeliversNoErrorOnEmptyCache(usingStore: sut)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        assertDeleteHasNoSideEffectsOnEmptyCache(usingStore: sut)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertDeleteDeliversNoErrorOnNonEmptyCache(usingStore: sut)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        
        assertDeleteEmptiesPreviouslyInsertedCache(usingStore: sut)
    }
    
    func test_feedStoreOperations_sideEffectsRunSerially() {
        let sut = makeSUT()
        
        assertFeedStoreOperationSideEffectsRunSerially(usingStore: sut)
    }
        
}


extension CoreDataFeedStoreTests {
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let sut = try! CoreDataFeedStore(storeType: .inMemory, bundle: storeBundle)
        assertNoMemoryLeaks(sut, objectName: "`CoreDataFeedStore`", file: file, line: line)
        return sut
    }
}
