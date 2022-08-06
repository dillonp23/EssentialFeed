//
//  CoreDataFeedStore+FailableSpecsTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 3/3/22.
//

import Foundation
import XCTest
import EssentialFeed
import CoreData

extension CoreDataFeedStoreTests: FailableFeedStoreSpecs {
    func test_init_canRegisterCustomStoreTypeAndLoadPersistentStores() {
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
        let stub = NSManagedObjectContext.expectsEmptyRetrieval()
        stub.startIntercepting()
        
        assertInsertHasNoSideEffectsOnFailedInsertion(usingStore: sut)
    }
    
    func test_delete_deliversErrorOnFailedDeletion() {
        let sut = makeSUT()
        
        assertDeleteDeliversErrorOnFailedDeletion(usingStore: sut)
    }
    
    func test_delete_hasNoSideEffectsOnFailedDeletion() {
        let sut = makeSUT()
        let stub = NSManagedObjectContext.expectsEmptyRetrieval()
        stub.startIntercepting()
        
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

    override func execute(_ request: NSPersistentStoreRequest,
                          with context: NSManagedObjectContext?) throws -> Any {
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
