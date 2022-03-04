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
    override func loadMetadata() throws {
        throw anyNSError()
    }
}

extension InvalidCoreDataStore: CustomCoreDataStore {
    public static var storeTypeKey: String {
        "EssentialFeedTests.InvalidCoreDataStore"
    }
    
    fileprivate static var storeUUIDKey: String {
        UUID().uuidString
    }
    
    public static func registerType() {
        NSPersistentStoreCoordinator.registerStoreClass(InvalidCoreDataStore.self,
                                                        forStoreType: Self.storeTypeKey)
    }
}
