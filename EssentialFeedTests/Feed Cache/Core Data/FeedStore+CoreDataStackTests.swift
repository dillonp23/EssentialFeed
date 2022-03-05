//
//  FeedStore+CoreDataStackTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 3/3/22.
//

import XCTest
import EssentialFeed
import CoreData

class CoreDataStackTests: XCTestCase {
    func test_createContainer_throwsErrorOnProhibitedStoreURL() {
        let bundle = Bundle(for: CoreDataFeedStore.self)
        let badURL = FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first!
        
        XCTAssertThrowsError(try CoreDataStack.createContainer(ofType: .persistent(url: badURL),
                                                               modelName: "FeedStore", in: bundle))
    }
    
    func test_createContainer_throwsErrorOnInvalidStoreType() {
        let bundle = Bundle(for: CoreDataFeedStore.self)

        XCTAssertThrowsError(try CoreDataStack
                                .createContainer(ofType: .custom(store: InvalidCoreDataStore.self),
                                                 modelName: "FeedStore", in: bundle))
    }
}

// MARK: Helpers
private final class InvalidCoreDataStore: NSIncrementalStore {
    // Always throws error when registering i.e. container creation always fails
    override func loadMetadata() throws {
        throw anyNSError()
    }
}

extension InvalidCoreDataStore: CustomCoreDataStore {
    public static var storeTypeKey: String {
        return String(describing: self)
    }
    
    public static var storeUUIDKey: String {
        return "CoreDataStackTests+\(storeTypeKey)"
    }
    
    static var storeMetadata: [String: Any] {
        [NSStoreTypeKey: storeTypeKey, NSStoreUUIDKey: storeUUIDKey]
    }
    
    public static func registerType() {
        NSPersistentStoreCoordinator.registerStoreClass(InvalidCoreDataStore.self,
                                                        type: StoreType.init(rawValue: storeTypeKey))
    }
}
