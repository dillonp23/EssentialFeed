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
    private typealias SUT = NSPersistentContainer
    
    func test_loadContainerForModel_deliversModelNotFoundErrorOnInvalidModelName() {
        let components = mockComponentsFor(modelType: .invalid)
        
        expect(toThrow: .modelNotFound, forAction: {
            _ = try SUT.loadContainerForModel(named: components.name,
                                              storeDescription: components.description,
                                              in: components.bundle)})
    }
    
    func test_loadStoresIn_deliversFailedToLoadPersistentStoresErrorOnLoadStoresFailure() {
        let components = mockComponentsFor(modelType: .valid)
        let container = makeFailableContainer(from: components)
        
        expect(toThrow: .failedToLoadPersistentStores(anyNSError()), forAction: {
            _ = try SUT.loadStoresIn(container: container)})
    }
}


// MARK: Assertion Helpers
extension NSPersistentContainerTests {
    private typealias LoadError = NSPersistentContainer.LoadingError
    
    private func expect(toThrow expectedError: LoadError, forAction action: () throws -> Void,
                        file: StaticString = #filePath, line: UInt = #line) {
        do { try action() }
        catch { compare(expectedError, error as! LoadError) }
    }
    
    private func compare(_ expectedError: LoadError, _ caughtError: LoadError,
                         file: StaticString = #filePath, line: UInt = #line) {
        switch (expectedError, caughtError) {
            case (.modelNotFound, .modelNotFound):
                break
            case let (.failedToLoadPersistentStores(expected), .failedToLoadPersistentStores(caught)):
                XCTAssertEqual(expected as NSError, caught as NSError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedError), got \(caughtError) instead.", file: file, line: line)
        }
    }
}


// MARK: Test Components & SUT Setup
extension NSPersistentContainerTests {
    private typealias Description = NSPersistentStoreDescription
    private typealias ModelComponents = (name: String, description: Description, bundle: Bundle)
    
    private enum ManagedModelType: String {
        case invalid = "InvalidModelName"
        case valid = "FeedStore"
    }
    
    private func mockComponentsFor(modelType: ManagedModelType) -> ModelComponents {
        let modelName = modelType.rawValue
        let emptyStoreDescription = Description(url: URL(fileURLWithPath: "/dev/null"))
        let bundle = Bundle(for: CoreDataFeedStore.self)
        
        return (modelName, emptyStoreDescription, bundle)
    }
    
    private func makeFailableContainer(from components: ModelComponents) -> NSPersistentContainer {
        let model = NSManagedObjectModel.with(name: components.name, in: components.bundle)!
        let container = FailableContainer(name: components.name, managedObjectModel: model)
        container.persistentStoreDescriptions = [components.description]
        
        return container
    }
}


// MARK: Test-Specific `FailableContainer` Class
extension NSPersistentContainerTests {
    private final class FailableContainer: NSPersistentContainer {
        override func loadPersistentStores(completionHandler block: @escaping (Description, Error?) -> Void) {
            block(Description(url: URL(fileURLWithPath: "/dev/null")), anyNSError())
        }
    }
}
