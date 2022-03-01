//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Dillon on 2/28/22.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
    
    private let container: NSPersistentContainer
    private let moc: NSManagedObjectContext
    
    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(modelName: "FeedStore", url: storeURL, in: bundle)
        moc = container.newBackgroundContext()
    }
    
    public func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping OperationCompletion) {
        
    }
    
    public func deleteCachedFeed(completion: @escaping OperationCompletion) {
        
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }
}

// MARK: - CoreDataFeedStore Model Representations
@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}

private extension ManagedCache {
    static var entityName: String {
        return self.entity().name!
    }
    
    func mappedToLocal() -> (feed: [LocalFeedImage], timestamp: Date) {
        let managedFeed = self.feed.compactMap {
            $0 as? ManagedFeedImage
        }
        let localFeed = managedFeed.map {
            LocalFeedImage(id: $0.id, description: $0.imageDescription, location: $0.location, url: $0.url)
        }
        return (localFeed, self.timestamp)
    }
    
    static func mapOrderedSet(from localFeed: [LocalFeedImage],
                                 in context: NSManagedObjectContext) -> NSOrderedSet {
        return NSOrderedSet(array: localFeed.map {
            let managedImage = ManagedFeedImage(context: context)
            managedImage.id = $0.id
            managedImage.imageDescription = $0.description
            managedImage.location = $0.location
            managedImage.url = $0.url
            return managedImage
        })
    }
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
}

// MARK: - Core Data Stack Setup Helpers
private extension NSPersistentContainer {
    enum LoadingError: Swift.Error {
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
