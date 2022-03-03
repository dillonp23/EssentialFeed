//
//  FeedStore+CoreDataStackTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 3/2/22.
//

import XCTest
import EssentialFeed
import CoreData

// MARK: NSPersistentContainer `Load` Tests
extension CoreDataFeedStoreTests {
    private typealias LoadError = NSPersistentContainer.LoadingError
    
    func test_load_deliversModelNotFoundErrorOnIncorrectModelName() {
        let modelName = "IncorrectModelName"
        let emptyStoreDescription = NSPersistentStoreDescription()
        let bundle = Bundle(for: CoreDataFeedStore.self)
        
        func containerLoad() throws -> NSPersistentContainer {
            return try NSPersistentContainer.load(modelName: modelName,
                                                  storeDescription: emptyStoreDescription,
                                                  in: bundle)
        }
        
        XCTAssertThrowsError(try containerLoad()) { error in
            guard let error = error as? LoadError, case .modelNotFound = error else {
                return XCTFail("Expected container loading to fail with `modelNotFound`, got \(error)")
            }
        }
    }
}
