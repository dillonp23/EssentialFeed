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
        self.metadata = [NSStoreTypeKey: Self.storeTypeKey, NSStoreUUIDKey: Self.storeUUIDKey]
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
    /// Note: the metdata associated with this type is based on its location in target,
    /// as well as its access level. Moving the class and/or changing it's access level
    /// will change the metadata type key, thus requiring a change to this value in code.
    ///
    /// Because this class is private (to prevent any access outside of this test class),
    /// the metadata is an obscure token (see below) and we cannot use the standard human
    /// readable type key of: "EssentialFeedTests.FailableCoreDataStore"
    ///
    /// If you receive an error reading "The store type in the metadata does not match
    /// the specified store type", copy the token from the error for the 'NSStoreType'
    /// key and update the value below to ensure class registeration and store loading
    /// succeeds as expected.
    public static var storeTypeKey: String {
        /// *Uncomment next line to see metadata error po in console*
        // "EssentialFeedTests.FailableCoreDataStore"
        "_TtC18EssentialFeedTestsP33_6F144DBF9C595C744714877AB9E6EB7921FailableCoreDataStore"
    }
    
    public static var storeUUIDKey: String {
        "CoreDataFeedStore+FailableSpecsTests"
    }
    
    public static func registerType() {
        NSPersistentStoreCoordinator.registerStoreClass(FailableCoreDataStore.self,
                                                        type: .init(rawValue: Self.storeTypeKey))
    }
}
