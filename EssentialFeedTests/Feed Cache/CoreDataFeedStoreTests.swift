//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/28/22.
//

import Foundation
import XCTest
import EssentialFeed

class CoreDataFeedStore: FeedStore {
    func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping OperationCompletion) {
        
    }
    
    func deleteCachedFeed(completion: @escaping OperationCompletion) {
        
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }
}

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
        
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
        
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        
    }
    
    func test_feedStoreOperations_sideEffectsRunSerially() {
        
    }
        
}


extension CoreDataFeedStoreTests {
    private func makeSUT() -> FeedStore {
        return CoreDataFeedStore()
    }
}
