//
//  CoreDataHelpers.swift
//  EssentialFeed
//
//  Created by Dillon on 3/2/22.
//

import CoreData

extension NSPersistentContainer {
    private enum LoadingError: Swift.Error {
        case modelNotFound
        case failedToLoadPersistentStores(Swift.Error)
    }
    
    static func load(modelName name: String, url: URL, in bundle: Bundle) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
            throw LoadingError.modelNotFound
        }
        
        let storeDescriptor = NSPersistentStoreDescription(url: url)
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        container.persistentStoreDescriptions = [storeDescriptor]
        
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
