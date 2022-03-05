//
//  CoreDataFeedStore+FailableSpecsTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 3/3/22.
//

import Foundation
import XCTest
import EssentialFeed

extension CoreDataFeedStoreTests: FailableFeedStoreSpecs {
    func test_init_isAbleToLoadPersistentStoresForFailableStore() {
        _ = makeSUT()
    }
    
    func test_retrieve_deliversFailureOnFailedRetrieval() {
        let sut = makeSUT()
        
        assertRetrieveDeliversFailureOnFailedRetrieval(usingStore: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnFailedRetrieval() {
        let sut = makeSUT()
        
        assertRetrieveHasNoSideEffectsOnFailedRetrieval(usingStore: sut)
    }
    
    func test_insert_deliversErrorOnFailedInsertion() {
        let sut = makeSUT()
        
        assertInsertDeliversErrorOnFailedInsertion(usingStore: sut)
    }
    
    func test_insert_hasNoSideEffectsOnFailedInsertion() {
        let sut = makeSUT()
        
        assertInsertHasNoSideEffectsOnFailedInsertion(usingStore: sut)
    }
    
    func test_delete_deliversErrorOnFailedDeletion() {
        let sut = makeSUT()
        
        assertDeleteDeliversErrorOnFailedDeletion(usingStore: sut)
    }
    
    func test_delete_hasNoSideEffectsOnFailedDeletion() {
        let sut = makeSUT()
        
        assertDeleteHasNoSideEffectsOnFailedDeletion(usingStore: sut)
    }
}


// MARK: Helpers
extension CoreDataFeedStoreTests {
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let sut = try! CoreDataFeedStore(storeType: .custom(store: FailableCoreDataStore.self), bundle: storeBundle)
        assertNoMemoryLeaks(sut, objectName: "`CoreDataFeedStore`", file: file, line: line)
        return sut
    }
}

// MARK: Helper Class to Test Failable Specs
private final class FailableCoreDataStore: NSIncrementalStore {
    public override func loadMetadata() throws {
        self.metadata = FailableCoreDataStore.storeMetadata
    }
    
    override var metadata: [String : Any]! {
        get {
            return FailableCoreDataStore.storeMetadata
        }
        set {
            super.metadata = newValue
        }
    }
    
    private var receivedRequests = Set<NSPersistentStoreRequestType>()
    
    /// For side-effects tests, we first execute a `.save` (i.e. an insert or delete operation)
    /// and throw an error to mock a failed deletion/insertion. After the failed insert/delete
    /// operation, a subsequent `.fetch` request will be passed to `execute(_:with:)` method
    /// which must succeed and return an empty array [] (representing an empty cache)
    override func execute(_ request: NSPersistentStoreRequest,
                          with context: NSManagedObjectContext?) throws -> Any {
        receivedRequests.insert(request.requestType)
        
        if request.requestType == .fetchRequestType && receivedRequests.contains(.saveRequestType) {
            return []
        }
        
        throw anyNSError()
    }
}

extension FailableCoreDataStore: CustomCoreDataStore {
    public static var storeTypeKey: String {
        return String(describing: self)
    }
    
    public static var storeUUIDKey: String {
        return "CoreDataFeedStoreTests+\(storeTypeKey)"
    }
    
    static var storeMetadata: [String: Any] {
        [NSStoreTypeKey: storeTypeKey, NSStoreUUIDKey: storeUUIDKey]
    }
    
    public static func registerType() {
        NSPersistentStoreCoordinator.registerStoreClass(FailableCoreDataStore.self,
                                                        type: StoreType.init(rawValue: storeTypeKey))
    }
}
