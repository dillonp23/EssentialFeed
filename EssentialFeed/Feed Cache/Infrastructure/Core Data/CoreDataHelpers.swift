//
//  CoreDataHelpers.swift
//  EssentialFeed
//
//  Created by Dillon on 3/2/22.
//

import CoreData

public protocol CustomCoreDataStore {
    static func registerType()
    static var storeTypeKey: String { get }
    static var storeUUIDKey: String { get }
}

public enum CoreDataStack {
    public enum StorageType {
        case persistent(url: URL)
        case inMemory
        case custom(store: CustomCoreDataStore.Type)
    }

    static func createContainer(ofType storeType: StorageType, modelName: String, in bundle: Bundle) throws -> NSPersistentContainer  {

        let storeDescription = NSPersistentStoreDescription()
        switch storeType {
            case let .persistent(url):
                storeDescription.url = url
            case .inMemory:
                storeDescription.url = URL(fileURLWithPath: "/dev/null")
            case let .custom(store):
                store.registerType()
                storeDescription.type = store.storeTypeKey
        }

        return try NSPersistentContainer.loadContainerForModel(named: modelName, storeDescription: storeDescription, in: bundle)
    }
}

public extension NSPersistentContainer {
    enum LoadingError: Swift.Error {
        case modelNotFound
        case failedToLoadPersistentStores(Swift.Error)
    }
    
    static func loadContainerForModel(named name: String,
                     storeDescription: NSPersistentStoreDescription,
                     in bundle: Bundle) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
            throw LoadingError.modelNotFound
        }
        
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        container.persistentStoreDescriptions = [storeDescription]
        
        return try NSPersistentContainer.loadStoresIn(container: container)
    }
    
    static func loadStoresIn(container: NSPersistentContainer) throws -> NSPersistentContainer {
        var loadingError: Swift.Error?
        container.loadPersistentStores { _, error in
            loadingError = error
        }
        
        try loadingError.map { error in
            throw LoadingError.failedToLoadPersistentStores(error)
        }
        
        return container
    }
}

public extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        return bundle
            .url(forResource: name, withExtension: "momd")
            .flatMap { NSManagedObjectModel(contentsOf: $0) }
    }
}
