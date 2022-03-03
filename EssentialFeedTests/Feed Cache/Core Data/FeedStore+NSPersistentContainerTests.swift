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
        let components = mockComponentsFor(modelType: .invalid)
        
        func containerLoad() throws -> NSPersistentContainer {
            return try NSPersistentContainer
                .loadContainerForModel(named: components.name,
                                       storeDescription: components.storeDescription,
                                       in: components.bundle)
        }
        
        XCTAssertThrowsError(try containerLoad()) { error in
            guard let error = error as? LoadError, case .modelNotFound = error else {
                return XCTFail("Expected container loading to fail with `modelNotFound`, got \(error)")
            }
        }
    }
    
    func test_loadStoresIn_deliversFailedToLoadPersistentStoresErrorOnLoadStoresFailure() {
        let components = mockComponentsFor(modelType: .valid)
        let model = NSManagedObjectModel.with(name: components.name, in: components.bundle)!
        
        let container = FailableContainer(name: components.name, managedObjectModel: model)
        container.persistentStoreDescriptions = [components.storeDescription]
        
        XCTAssertThrowsError(try NSPersistentContainer.loadStoresIn(container: container)) { error in
            guard let thrownError = error as? LoadError, case let .failedToLoadPersistentStores(loadingError) = thrownError else {
                return XCTFail("Expected to fail with `.failedToLoadPersistentStores`, got \(error)")
            }
            
            XCTAssertEqual(anyNSError(), loadingError as NSError)
        }
    }
}


// MARK: Helpers
extension NSPersistentContainerTests {
    private typealias SUTComponents = (name: String, storeDescription: NSPersistentStoreDescription, bundle: Bundle)
    
    private enum ManagedModelType: String {
        case invalid = "InvalidModelName"
        case valid = "FeedStore"
    }
    
    private func mockComponentsFor(modelType: ManagedModelType) -> SUTComponents {
        let modelName = modelType.rawValue
        let emptyStoreDescription = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
        let bundle = Bundle(for: CoreDataFeedStore.self)
        
        return (modelName, emptyStoreDescription, bundle)
    }
}


// MARK: Test-Specific `FailableContainer` Class
extension NSPersistentContainerTests {
    private final class FailableContainer: NSPersistentContainer {
        override func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void) {
            block(NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null")), anyNSError())
        }
    }
}
