//
//  FeedStore+NSPersistentContainerTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 3/2/22.
//

import XCTest
import EssentialFeed
import CoreData

class NSPersistentContainerTests: XCTestCase {
    private typealias LoadError = NSPersistentContainer.LoadingError
    
    func test_loadContainerForModel_deliversModelNotFoundErrorOnInvalidModelName() {
        let modelName = "IncorrectModelName"
        let emptyStoreDescription = NSPersistentStoreDescription()
        let bundle = Bundle(for: CoreDataFeedStore.self)
        
        func containerLoad() throws -> NSPersistentContainer {
            return try NSPersistentContainer
                .loadContainerForModel(named: modelName,
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
