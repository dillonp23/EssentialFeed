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

public enum CoreDataStore {
    public enum StorageType {
        case persistent(url: URL)
        case inMemory
        case custom(typeName: String)
    }

    static func createContainer(ofType storeType: StorageType, modelName: String, in bundle: Bundle) throws -> NSPersistentContainer  {

        let storeDescription = NSPersistentStoreDescription()
        switch storeType {
            case let .persistent(url):
                storeDescription.url = url
            case .inMemory:
                storeDescription.url = URL(fileURLWithPath: "/dev/null")
            case let .custom(typeName):
                storeDescription.type = typeName
        }

        return try NSPersistentContainer.load(modelName: modelName, storeDescription: storeDescription, in: bundle)
    }
}

extension NSPersistentContainer {
    private enum LoadingError: Swift.Error {
        case modelNotFound
        case failedToLoadPersistentStores(Swift.Error)
    }
    
    static func load(modelName name: String,
                     storeDescription: NSPersistentStoreDescription,
                     in bundle: Bundle) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
            throw LoadingError.modelNotFound
        }
        
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        container.persistentStoreDescriptions = [storeDescription]
        
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

private extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        return bundle
            .url(forResource: name, withExtension: "momd")
            .flatMap { NSManagedObjectModel(contentsOf: $0) }
    }
}
